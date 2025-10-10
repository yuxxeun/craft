#!/bin/bash

# Script Backup Otomatis
# Membuat backup folder/file dengan timestamp dan kompresi

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfigurasi default
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30  # Hapus backup lebih dari 30 hari

# Banner
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Automated Backup Script${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Fungsi untuk membuat direktori backup
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echo -e "${GREEN}✓ Direktori backup dibuat: $BACKUP_DIR${NC}"
    fi
}

# Fungsi untuk backup file/folder
backup_item() {
    local source=$1
    local backup_name=$(basename "$source")
    local backup_file="$BACKUP_DIR/${backup_name}_${DATE}.tar.gz"
    
    if [ ! -e "$source" ]; then
        echo -e "${RED}✗ Error: $source tidak ditemukan!${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⏳ Membackup: $source${NC}"
    
    # Membuat backup dengan kompresi
    tar -czf "$backup_file" -C "$(dirname "$source")" "$(basename "$source")" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✓ Backup berhasil: $backup_file ($size)${NC}"
        return 0
    else
        echo -e "${RED}✗ Backup gagal: $source${NC}"
        return 1
    fi
}

# Fungsi untuk cleanup backup lama
cleanup_old_backups() {
    echo ""
    echo -e "${YELLOW}🧹 Membersihkan backup lama (> $RETENTION_DAYS hari)...${NC}"
    
    local count=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS 2>/dev/null | wc -l)
    
    if [ $count -gt 0 ]; then
        find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null
        echo -e "${GREEN}✓ $count backup lama dihapus${NC}"
    else
        echo -e "${BLUE}ℹ Tidak ada backup lama yang perlu dihapus${NC}"
    fi
}

# Fungsi untuk menampilkan daftar backup
list_backups() {
    echo ""
    echo -e "${BLUE}📦 Daftar Backup yang Tersedia:${NC}"
    echo "================================"
    
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print $9, "(" $5 ")", $6, $7, $8}'
    else
        echo "Belum ada backup"
    fi
}

# Menu utama
echo "Pilih mode backup:"
echo "1. Backup file/folder tertentu"
echo "2. Backup multiple items (dari file list)"
echo "3. Backup direktori home"
echo "4. Lihat daftar backup"
echo "5. Restore backup"
read -p "Pilihan (1-5): " mode

create_backup_dir

case $mode in
    1)
        read -p "Masukkan path file/folder yang akan dibackup: " source
        backup_item "$source"
        cleanup_old_backups
        ;;
    2)
        read -p "Masukkan path file yang berisi daftar item (satu path per baris): " list_file
        
        if [ ! -f "$list_file" ]; then
            echo -e "${RED}✗ File list tidak ditemukan!${NC}"
            exit 1
        fi
        
        success=0
        failed=0
        
        while IFS= read -r line; do
            # Skip baris kosong dan komentar
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            
            if backup_item "$line"; then
                ((success++))
            else
                ((failed++))
            fi
        done < "$list_file"
        
        echo ""
        echo -e "${BLUE}================================${NC}"
        echo -e "${GREEN}✓ Berhasil: $success${NC}"
        echo -e "${RED}✗ Gagal: $failed${NC}"
        
        cleanup_old_backups
        ;;
    3)
        echo -e "${YELLOW}⏳ Membackup direktori home (mengecualikan cache dan temp)...${NC}"
        backup_file="$BACKUP_DIR/home_backup_${DATE}.tar.gz"
        
        tar -czf "$backup_file" \
            --exclude='.cache' \
            --exclude='.npm' \
            --exclude='.mozilla' \
            --exclude='node_modules' \
            --exclude='.local/share/Trash' \
            -C "$HOME" . 2>/dev/null
        
        if [ $? -eq 0 ]; then
            size=$(du -h "$backup_file" | cut -f1)
            echo -e "${GREEN}✓ Backup home berhasil: $backup_file ($size)${NC}"
        else
            echo -e "${RED}✗ Backup home gagal!${NC}"
        fi
        
        cleanup_old_backups
        ;;
    4)
        list_backups
        ;;
    5)
        list_backups
        echo ""
        read -p "Masukkan nama file backup yang akan direstore: " backup_file_name
        read -p "Restore ke direktori (default: ./restore): " restore_dir
        
        restore_dir=${restore_dir:-./restore}
        backup_path="$BACKUP_DIR/$backup_file_name"
        
        if [ ! -f "$backup_path" ]; then
            echo -e "${RED}✗ File backup tidak ditemukan!${NC}"
            exit 1
        fi
        
        mkdir -p "$restore_dir"
        echo -e "${YELLOW}⏳ Merestore backup...${NC}"
        
        tar -xzf "$backup_path" -C "$restore_dir" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Restore berhasil ke: $restore_dir${NC}"
        else
            echo -e "${RED}✗ Restore gagal!${NC}"
        fi
        ;;
    *)
        echo -e "${RED}✗ Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Selesai!${NC}"
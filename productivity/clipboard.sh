#!/bin/bash

# Cron Job Manager
# Memudahkan manage cron jobs

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# File temp
TEMP_CRON="/tmp/crontab.tmp"

# Banner
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}  Cron Job Manager${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Fungsi untuk cek cron service
check_cron_service() {
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Fungsi untuk list cron jobs
list_cron_jobs() {
    echo -e "${BLUE}📋 Daftar Cron Jobs:${NC}"
    echo "================================"
    
    crontab -l 2>/dev/null > "$TEMP_CRON"
    
    if [ ! -s "$TEMP_CRON" ]; then
        echo -e "${YELLOW}Tidak ada cron job${NC}"
        return
    fi
    
    local index=1
    while IFS= read -r line; do
        # Skip baris kosong dan komentar
        if [ -z "$line" ] || [[ "$line" =~ ^#.*$ ]]; then
            continue
        fi
        
        echo -e "${CYAN}[$index]${NC} $line"
        ((index++))
    done < "$TEMP_CRON"
    
    echo ""
    echo -e "${MAGENTA}Total: $((index-1)) job(s)${NC}"
}

# Fungsi untuk add cron job
add_cron_job() {
    echo -e "${BLUE}➕ Tambah Cron Job Baru${NC}"
    echo "================================"
    echo ""
    echo "Format waktu cron: * * * * *"
    echo "                   │ │ │ │ │"
    echo "                   │ │ │ │ └─── Day of week (0-7)"
    echo "                   │ │ │ └───── Month (1-12)"
    echo "                   │ │ └─────── Day of month (1-31)"
    echo "                   │ └───────── Hour (0-23)"
    echo "                   └─────────── Minute (0-59)"
    echo ""
    echo "Contoh:"
    echo "  * * * * *        - Setiap menit"
    echo "  0 * * * *        - Setiap jam"
    echo "  0 0 * * *        - Setiap hari jam 00:00"
    echo "  0 0 * * 0        - Setiap minggu"
    echo "  0 2 1 * *        - Setiap tanggal 1, jam 02:00"
    echo "  */5 * * * *      - Setiap 5 menit"
    echo "  0 9-17 * * 1-5   - Jam 9-17, Senin-Jumat"
    echo ""
    
    read -p "Masukkan schedule (contoh: 0 2 * * *): " schedule
    
    if [ -z "$schedule" ]; then
        echo -e "${RED}✗ Schedule tidak boleh kosong${NC}"
        return 1
    fi
    
    read -p "Masukkan command yang akan dijalankan: " command
    
    if [ -z "$command" ]; then
        echo -e "${RED}✗ Command tidak boleh kosong${NC}"
        return 1
    fi
    
    read -p "Deskripsi job (opsional): " description
    
    # Tambahkan ke crontab
    crontab -l 2>/dev/null > "$TEMP_CRON"
    
    if [ ! -z "$description" ]; then
        echo "# $description" >> "$TEMP_CRON"
    fi
    
    echo "$schedule $command" >> "$TEMP_CRON"
    
    crontab "$TEMP_CRON"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Cron job berhasil ditambahkan!${NC}"
        echo ""
        echo "Preview:"
        echo -e "${CYAN}$schedule $command${NC}"
    else
        echo -e "${RED}✗ Gagal menambahkan cron job${NC}"
        return 1
    fi
}

# Fungsi untuk remove cron job
remove_cron_job() {
    list_cron_jobs
    
    if [ ! -s "$TEMP_CRON" ]; then
        return
    fi
    
    echo ""
    read -p "Pilih nomor job yang akan dihapus: " num
    
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}✗ Input harus angka${NC}"
        return 1
    fi
    
    crontab -l 2>/dev/null > "$TEMP_CRON"
    
    local index=1
    local new_cron="/tmp/new_crontab.tmp"
    > "$new_cron"
    
    while IFS= read -r line; do
        # Skip baris kosong
        if [ -z "$line" ]; then
            echo "$line" >> "$new_cron"
            continue
        fi
        
        # Jaga komentar
        if [[ "$line" =~ ^#.*$ ]]; then
            echo "$line" >> "$new_cron"
            continue
        fi
        
        # Skip job yang dipilih
        if [ $index -eq $num ]; then
            echo -e "${YELLOW}Menghapus: $line${NC}"
            ((index++))
            continue
        fi
        
        echo "$line" >> "$new_cron"
        ((index++))
    done < "$TEMP_CRON"
    
    crontab "$new_cron"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Cron job berhasil dihapus!${NC}"
    else
        echo -e "${RED}✗ Gagal menghapus cron job${NC}"
        return 1
    fi
}

# Fungsi untuk edit cron job
edit_cron_job() {
    # Cek editor
    if [ -z "$EDITOR" ]; then
        EDITOR="nano"
    fi
    
    echo -e "${YELLOW}Membuka editor untuk edit crontab...${NC}"
    echo -e "${YELLOW}Editor: $EDITOR${NC}"
    echo ""
    
    crontab -e
    
    echo ""
    echo -e "${GREEN}✓ Selesai edit${NC}"
}

# Fungsi untuk enable/disable cron job
toggle_cron_job() {
    list_cron_jobs
    
    if [ ! -s "$TEMP_CRON" ]; then
        return
    fi
    
    echo ""
    read -p "Pilih nomor job untuk enable/disable: " num
    
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}✗ Input harus angka${NC}"
        return 1
    fi
    
    crontab -l 2>/dev/null > "$TEMP_CRON"
    
    local index=1
    local new_cron="/tmp/new_crontab.tmp"
    > "$new_cron"
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            echo "$line" >> "$new_cron"
            continue
        fi
        
        if [[ "$line" =~ ^#.*$ ]]; then
            echo "$line" >> "$new_cron"
            continue
        fi
        
        if [ $index -eq $num ]; then
            # Jika dimulai dengan #, enable (hapus #)
            if [[ "$line" =~ ^#.*$ ]]; then
                line="${line:1}"  # Hapus karakter pertama (#)
                echo -e "${GREEN}✓ Job enabled${NC}"
            else
                # Jika tidak dimulai dengan #, disable (tambah #)
                line="#$line"
                echo -e "${YELLOW}✓ Job disabled${NC}"
            fi
        fi
        
        echo "$line" >> "$new_cron"
        ((index++))
    done < "$TEMP_CRON"
    
    crontab "$new_cron"
}

# Fungsi untuk backup crontab
backup_crontab() {
    local backup_dir="$HOME/cron-backups"
    local backup_file="$backup_dir/crontab_$(date +%Y%m%d_%H%M%S).txt"
    
    mkdir -p "$backup_dir"
    
    crontab -l 2>/dev/null > "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Crontab berhasil dibackup!${NC}"
        echo "Location: $backup_file"
    else
        echo -e "${RED}✗ Backup gagal${NC}"
    fi
}

# Fungsi untuk restore crontab
restore_crontab() {
    local backup_dir="$HOME/cron-backups"
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${YELLOW}Tidak ada backup${NC}"
        return
    fi
    
    echo -e "${BLUE}📦 Daftar Backup:${NC}"
    echo "================================"
    
    local files=($(ls -t "$backup_dir"/crontab_*.txt 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}Tidak ada backup${NC}"
        return
    fi
    
    local index=1
    for file in "${files[@]}"; do
        local filename=$(basename "$file")
        local date=$(echo "$filename" | sed 's/crontab_\(.*\)\.txt/\1/')
        echo -e "${CYAN}[$index]${NC} $date"
        ((index++))
    done
    
    echo ""
    read -p "Pilih nomor backup untuk restore: " num
    
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ $num -lt 1 ] || [ $num -gt ${#files[@]} ]; then
        echo -e "${RED}✗ Pilihan tidak valid${NC}"
        return 1
    fi
    
    local selected_file="${files[$((num-1))]}"
    
    crontab "$selected_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Crontab berhasil direstore!${NC}"
    else
        echo -e "${RED}✗ Restore gagal${NC}"
    fi
}

# Fungsi untuk show cron log
show_cron_log() {
    echo -e "${BLUE}📜 Cron Log (10 baris terakhir):${NC}"
    echo "================================"
    
    if [ -f "/var/log/cron" ]; then
        tail -n 10 /var/log/cron
    elif [ -f "/var/log/cron.log" ]; then
        tail -n 10 /var/log/cron.log
    elif [ -f "/var/log/syslog" ]; then
        grep CRON /var/log/syslog | tail -n 10
    else
        echo -e "${YELLOW}Log file tidak ditemukan${NC}"
        echo "Coba: sudo journalctl -u cron -n 10"
    fi
}

# Main
if ! check_cron_service; then
    echo -e "${YELLOW}⚠ Cron service tidak berjalan${NC}"
    echo "Start dengan: sudo systemctl start cron"
    echo ""
fi

# Menu
echo "Pilih aksi:"
echo "1. List semua cron jobs"
echo "2. Tambah cron job baru"
echo "3. Hapus cron job"
echo "4. Edit crontab manual"
echo "5. Enable/Disable cron job"
echo "6. Backup crontab"
echo "7. Restore crontab"
echo "8. Lihat cron log"
read -p "Pilihan (1-8): " choice

echo ""

case $choice in
    1)
        list_cron_jobs
        ;;
    2)
        add_cron_job
        ;;
    3)
        remove_cron_job
        ;;
    4)
        edit_cron_job
        ;;
    5)
        toggle_cron_job
        ;;
    6)
        backup_crontab
        ;;
    7)
        restore_crontab
        ;;
    8)
        show_cron_log
        ;;
    *)
        echo -e "${RED}✗ Pilihan tidak valid${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Selesai!${NC}"
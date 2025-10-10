#!/bin/bash

# Script Network Speed Test
# Menggunakan speedtest-cli atau fast-cli

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# File log
LOG_DIR="$HOME/speedtest-logs"
LOG_FILE="$LOG_DIR/speedtest_$(date +%Y%m%d).log"

# Banner
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}  Network Speed Test${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Fungsi untuk membuat direktori log
create_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

# Fungsi untuk cek koneksi internet
check_internet() {
    echo -e "${YELLOW}⏳ Memeriksa koneksi internet...${NC}"
    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✓ Koneksi internet tersedia${NC}"
        return 0
    else
        echo -e "${RED}✗ Tidak ada koneksi internet!${NC}"
        return 1
    fi
}

# Fungsi untuk cek speedtest-cli
check_speedtest_cli() {
    if command -v speedtest-cli &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Fungsi untuk cek fast-cli
check_fast_cli() {
    if command -v fast &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Fungsi untuk install speedtest-cli
install_speedtest_cli() {
    echo -e "${YELLOW}Mencoba install speedtest-cli...${NC}"
    
    if command -v pip3 &> /dev/null; then
        pip3 install speedtest-cli --user
        return $?
    elif command -v pip &> /dev/null; then
        pip install speedtest-cli --user
        return $?
    else
        echo -e "${RED}pip tidak ditemukan. Install secara manual:${NC}"
        echo "  pip install speedtest-cli"
        echo "  atau: sudo apt install speedtest-cli"
        return 1
    fi
}

# Fungsi untuk test dengan speedtest-cli
run_speedtest_cli() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Memulai speed test dengan speedtest-cli...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Menjalankan speedtest
    result=$(speedtest-cli --simple 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "$result"
        
        # Parse hasil
        ping=$(echo "$result" | grep "Ping:" | awk '{print $2}')
        download=$(echo "$result" | grep "Download:" | awk '{print $2}')
        upload=$(echo "$result" | grep "Upload:" | awk '{print $2}')
        
        # Tampilkan hasil dengan format bagus
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}📈 Hasil Speed Test:${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "⚡ Ping      : ${YELLOW}$ping ms${NC}"
        echo -e "⬇️  Download  : ${GREEN}$download Mbit/s${NC}"
        echo -e "⬆️  Upload    : ${CYAN}$upload Mbit/s${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Log hasil
        create_log_dir
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ping: $ping ms | Download: $download Mbit/s | Upload: $upload Mbit/s" >> "$LOG_FILE"
        
        return 0
    else
        echo -e "${RED}✗ Speed test gagal!${NC}"
        return 1
    fi
}

# Fungsi untuk test dengan speedtest-cli (detailed)
run_speedtest_detailed() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Memulai detailed speed test...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    speedtest-cli
    
    if [ $? -eq 0 ]; then
        create_log_dir
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Detailed test completed" >> "$LOG_FILE"
        return 0
    else
        echo -e "${RED}✗ Speed test gagal!${NC}"
        return 1
    fi
}

# Fungsi untuk test dengan fast-cli
run_fast_cli() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Memulai speed test dengan Fast.com...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    fast --upload
}

# Fungsi untuk monitoring continuous
run_continuous_test() {
    read -p "Interval test (dalam menit, default: 30): " interval
    interval=${interval:-30}
    interval_sec=$((interval * 60))
    
    echo -e "${YELLOW}⏱️  Memulai continuous monitoring setiap $interval menit...${NC}"
    echo -e "${YELLOW}Tekan Ctrl+C untuk berhenti${NC}"
    echo ""
    
    while true; do
        echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] Menjalankan speed test...${NC}"
        run_speedtest_cli
        echo ""
        echo -e "${YELLOW}⏳ Menunggu $interval menit untuk test berikutnya...${NC}"
        echo ""
        sleep $interval_sec
    done
}

# Fungsi untuk lihat history log
view_logs() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📜 History Speed Test (Hari Ini)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE"
    else
        echo "Belum ada log untuk hari ini"
    fi
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Cek koneksi internet
if ! check_internet; then
    exit 1
fi

echo ""

# Cek tool yang tersedia
has_speedtest=false
has_fast=false

if check_speedtest_cli; then
    has_speedtest=true
    echo -e "${GREEN}✓ speedtest-cli tersedia${NC}"
fi

if check_fast_cli; then
    has_fast=true
    echo -e "${GREEN}✓ fast-cli tersedia${NC}"
fi

# Jika tidak ada tool, tawarkan install
if [ "$has_speedtest" = false ] && [ "$has_fast" = false ]; then
    echo -e "${YELLOW}⚠️  Tidak ada tool speed test yang terinstall${NC}"
    echo ""
    read -p "Install speedtest-cli sekarang? (y/n): " install_choice
    
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
        if install_speedtest_cli; then
            echo -e "${GREEN}✓ speedtest-cli berhasil diinstall${NC}"
            has_speedtest=true
        else
            echo -e "${RED}✗ Instalasi gagal${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Install manual dengan:${NC}"
        echo "  pip install speedtest-cli"
        echo "  atau: npm install -g fast-cli"
        exit 1
    fi
fi

echo ""

# Menu
echo -e "${CYAN}Pilih mode test:${NC}"
echo "1. Quick test (simple)"
echo "2. Detailed test"
echo "3. Test dengan Fast.com (jika tersedia)"
echo "4. Continuous monitoring"
echo "5. Lihat history log"
read -p "Pilihan (1-5): " choice

echo ""

case $choice in
    1)
        if [ "$has_speedtest" = true ]; then
            run_speedtest_cli
        else
            echo -e "${RED}speedtest-cli tidak tersedia${NC}"
        fi
        ;;
    2)
        if [ "$has_speedtest" = true ]; then
            run_speedtest_detailed
        else
            echo -e "${RED}speedtest-cli tidak tersedia${NC}"
        fi
        ;;
    3)
        if [ "$has_fast" = true ]; then
            run_fast_cli
        else
            echo -e "${RED}fast-cli tidak tersedia. Install dengan: npm install -g fast-cli${NC}"
        fi
        ;;
    4)
        if [ "$has_speedtest" = true ]; then
            run_continuous_test
        else
            echo -e "${RED}speedtest-cli tidak tersedia${NC}"
        fi
        ;;
    5)
        view_logs
        ;;
    *)
        echo -e "${RED}✗ Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Selesai!${NC}"
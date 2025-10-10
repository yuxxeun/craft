#!/bin/bash

# Script Download YouTube Video
# Memerlukan yt-dlp untuk berfungsi

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fungsi untuk memeriksa apakah yt-dlp terinstal
check_ytdlp() {
    if ! command -v yt-dlp &> /dev/null; then
        echo -e "${RED}Error: yt-dlp tidak ditemukan!${NC}"
        echo -e "${YELLOW}Install yt-dlp dengan cara:${NC}"
        echo "  - Ubuntu/Debian: sudo apt install yt-dlp"
        echo "  - Arch Linux: sudo pacman -S yt-dlp"
        echo "  - Atau: sudo pip install yt-dlp"
        exit 1
    fi
}

# Fungsi untuk memeriksa apakah ffmpeg terinstal
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${YELLOW}Warning: ffmpeg tidak ditemukan!${NC}"
        echo -e "${YELLOW}Install ffmpeg untuk konversi audio yang lebih baik:${NC}"
        echo "  - Ubuntu/Debian: sudo apt install ffmpeg"
        echo "  - Arch Linux: sudo pacman -S ffmpeg"
        echo ""
    fi
}

# Banner
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  YouTube Video Downloader${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Cek dependencies
check_ytdlp
check_ffmpeg

# Input URL
read -p "Masukkan URL YouTube: " url

if [ -z "$url" ]; then
    echo -e "${RED}Error: URL tidak boleh kosong!${NC}"
    exit 1
fi

# Pilih format
echo ""
echo "Pilih format download:"
echo "1. MP4 (Video)"
echo "2. MP3 (Audio saja)"
read -p "Pilihan (1/2): " choice

case $choice in
    1)
        echo -e "${GREEN}Mengunduh dalam format MP4...${NC}"
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" \
               --merge-output-format mp4 \
               -o "%(title)s.%(ext)s" \
               "$url"
        ;;
    2)
        echo -e "${GREEN}Mengunduh dalam format MP3...${NC}"
        yt-dlp -x --audio-format mp3 \
               --audio-quality 0 \
               -o "%(title)s.%(ext)s" \
               "$url"
        ;;
    *)
        echo -e "${RED}Pilihan tidak valid!${NC}"
        exit 1
        ;;
esac

# Cek hasil
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Download berhasil!${NC}"
else
    echo ""
    echo -e "${RED}✗ Download gagal!${NC}"
    exit 1
fi
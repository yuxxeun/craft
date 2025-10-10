#!/bin/bash

# Image Resizer
# Resize gambar secara batch dengan berbagai opsi

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}  Image Resizer${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Fungsi untuk cek ImageMagick
check_imagemagick() {
    if ! command -v convert &> /dev/null; then
        echo -e "${RED}✗ ImageMagick tidak terinstall!${NC}"
        echo ""
        echo "Install dengan:"
        echo "  Ubuntu/Debian: sudo apt install imagemagick"
        echo "  macOS: brew install imagemagick"
        echo "  Arch Linux: sudo pacman -S imagemagick"
        exit 1
    fi
}

# Fungsi untuk get image info
get_image_info() {
    local file="$1"
    identify -format "%wx%h %b" "$file" 2>/dev/null
}

# Fungsi untuk resize single image
resize_image() {
    local input="$1"
    local output="$2"
    local width="$3"
    local height="$4"
    local quality="$5"
    local maintain_aspect="$6"
    
    if [ "$maintain_aspect" = "yes" ]; then
        # Maintain aspect ratio
        convert "$input" -resize "${width}x${height}" -quality "$quality" "$output" 2>/dev/null
    else
        # Force exact size (ignore aspect ratio)
        convert "$input" -resize "${width}x${height}!" -quality "$quality" "$output" 2>/dev/null
    fi
    
    return $?
}

# Fungsi untuk resize by percentage
resize_by_percentage() {
    local input="$1"
    local output="$2"
    local percentage="$3"
    local quality="$4"
    
    convert "$input" -resize "$percentage%" -quality "$quality" "$output" 2>/dev/null
    
    return $?
}

# Fungsi untuk resize single file
resize_single_file() {
    read -p "Masukkan path file gambar: " input_file
    
    if [ ! -f "$input_file" ]; then
        echo -e "${RED}✗ File tidak ditemukan!${NC}"
        return 1
    fi
    
    # Tampilkan info gambar
    local info=$(get_image_info "$input_file")
    echo -e "${BLUE}Info gambar:${NC} $info"
    echo ""
    
    echo "Pilih metode resize:"
    echo "1. By dimension (width x height)"
    echo "2. By percentage"
    read -p "Pilihan (1/2): " method
    
    read -p "Output filename (kosongkan untuk overwrite): " output_file
    
    if [ -z "$output_file" ]; then
        output_file="$input_file"
    fi
    
    read -p "Quality (1-100, default: 90): " quality
    quality=${quality:-90}
    
    if [ "$method" = "1" ]; then
        read -p "Width: " width
        read -p "Height: " height
        read -p "Maintain aspect ratio? (y/n, default: y): " aspect
        aspect=${aspect:-y}
        
        if [ "$aspect" = "y" ]; then
            maintain="yes"
        else
            maintain="no"
        fi
    elif [ "$method" = "2" ]; then
        read -p "Percentage (contoh: 50 untuk 50%): " percentage
    else
        echo -e "${RED}✗ Pilihan tidak valid${NC}"
        return 1
    fi
    
    read -p "Quality (1-100, default: 90): " quality
    quality=${quality:-90}
    
    # Hitung total files
    if [ -z "$ext_filter" ]; then
        total=$(find "$input_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) | wc -l)
    else
        total=$(find "$input_dir" -maxdepth 1 -type f -iname "*.$ext_filter" | wc -l)
    fi
    
    if [ $total -eq 0 ]; then
        echo -e "${YELLOW}Tidak ada gambar ditemukan${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Total gambar: $total${NC}"
    echo -e "${YELLOW}⏳ Memulai resize...${NC}"
    echo ""
    
    local success=0
    local failed=0
    local current=0
    
    # Process files
    if [ -z "$ext_filter" ]; then
        files=$(find "$input_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \))
    else
        files=$(find "$input_dir" -maxdepth 1 -type f -iname "*.$ext_filter")
    fi
    
    while IFS= read -r file; do
        ((current++))
        local filename=$(basename "$file")
        local output_file="$output_dir/$filename"
        
        echo -ne "${CYAN}[$current/$total]${NC} Processing: $filename... "
        
        if [ "$method" = "1" ]; then
            if resize_image "$file" "$output_file" "$width" "$height" "$quality" "$maintain"; then
                echo -e "${GREEN}✓${NC}"
                ((success++))
            else
                echo -e "${RED}✗${NC}"
                ((failed++))
            fi
        else
            if resize_by_percentage "$file" "$output_file" "$percentage" "$quality"; then
                echo -e "${GREEN}✓${NC}"
                ((success++))
            else
                echo -e "${RED}✗${NC}"
                ((failed++))
            fi
        fi
    done <<< "$files"
    
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}✓ Berhasil: $success${NC}"
    echo -e "${RED}✗ Gagal: $failed${NC}"
    echo -e "${BLUE}Output: $output_dir${NC}"
}

# Fungsi untuk resize by max dimension
resize_max_dimension() {
    read -p "Masukkan direktori input (default: .): " input_dir
    input_dir=${input_dir:-.}
    
    if [ ! -d "$input_dir" ]; then
        echo -e "${RED}✗ Direktori tidak ditemukan!${NC}"
        return 1
    fi
    
    read -p "Masukkan direktori output (default: ./resized): " output_dir
    output_dir=${output_dir:-./resized}
    
    mkdir -p "$output_dir"
    
    read -p "Max width: " max_width
    read -p "Max height: " max_height
    read -p "Quality (1-100, default: 90): " quality
    quality=${quality:-90}
    
    local files=$(find "$input_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \))
    local total=$(echo "$files" | wc -l)
    
    if [ $total -eq 0 ]; then
        echo -e "${YELLOW}Tidak ada gambar ditemukan${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Total gambar: $total${NC}"
    echo -e "${YELLOW}⏳ Memulai resize...${NC}"
    echo ""
    
    local success=0
    local failed=0
    local current=0
    
    while IFS= read -r file; do
        ((current++))
        local filename=$(basename "$file")
        local output_file="$output_dir/$filename"
        
        echo -ne "${CYAN}[$current/$total]${NC} Processing: $filename... "
        
        # Resize dengan max dimension (maintain aspect ratio)
        if convert "$file" -resize "${max_width}x${max_height}>" -quality "$quality" "$output_file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            ((success++))
        else
            echo -e "${RED}✗${NC}"
            ((failed++))
        fi
    done <<< "$files"
    
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}✓ Berhasil: $success${NC}"
    echo -e "${RED}✗ Gagal: $failed${NC}"
}

# Fungsi untuk compress images
compress_images() {
    read -p "Masukkan direktori input (default: .): " input_dir
    input_dir=${input_dir:-.}
    
    if [ ! -d "$input_dir" ]; then
        echo -e "${RED}✗ Direktori tidak ditemukan!${NC}"
        return 1
    fi
    
    read -p "Masukkan direktori output (default: ./compressed): " output_dir
    output_dir=${output_dir:-./compressed}
    
    mkdir -p "$output_dir"
    
    read -p "Quality (1-100, default: 85): " quality
    quality=${quality:-85}
    
    local files=$(find "$input_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \))
    local total=$(echo "$files" | wc -l)
    
    if [ $total -eq 0 ]; then
        echo -e "${YELLOW}Tidak ada gambar ditemukan${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Total gambar: $total${NC}"
    echo -e "${YELLOW}⏳ Memulai kompresi...${NC}"
    echo ""
    
    local success=0
    local failed=0
    local current=0
    local total_saved=0
    
    while IFS= read -r file; do
        ((current++))
        local filename=$(basename "$file")
        local output_file="$output_dir/$filename"
        
        local size_before=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        
        echo -ne "${CYAN}[$current/$total]${NC} Processing: $filename... "
        
        if convert "$file" -quality "$quality" "$output_file" 2>/dev/null; then
            local size_after=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
            local saved=$((size_before - size_after))
            local percent=$((saved * 100 / size_before))
            
            total_saved=$((total_saved + saved))
            
            echo -e "${GREEN}✓${NC} Saved: ${YELLOW}$percent%${NC}"
            ((success++))
        else
            echo -e "${RED}✗${NC}"
            ((failed++))
        fi
    done <<< "$files"
    
    local total_saved_mb=$((total_saved / 1024 / 1024))
    
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}✓ Berhasil: $success${NC}"
    echo -e "${RED}✗ Gagal: $failed${NC}"
    echo -e "${YELLOW}💾 Total saved: ${total_saved_mb}MB${NC}"
}

# Main
check_imagemagick

echo -e "${GREEN}✓ ImageMagick terinstall${NC}"
echo ""

# Menu
echo "Pilih mode:"
echo "1. Resize single file"
echo "2. Resize batch (multiple files)"
echo "3. Resize by max dimension"
echo "4. Compress images"
read -p "Pilihan (1-4): " choice

echo ""

case $choice in
    1)
        resize_single_file
        ;;
    2)
        resize_batch
        ;;
    3)
        resize_max_dimension
        ;;
    4)
        compress_images
        ;;
    *)
        echo -e "${RED}✗ Pilihan tidak valid${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Selesai!${NC}"}
        
        if [ "$aspect" = "y" ]; then
            maintain="yes"
        else
            maintain="no"
        fi
        
        echo -e "${YELLOW}⏳ Resizing...${NC}"
        
        if resize_image "$input_file" "$output_file" "$width" "$height" "$quality" "$maintain"; then
            local new_info=$(get_image_info "$output_file")
            echo -e "${GREEN}✓ Resize berhasil!${NC}"
            echo -e "${BLUE}New size:${NC} $new_info"
        else
            echo -e "${RED}✗ Resize gagal!${NC}"
        fi
        
    elif [ "$method" = "2" ]; then
        read -p "Percentage (contoh: 50 untuk 50%): " percentage
        
        echo -e "${YELLOW}⏳ Resizing...${NC}"
        
        if resize_by_percentage "$input_file" "$output_file" "$percentage" "$quality"; then
            local new_info=$(get_image_info "$output_file")
            echo -e "${GREEN}✓ Resize berhasil!${NC}"
            echo -e "${BLUE}New size:${NC} $new_info"
        else
            echo -e "${RED}✗ Resize gagal!${NC}"
        fi
    else
        echo -e "${RED}✗ Pilihan tidak valid${NC}"
    fi
}

# Fungsi untuk resize batch
resize_batch() {
    read -p "Masukkan direktori input (default: .): " input_dir
    input_dir=${input_dir:-.}
    
    if [ ! -d "$input_dir" ]; then
        echo -e "${RED}✗ Direktori tidak ditemukan!${NC}"
        return 1
    fi
    
    read -p "Masukkan direktori output (default: ./resized): " output_dir
    output_dir=${output_dir:-./resized}
    
    mkdir -p "$output_dir"
    
    echo ""
    echo "Format yang didukung: jpg, jpeg, png, gif, bmp, webp"
    read -p "Filter extension (kosongkan untuk semua): " ext_filter
    
    echo ""
    echo "Pilih metode resize:"
    echo "1. By dimension (width x height)"
    echo "2. By percentage"
    read -p "Pilihan (1/2): " method
    
    if [ "$method" = "1" ]; then
        read -p "Width: " width
        read -p "Height: " height
        read -p "Maintain aspect ratio? (y/n, default: y): " aspect
        aspect=${aspect:-y
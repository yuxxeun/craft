package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

const (
	// Audio qualities
	AudioBest = "best"
	Audio320k = "320k"
	Audio256k = "256k"
	Audio192k = "192k"
	Audio128k = "128k"

	// Video qualities
	Video2160p = "2160p" // 4K
	Video1440p = "1440p" // 2K
	Video1080p = "1080p" // Full HD
	Video720p  = "720p"  // HD
	Video480p  = "480p"  // SD
	Video360p  = "360p"  // Low
)

type DownloadConfig struct {
	URL         string
	Format      string // mp3 or mp4
	Quality     string
	OutputPath  string
	OutputName  string
	Playlist    bool
	StartNumber int
	EndNumber   int
	Subtitles   bool
	Thumbnail   bool
}

var (
	// Command line flags
	url         = flag.String("url", "", "YouTube video/playlist URL")
	format      = flag.String("format", "mp4", "Output format: mp3 or mp4")
	quality     = flag.String("quality", "best", "Quality: best, 1080p, 720p, 480p, 360p (video) or best, 320k, 192k, 128k (audio)")
	outputPath  = flag.String("output", "./downloads", "Output directory")
	outputName  = flag.String("name", "", "Custom output filename (without extension)")
	playlist    = flag.Bool("playlist", false, "Download entire playlist")
	startNum    = flag.Int("start", 1, "Playlist start number")
	endNum      = flag.Int("end", 0, "Playlist end number (0 = all)")
	subtitles   = flag.Bool("subs", false, "Download subtitles")
	thumbnail   = flag.Bool("thumb", false, "Embed thumbnail")
	interactive = flag.Bool("interactive", false, "Interactive mode")
)

func main() {
	flag.Parse()

	// Check if yt-dlp is installed
	if !checkYtDlpInstalled() {
		fmt.Println("❌ yt-dlp is not installed!")
		fmt.Println("📦 Install with: pip install yt-dlp")
		fmt.Println("   or: brew install yt-dlp (macOS)")
		fmt.Println("   or: sudo apt install yt-dlp (Ubuntu/Debian)")
		os.Exit(1)
	}

	if *interactive {
		runInteractiveMode()
		return
	}

	if *url == "" {
		fmt.Println("❌ Error: URL is required")
		fmt.Println("Usage: ./ytdl -url <youtube-url> [options]")
		fmt.Println("Or use: ./ytdl -interactive")
		flag.PrintDefaults()
		os.Exit(1)
	}

	config := DownloadConfig{
		URL:         *url,
		Format:      *format,
		Quality:     *quality,
		OutputPath:  *outputPath,
		OutputName:  *outputName,
		Playlist:    *playlist,
		StartNumber: *startNum,
		EndNumber:   *endNum,
		Subtitles:   *subtitles,
		Thumbnail:   *thumbnail,
	}

	downloadVideo(config)
}

func runInteractiveMode() {
	reader := bufio.NewReader(os.Stdin)

	fmt.Println("🎬 YouTube Downloader")
	fmt.Println("═══════════════════════════════════════")
	fmt.Println()

	// Get URL
	fmt.Print("📺 YouTube URL: ")
	url, _ := reader.ReadString('\n')
	url = strings.TrimSpace(url)

	if url == "" {
		fmt.Println("❌ URL cannot be empty!")
		os.Exit(1)
	}

	// Check if playlist
	fmt.Print("📋 Is this a playlist? (y/N): ")
	playlistInput, _ := reader.ReadString('\n')
	isPlaylist := strings.ToLower(strings.TrimSpace(playlistInput)) == "y"

	// Get format
	fmt.Println()
	fmt.Println("📁 Choose format:")
	fmt.Println("  1. MP4 (Video)")
	fmt.Println("  2. MP3 (Audio only)")
	fmt.Print("Select (1-2): ")
	formatInput, _ := reader.ReadString('\n')
	formatInput = strings.TrimSpace(formatInput)

	var format string
	switch formatInput {
	case "1":
		format = "mp4"
	case "2":
		format = "mp3"
	default:
		format = "mp4"
	}

	// Get quality
	fmt.Println()
	var quality string
	if format == "mp4" {
		fmt.Println("🎥 Choose video quality:")
		fmt.Println("  1. Best (Highest available)")
		fmt.Println("  2. 2160p (4K)")
		fmt.Println("  3. 1440p (2K)")
		fmt.Println("  4. 1080p (Full HD)")
		fmt.Println("  5. 720p (HD)")
		fmt.Println("  6. 480p (SD)")
		fmt.Println("  7. 360p (Low)")
		fmt.Print("Select (1-7): ")
		qualityInput, _ := reader.ReadString('\n')
		qualityInput = strings.TrimSpace(qualityInput)

		switch qualityInput {
		case "1":
			quality = "best"
		case "2":
			quality = Video2160p
		case "3":
			quality = Video1440p
		case "4":
			quality = Video1080p
		case "5":
			quality = Video720p
		case "6":
			quality = Video480p
		case "7":
			quality = Video360p
		default:
			quality = "best"
		}
	} else {
		fmt.Println("🎵 Choose audio quality:")
		fmt.Println("  1. Best (320k)")
		fmt.Println("  2. 256k")
		fmt.Println("  3. 192k")
		fmt.Println("  4. 128k")
		fmt.Print("Select (1-4): ")
		qualityInput, _ := reader.ReadString('\n')
		qualityInput = strings.TrimSpace(qualityInput)

		switch qualityInput {
		case "1":
			quality = Audio320k
		case "2":
			quality = Audio256k
		case "3":
			quality = Audio192k
		case "4":
			quality = Audio128k
		default:
			quality = Audio320k
		}
	}

	// Additional options
	fmt.Println()
	fmt.Print("📥 Download subtitles? (y/N): ")
	subsInput, _ := reader.ReadString('\n')
	downloadSubs := strings.ToLower(strings.TrimSpace(subsInput)) == "y"

	fmt.Print("🖼️  Embed thumbnail? (y/N): ")
	thumbInput, _ := reader.ReadString('\n')
	embedThumb := strings.ToLower(strings.TrimSpace(thumbInput)) == "y"

	// Output path
	fmt.Print("📂 Output directory (default: ./downloads): ")
	outputPathInput, _ := reader.ReadString('\n')
	outputPathInput = strings.TrimSpace(outputPathInput)
	if outputPathInput == "" {
		outputPathInput = "./downloads"
	}

	config := DownloadConfig{
		URL:        url,
		Format:     format,
		Quality:    quality,
		OutputPath: outputPathInput,
		Playlist:   isPlaylist,
		Subtitles:  downloadSubs,
		Thumbnail:  embedThumb,
	}

	fmt.Println()
	downloadVideo(config)
}

func checkYtDlpInstalled() bool {
	cmd := exec.Command("yt-dlp", "--version")
	err := cmd.Run()
	return err == nil
}

func downloadVideo(config DownloadConfig) {
	// Create output directory
	if err := os.MkdirAll(config.OutputPath, 0755); err != nil {
		fmt.Printf("❌ Error creating directory: %v\n", err)
		os.Exit(1)
	}

	// Print download info
	fmt.Println("📥 Download Configuration")
	fmt.Println("═══════════════════════════════════════")
	fmt.Printf("🔗 URL: %s\n", config.URL)
	fmt.Printf("📁 Format: %s\n", strings.ToUpper(config.Format))
	fmt.Printf("🎯 Quality: %s\n", config.Quality)
	fmt.Printf("📂 Output: %s\n", config.OutputPath)
	if config.Playlist {
		fmt.Printf("📋 Playlist: Yes\n")
	}
	fmt.Println("═══════════════════════════════════════")
	fmt.Println()

	// Build yt-dlp command
	args := buildYtDlpArgs(config)

	fmt.Println("⏳ Starting download...")
	fmt.Println()

	// Execute download
	cmd := exec.Command("yt-dlp", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	startTime := time.Now()
	err := cmd.Run()

	if err != nil {
		fmt.Printf("\n❌ Download failed: %v\n", err)
		os.Exit(1)
	}

	duration := time.Since(startTime)
	fmt.Println()
	fmt.Println("═══════════════════════════════════════")
	fmt.Printf("✅ Download completed in %s\n", formatDuration(duration))
	fmt.Printf("📂 Files saved to: %s\n", config.OutputPath)
	fmt.Println("═══════════════════════════════════════")
}

func buildYtDlpArgs(config DownloadConfig) []string {
	args := []string{}

	// Output template
	outputTemplate := filepath.Join(config.OutputPath, "%(title)s.%(ext)s")
	if config.OutputName != "" {
		outputTemplate = filepath.Join(config.OutputPath, config.OutputName+".%(ext)s")
	}
	args = append(args, "-o", outputTemplate)

	// Format and quality
	if config.Format == "mp3" {
		args = append(args, "-x", "--audio-format", "mp3")

		// Audio quality
		switch config.Quality {
		case Audio320k:
			args = append(args, "--audio-quality", "0") // Best
		case Audio256k:
			args = append(args, "--audio-quality", "2")
		case Audio192k:
			args = append(args, "--audio-quality", "5")
		case Audio128k:
			args = append(args, "--audio-quality", "7")
		default:
			args = append(args, "--audio-quality", "0")
		}
	} else {
		// Video format
		if config.Quality == "best" {
			args = append(args, "-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best")
		} else {
			formatString := fmt.Sprintf("bestvideo[height<=%s][ext=mp4]+bestaudio[ext=m4a]/best[height<=%s][ext=mp4]/best",
				strings.TrimSuffix(config.Quality, "p"),
				strings.TrimSuffix(config.Quality, "p"))
			args = append(args, "-f", formatString)
		}

		// Merge to mp4
		args = append(args, "--merge-output-format", "mp4")
	}

	// Playlist options
	if config.Playlist {
		if config.StartNumber > 1 {
			args = append(args, "--playlist-start", fmt.Sprintf("%d", config.StartNumber))
		}
		if config.EndNumber > 0 {
			args = append(args, "--playlist-end", fmt.Sprintf("%d", config.EndNumber))
		}
	} else {
		args = append(args, "--no-playlist")
	}

	// Subtitles
	if config.Subtitles {
		args = append(args, "--write-subs", "--write-auto-subs", "--sub-lang", "en,id")
		if config.Format == "mp4" {
			args = append(args, "--embed-subs")
		}
	}

	// Thumbnail
	if config.Thumbnail {
		args = append(args, "--embed-thumbnail")
	}

	// Metadata
	args = append(args, "--add-metadata")

	// Progress
	args = append(args, "--progress")

	// URL
	args = append(args, config.URL)

	return args
}

func formatDuration(d time.Duration) string {
	d = d.Round(time.Second)
	h := d / time.Hour
	d -= h * time.Hour
	m := d / time.Minute
	d -= m * time.Minute
	s := d / time.Second

	if h > 0 {
		return fmt.Sprintf("%dh %dm %ds", h, m, s)
	}
	if m > 0 {
		return fmt.Sprintf("%dm %ds", m, s)
	}
	return fmt.Sprintf("%ds", s)
}

import os, strutils, times, osproc

proc optimizeImage(filepath: string): bool =
  echo "Optimizing: ", filepath
  let ext = filepath.splitFile.ext.toLowerAscii
  
  var cmd = ""
  case ext
  of ".jpg", ".jpeg":
    cmd = "jpegoptim --strip-all --max=85 " & filepath
  of ".png":
    cmd = "optipng -o7 " & filepath
  of ".webp":
    cmd = "cwebp -q 80 " & filepath & " -o " & filepath
  else:
    echo "Unsupported format: ", ext
    return false
  
  let exitCode = execCmd(cmd)
  return exitCode == 0

proc scanAndOptimize(directory: string) =
  var optimized = 0
  var failed = 0
  
  for file in walkDirRec(directory):
    let ext = file.splitFile.ext.toLowerAscii
    if ext in [".jpg", ".jpeg", ".png", ".webp"]:
      if optimizeImage(file):
        inc optimized
      else:
        inc failed
  
  echo "\n📊 Summary:"
  echo "✅ Optimized: ", optimized, " images"
  echo "❌ Failed: ", failed, " images"
  echo "⏰ Time: ", now()

when isMainModule:
  let targetDir = if paramCount() > 0: paramStr(1) else: "/var/www/uploads"
  echo "🖼️  Starting image optimization..."
  echo "📁 Directory: ", targetDir
  scanAndOptimize(targetDir)
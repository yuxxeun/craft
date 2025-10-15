# Nim - simple PPM(P6) -> ASCII converter
proc imageToAscii(w: int, h: int, data: seq[byte], outWidth: int, chars: string, invert: bool): string =
# adjust height because characters are taller than wide
let aspect = float(h) / float(w)
let outH = max(1, int((float(outWidth) * aspect) / 2.0))


# nearest-neighbor sampling
var sb = newStringOfCap(outWidth * (outH + 1))
for y in 0..<outH:
let srcY = int((y * h) div outH)
for x in 0..<outWidth:
let srcX = int((x * w) div outWidth)
let idx = (srcY*w + srcX)*3
let r = int(data[idx])
let g = int(data[idx+1])
let b = int(data[idx+2])
let br = pixelBrightness(r,g,b)
sb.add brightnessToChar(br, chars, invert)
sb.add '\n'
sb


when isMainModule:
if paramCount() < 1:
echo "Usage: nim c -r craft_art.nim <image.ppm> [width] [--invert] [--chars=...]"
quit(1)


let path = paramStr(1)
var outW = 100
var invert = false
var chars = DEFAULT_CHARS


for i in 2..paramCount():
let p = paramStr(i)
if p == "--invert": invert = true
elif p.startsWith("--chars="):
chars = p.split("=")[1]
else:
if p.parseInt(res=outW):
discard 0


if not fileExists(path):
echo "File not found: ", path
quit(1)


let (w,h,data) = readPPM(path)
let ascii = imageToAscii(w,h,data,outW,chars,invert)
stdout.write ascii
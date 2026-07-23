#!/usr/bin/env bash
# _image_tool — resize, convert, strip EXIF, batch-optimize images.
# Prefix: it_
# Backends: convert/magick (ImageMagick), cwebp, exiftool, optipng/jpegoptim

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_has_cmd  >/dev/null 2>&1; then uk_has_cmd()  { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error    >/dev/null 2>&1; then uk_error()    { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn     >/dev/null 2>&1; then uk_warn()     { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info     >/dev/null 2>&1; then uk_info()     { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success  >/dev/null 2>&1; then uk_success()  { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note     >/dev/null 2>&1; then uk_note()     { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner   >/dev/null 2>&1; then uk_banner()   { :; }; fi
if ! declare -f uk_prompt   >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply
    printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm  >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''
    printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then echo macos
    else echo linux; fi
  }
fi
if ! declare -f uk_expand_path >/dev/null 2>&1; then
  uk_expand_path() { local i="${1:-}"; printf '%s\n' "${i/#\~/$HOME}"; }
fi
# --------------------------

# Dry-run by default: file-writing subcommands only write when IT_APPLY=1.
IT_APPLY=0

it_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage:\n  _image_tool.sh <subcommand> FILE [OPTIONS]\n\n'
  uk_help_section "$w" "Subcommands" \
    "info FILE" "Show image dimensions, format, size." \
    "resize FILE" "Resize image (--width, --height, --percent)." \
    "convert FILE" "Convert between formats (--format png/jpg/webp)." \
    "strip FILE" "Strip EXIF/metadata (requires exiftool or imagemagick)." \
    "optimize FILE" "Optimize file size (optipng/jpegoptim/cwebp)." \
    "thumb FILE" "Generate a thumbnail (--size 200)."
  printf '\n'
  uk_help_section "$w" "Options" \
    "--width N" "Target width in pixels." \
    "--height N" "Target height in pixels." \
    "--percent N" "Resize percentage (e.g. 50)." \
    "--format FMT" "Target format (png, jpg, webp, gif)." \
    "--quality N" "JPEG/WebP quality 1-100 (default 85)." \
    "--size N" "Thumbnail max dimension." \
    "--out FILE" "Output path." \
    "--apply" "Actually write/overwrite output files (default is dry-run)." \
    "--recursive" "Reserved; currently rejected instead of silently ignored." \
    "--json" "Machine-readable output (info)." \
    "--no-color" "Disable ANSI (also respects NO_COLOR=1)." \
    "-h, --help" "Show this help."
  printf '\nSafety:\n'
  printf '  File-writing subcommands (resize, convert, strip, optimize, thumb) preview\n'
  printf '  only by default. Re-run with --apply to write the output file(s).\n\n'
  printf 'Backends: ImageMagick (convert/magick), exiftool, optipng, jpegoptim, cwebp.\n\n'
  printf 'Examples:\n'
  printf '  _image_tool.sh info photo.jpg\n'
  printf '  _image_tool.sh resize photo.jpg --width 800 --out resized.jpg\n'
  printf '  _image_tool.sh convert photo.png --format webp\n'
  printf '  _image_tool.sh strip photo.jpg --out clean.jpg\n'
  printf '  _image_tool.sh optimize photo.png\n'
}

it_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}
it_section() {
  local title="${1:-}"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  it_hr
}

it_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

it_has_convert() { uk_has_cmd convert || uk_has_cmd magick; }
it_convert_cmd() { uk_has_cmd magick && printf 'magick\n' || printf 'convert\n'; }

it_prepare_output() {
  local out="${1:-}"
  [[ -z "$out" ]] && return 0
  local dir
  dir="$(dirname -- "$out")"
  [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null || { uk_error "Cannot create output directory: $dir"; return 1; }
}

it_validate_int() {
  local name="$1" val="$2" min="${3:-1}" max="${4:-}"
  [[ -z "$val" ]] && return 0
  [[ "$val" =~ ^[0-9]+$ ]] || { uk_error "$name must be a positive integer: $val"; return 2; }
  (( val >= min )) || { uk_error "$name must be >= $min"; return 2; }
  [[ -z "$max" || "$val" -le "$max" ]] || { uk_error "$name must be <= $max"; return 2; }
}

it_cmd_info() {
  local file="$1" as_json="$2"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }

  if (( as_json )); then
    local w h fmt size cmd
    if it_has_convert; then
      cmd="$(it_convert_cmd)"
      read -r w h fmt <<<"$($cmd "$file" -format '%w %h %m' info: 2>/dev/null || true)"
    fi
    size="$(wc -c <"$file" | tr -d ' ')"
    printf '{"file":%s,"width":%s,"height":%s,"format":%s,"bytes":%s}\n' \
      "$(it_json_escape "$file")" \
      "$(it_json_escape "${w:-}")" \
      "$(it_json_escape "${h:-}")" \
      "$(it_json_escape "${fmt:-}")" \
      "${size:-0}"
    return 0
  fi

  it_section "Image Info: $file"
  local w h fmt size
  size="$(wc -c <"$file" | tr -d ' ')"
  if it_has_convert; then
    local cmd; cmd="$(it_convert_cmd)"
    read -r w h fmt <<<"$($cmd "$file" -format '%w %h %m' info: 2>/dev/null || true)"
    printf '  %s%-12s%s  %s\n' "${UK_C_DIM:-}" "Dimensions" "${UK_C_RESET:-}" "${w}x${h}"
    printf '  %s%-12s%s  %s\n' "${UK_C_DIM:-}" "Format" "${UK_C_RESET:-}" "$fmt"
  fi
  printf '  %s%-12s%s  %d bytes\n' "${UK_C_DIM:-}" "Size" "${UK_C_RESET:-}" "$size"
}

it_cmd_resize() {
  local file="$1" width="$2" height="$3" percent="$4" out="$5"
  it_has_convert || { uk_error "ImageMagick required (convert/magick)."; return 2; }
  [[ -z "$out" ]] && out="${file%.*}_resized.${file##*.}"
  it_prepare_output "$out" || return $?

  if (( IT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would write resized image to: $out"
    uk_note "Re-run with --apply to write the file."
    return 0
  fi

  local cmd
  cmd="$(it_convert_cmd)"
  local -a args=()
  if [[ -n "$percent" ]]; then
    args+=(-resize "${percent}%")
  elif [[ -n "$width" && -n "$height" ]]; then
    args+=(-resize "${width}x${height}!")
  elif [[ -n "$width" ]]; then
    args+=(-resize "${width}x")
  elif [[ -n "$height" ]]; then
    args+=(-resize "x${height}")
  else
    uk_error "Provide --width, --height, or --percent."; return 2
  fi

  $cmd "$file" "${args[@]}" "$out" 2>/dev/null
  local rc=$?
  (( rc == 0 )) && uk_success "Resized: $out" || uk_error "Resize failed."
  return "$rc"
}

it_cmd_convert() {
  local file="$1" fmt="$2" quality="$3" out="$4"
  it_has_convert || { uk_error "ImageMagick required (convert/magick)."; return 2; }
  [[ -z "$fmt" ]] && { uk_error "Target format required (--format)."; return 2; }
  [[ -z "$out" ]] && out="${file%.*}.${fmt}"
  it_prepare_output "$out" || return $?

  if (( IT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would write converted image to: $out"
    uk_note "Re-run with --apply to write the file."
    return 0
  fi

  local cmd
  cmd="$(it_convert_cmd)"
  local -a args=()
  [[ -n "$quality" ]] && args+=(-quality "$quality")

  $cmd "$file" "${args[@]}" "${fmt^^}:$out" 2>/dev/null
  local rc=$?
  (( rc == 0 )) && uk_success "Converted: $out" || uk_error "Conversion failed."
  return "$rc"
}

it_cmd_strip() {
  local file="$1" out="$2"
  [[ -z "$out" ]] && out="${file%.*}_clean.${file##*.}"
  it_prepare_output "$out" || return $?

  if (( IT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would write metadata-stripped image to: $out"
    uk_note "Re-run with --apply to write the file."
    return 0
  fi

  if uk_has_cmd exiftool; then
    exiftool -all= -overwrite_original "$file" -o "$out" 2>/dev/null
    local rc=$?
    (( rc == 0 )) && uk_success "Stripped EXIF: $out" || uk_error "Strip failed."
    return "$rc"
  elif it_has_convert; then
    local cmd
    cmd="$(it_convert_cmd)"
    $cmd "$file" -strip "$out" 2>/dev/null
    local rc=$?
    (( rc == 0 )) && uk_success "Stripped metadata: $out" || uk_error "Strip failed."
    return "$rc"
  else
    uk_error "Install exiftool or ImageMagick to strip metadata."
    return 2
  fi
}

it_cmd_optimize() {
  local file="$1" quality="$2"
  local ext="${file##*.}"
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

  if (( IT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would optimize (rewrite in place): $file"
    uk_note "Re-run with --apply to overwrite the original file."
    return 0
  fi

  case "$ext" in
    png)
      if uk_has_cmd optipng; then
        optipng -quiet -strip all "$file" || { uk_error "PNG optimization failed."; return 1; }
        uk_success "Optimized PNG: $file"
      elif uk_has_cmd pngcrush; then
        local tmp; tmp="$(mktemp)" || return 1
        if ! pngcrush -q "$file" "$tmp" || ! mv "$tmp" "$file"; then
          rm -f "$tmp"
          uk_error "PNG optimization failed."
          return 1
        fi
        uk_success "Optimized PNG: $file"
      else
        uk_error "Install optipng or pngcrush for PNG optimization."
        return 2
      fi
      ;;
    jpg|jpeg)
      if uk_has_cmd jpegoptim; then
        local -a jpeg_args=(--strip-all --quiet)
        [[ -n "$quality" ]] && jpeg_args+=("--max=$quality")
        jpegoptim "${jpeg_args[@]}" "$file" || { uk_error "JPEG optimization failed."; return 1; }
        uk_success "Optimized JPEG: $file"
      elif it_has_convert; then
        local cmd; cmd="$(it_convert_cmd)"
        local tmp; tmp="$(mktemp).jpg" || return 1
        local -a convert_args=()
        [[ -n "$quality" ]] && convert_args+=(-quality "$quality")
        if ! $cmd "$file" "${convert_args[@]}" "$tmp" || ! mv "$tmp" "$file"; then
          rm -f "$tmp"
          uk_error "JPEG optimization failed."
          return 1
        fi
        uk_success "Optimized JPEG: $file"
      else
        uk_error "Install jpegoptim or ImageMagick for JPEG optimization."
        return 2
      fi
      ;;
    webp)
      if uk_has_cmd cwebp; then
        local tmp; tmp="$(mktemp).webp" || return 1
        local -a webp_args=(-quiet)
        [[ -n "$quality" ]] && webp_args+=(-q "$quality")
        if ! cwebp "${webp_args[@]}" "$file" -o "$tmp" || ! mv "$tmp" "$file"; then
          rm -f "$tmp"
          uk_error "WebP optimization failed."
          return 1
        fi
        uk_success "Optimized WebP: $file"
      else
        uk_error "Install cwebp for WebP optimization."
        return 2
      fi
      ;;
    *)
      uk_warn "No optimizer for .$ext files."
      return 1
      ;;
  esac
}

it_cmd_thumb() {
  local file="$1" size="$2" out="$3"
  it_has_convert || { uk_error "ImageMagick required (convert/magick)."; return 2; }
  [[ -z "$size" ]] && size=200
  [[ -z "$out" ]] && out="${file%.*}_thumb.${file##*.}"
  it_validate_int "--size" "$size" 1 10000 || return $?
  it_prepare_output "$out" || return $?

  if (( IT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would write thumbnail to: $out"
    uk_note "Re-run with --apply to write the file."
    return 0
  fi

  local cmd
  cmd="$(it_convert_cmd)"
  $cmd "$file" -thumbnail "${size}x${size}^" -gravity center -extent "${size}x${size}" "$out" 2>/dev/null
  local rc=$?
  (( rc == 0 )) && uk_success "Thumbnail: $out" || uk_error "Thumbnail generation failed."
  return "$rc"
}

it_main() {
  uk_banner "image-tool" "Resize, convert, strip, optimize images" "" "$@"

  local sub="" file="" out="" fmt="" quality=""
  local width="" height="" percent="" size=""
  local as_json=0 recursive=0
  IT_APPLY=0

  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
      info|resize|convert|strip|optimize|thumb) sub="$1"; shift ;;
      -h|--help) it_usage; return 0 ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --width)   shift; width="${1:-}" ;;
      --height)  shift; height="${1:-}" ;;
      --percent) shift; percent="${1:-}" ;;
      --format)  shift; fmt="${1:-}" ;;
      --quality) shift; quality="${1:-}" ;;
      --size)    shift; size="${1:-}" ;;
      --out)     shift; out="${1:-}" ;;
      --apply)   IT_APPLY=1 ;;
      --recursive) recursive=1 ;;
      --json)    as_json=1 ;;
      --no-color) UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                  UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help) it_usage; return 0 ;;
      -*)        uk_error "Unknown: ${1:-}"; it_usage; return 2 ;;
      *)         file="$1" ;;
    esac
    shift || true
  done

  [[ -z "$sub" ]] && { uk_error "Subcommand required."; it_usage; return 2; }
  [[ -z "$file" ]] && { uk_error "FILE required."; it_usage; return 2; }
  (( recursive == 0 )) || { uk_error "--recursive is not implemented yet; pass one file at a time."; return 2; }
  [[ -f "$file" ]] || { uk_error "File not found: $file"; return 2; }
  it_validate_int "--width" "$width" 1 100000 || return $?
  it_validate_int "--height" "$height" 1 100000 || return $?
  it_validate_int "--percent" "$percent" 1 10000 || return $?
  it_validate_int "--quality" "$quality" 1 100 || return $?

  case "$sub" in
    info)     it_cmd_info "$file" "$as_json" ;;
    resize)   it_cmd_resize "$file" "$width" "$height" "$percent" "$out" ;;
    convert)  it_cmd_convert "$file" "$fmt" "$quality" "$out" ;;
    strip)    it_cmd_strip "$file" "$out" ;;
    optimize) it_cmd_optimize "$file" "$quality" ;;
    thumb)    it_cmd_thumb "$file" "$size" "$out" ;;
    *)        it_usage; return 2 ;;
  esac
}

it_wizard() {
  uk_banner "image-tool" "Resize, convert, strip, optimize images" ""
  local sub file out fmt quality width height pct size jsonf

  sub="$(uk_prompt 'Action: info, resize, convert, strip, optimize, thumb' 'info' \
    'info | resize | convert | strip | optimize | thumb' \
    'info = dimensions/format. resize = change dimensions.')"
  file="$(uk_prompt 'Image file' './photo.jpg' './image.png' 'Required.')"
  file="$(uk_expand_path "$file" 2>/dev/null || echo "$file")"

  case "$sub" in
    info)
      if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
      local -a a=(info "$file")
      [[ -n "$jsonf" ]] && a+=("$jsonf")
      it_main "${a[@]}"
      ;;
    resize)
      uk_note "Enter target dimensions (provide at least one)."
      width="$(uk_prompt 'Width (pixels)' '' '800' 'Blank = auto')"
      height="$(uk_prompt 'Height (pixels)' '' '600' 'Blank = auto')"
      pct="$(uk_prompt 'Percent (overrides w/h)' '' '50' 'Leave blank for absolute resize.')"
      out="$(uk_prompt 'Output file' "${file%.*}_resized.${file##*.}" './out.jpg' '')"
      out="$(uk_expand_path "$out" 2>/dev/null || echo "$out")"
      local -a a=(resize "$file")
      [[ -n "$width"  ]] && a+=(--width "$width")
      [[ -n "$height" ]] && a+=(--height "$height")
      [[ -n "$pct"    ]] && a+=(--percent "$pct")
      [[ -n "$out"    ]] && a+=(--out "$out")
      uk_confirm 'Write the resized image now?' 'N' && a+=(--apply)
      it_main "${a[@]}"
      ;;
    convert)
      fmt="$(uk_prompt 'Target format: png, jpg, webp, gif' 'png' 'webp' '')"
      quality="$(uk_prompt 'Quality (1-100, blank=85)' '' '90' 'JPEG/WebP only.')"
      out="$(uk_prompt 'Output file' "${file%.*}.$fmt" './out.webp' '')"
      out="$(uk_expand_path "$out" 2>/dev/null || echo "$out")"
      local -a a=(convert "$file" --format "$fmt")
      [[ -n "$quality" ]] && a+=(--quality "$quality")
      [[ -n "$out"    ]] && a+=(--out "$out")
      uk_confirm 'Write the converted image now?' 'N' && a+=(--apply)
      it_main "${a[@]}"
      ;;
    strip)
      out="$(uk_prompt 'Output file' "${file%.*}_clean.${file##*.}" './clean.jpg' '')"
      out="$(uk_expand_path "$out" 2>/dev/null || echo "$out")"
      local -a a=(strip "$file" --out "$out")
      uk_confirm 'Write the metadata-stripped image now?' 'N' && a+=(--apply)
      it_main "${a[@]}"
      ;;
    optimize)
      quality="$(uk_prompt 'JPEG quality (1-100, blank=85)' '' '80' 'Only applies to JPEG.')"
      local -a a=(optimize "$file")
      [[ -n "$quality" ]] && a+=(--quality "$quality")
      uk_confirm 'Optimize (rewrite) the image in place now?' 'N' && a+=(--apply)
      it_main "${a[@]}"
      ;;
    thumb)
      size="$(uk_prompt 'Thumbnail max dimension' '200' '150' 'Square crop.')"
      out="$(uk_prompt 'Output file' "${file%.*}_thumb.${file##*.}" './thumb.jpg' '')"
      out="$(uk_expand_path "$out" 2>/dev/null || echo "$out")"
      local -a a=(thumb "$file" --size "$size" --out "$out")
      uk_confirm 'Write the thumbnail now?' 'N' && a+=(--apply)
      it_main "${a[@]}"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    it_wizard
  else
    it_main "$@"
  fi
fi

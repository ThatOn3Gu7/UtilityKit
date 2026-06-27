#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

MC_KIND='image'
MC_TO='webp'
MC_QUALITY=82
MC_APPLY=0
MC_STRIP_EXIF=0
MC_OUTPUT=''
declare -a MC_PATHS=()

mc_usage() {
  cat <<'USAGE'
Usage:
  _media_convert.sh --kind image|video --to webp|jpg|png|mp4 [--quality 82] [--strip-exif] [--output DIR] [--apply] PATH...
USAGE
}

mc_collect() {
  local p
  for p in "${MC_PATHS[@]}"; do
    if [[ -d "$p" ]]; then
      case "$MC_KIND" in
      image) find "$p" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) ;;
      video) find "$p" -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' -o -iname '*.avi' \) ;;
      esac
    elif [[ -f "$p" ]]; then
      printf '%s\n' "$p"
    fi
  done
}

mc_require_tool() {
  case "$MC_KIND" in
  image)
    uk_has_cmd magick || uk_has_cmd ffmpeg || {
      uk_error 'Need ImageMagick (magick) or ffmpeg for image conversion.'
      return 1
    }
    ;;
  video)
    uk_has_cmd ffmpeg || {
      uk_error 'ffmpeg is required for video conversion.'
      return 1
    }
    ;;
  esac
}
mc_fake_progress() {
  local pid="$1" width=28 pct=0 fill empty
  local ch_fill ch_empty
  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    ch_fill='█'
    ch_empty='░'
  else
    ch_fill='#'
    ch_empty='-'
  fi

  local c_bar c_done
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    c_bar="$UK_C_CYAN"
    c_done="$UK_C_GREEN"
  else
    c_bar=''
    c_done=''
  fi

  printf '\n' # optional: start with a blank line

  while kill -0 "$pid" 2>/dev/null; do
    # Acceleration logic (your original, slightly modified)
    if ((pct < 50)); then
      pct=$((pct + 4))
      sleep 0.06
    elif ((pct < 85)); then
      pct=$((pct + 1))
      sleep 0.25
    elif ((pct < 99)); then
      pct=$((pct + 1))
      sleep 0.80
    fi
    ((pct > 99)) && pct=99

    fill=$((pct * width / 100))
    empty=$((width - fill))

    # Build the fill/empty strings using bash substitution – NO tr!
    local bar_fill bar_empty
    printf -v bar_fill '%*s' "$fill" ''
    printf -v bar_empty '%*s' "$empty" ''
    bar_fill="${bar_fill// /$ch_fill}"
    bar_empty="${bar_empty// /$ch_empty}"

    printf '\r  %s⚙%s [%s%s%s%s%s] %s%3d%%%s  converting...' \
      "$UK_C_CYAN" "$UK_C_RESET" \
      "$c_bar" "$bar_fill" \
      "$UK_C_DIM" "$bar_empty" "$UK_C_RESET" \
      "$UK_C_BOLD" "$pct" "$UK_C_RESET"
  done

  wait "$pid" 2>/dev/null || true

  # Final 100% bar
  fill=$width
  printf -v bar_fill '%*s' "$fill" ''
  bar_fill="${bar_fill// /$ch_fill}"

  printf '\r  %s✔%s [%s%s%s] %s100%%%s  done.%*s\n' \
    "$UK_C_GREEN" "$UK_C_RESET" \
    "$c_done" "$bar_fill" "$UK_C_RESET" \
    "$UK_C_BOLD" "$UK_C_RESET" 12 ''
}
mc_convert_one() {
  local src="$1" base out
  base="$(basename "${src%.*}")"
  out="$MC_OUTPUT/${base}.${MC_TO}"

  if ((MC_APPLY == 0)); then
    printf '  %s→%s %s%s%s  %s->%s  %s%s%s\n' \
      "$UK_C_DIM" "$UK_C_RESET" \
      "$UK_C_CYAN" "$src" "$UK_C_RESET" \
      "$UK_C_DIM" "$UK_C_RESET" \
      "$UK_C_GREEN" "$out" "$UK_C_RESET"
    return 0
  fi

  mkdir -p "$MC_OUTPUT"
  printf '  %sConverting:%s %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$src" "$UK_C_RESET"

  if [[ "$MC_KIND" == 'image' ]]; then
    if uk_has_cmd magick; then
      if ((MC_STRIP_EXIF == 1)); then
        magick "$src" -strip -quality "$MC_QUALITY" "$out" >/dev/null 2>&1 &
      else
        magick "$src" -quality "$MC_QUALITY" "$out" >/dev/null 2>&1 &
      fi
    else
      ffmpeg -y -i "$src" -qscale:v 3 "$out" >/dev/null 2>&1 &
    fi
  else
    printf '  %s(using ffmpeg libx264 crf=26)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    ffmpeg -y -i "$src" -vcodec libx264 -crf 26 -preset medium -movflags +faststart "$out" >/dev/null 2>&1 &
  fi

  local _mc_bg=$!
  if [[ -t 1 ]]; then
    mc_fake_progress "$_mc_bg"
  else
    wait "$_mc_bg"
  fi

  if [[ -f "$out" ]]; then
    uk_success "Created: $out"
  else
    uk_error "Conversion failed: $out"
  fi
}
mc_main() {
  uk_banner "media-convert" "Batch image and video conversion via ImageMagick or ffmpeg" "" "$@"
  MC_KIND='image'
  MC_TO='webp'
  MC_QUALITY=82
  MC_APPLY=0
  MC_STRIP_EXIF=0
  MC_OUTPUT=''
  MC_PATHS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --kind)
      shift
      MC_KIND="${1:-image}"
      ;;
    --to)
      shift
      MC_TO="${1:-webp}"
      ;;
    --quality)
      shift
      MC_QUALITY="${1:-82}"
      ;;
    --strip-exif) MC_STRIP_EXIF=1 ;;
    --output)
      shift
      MC_OUTPUT="${1:-}"
      ;;
    --apply) MC_APPLY=1 ;;
    -h | --help)
      mc_usage
      return 0
      ;;
    *) MC_PATHS+=("$1") ;;
    esac
    shift
  done

  # Interactive mode
  if ((${#MC_PATHS[@]} == 0)) && [[ -t 0 && -t 1 ]]; then

    MC_KIND="$(uk_prompt \
      'Enter conversion kind' \
      'image' \
      'image  →  uses ImageMagick or ffmpeg  |  video  →  uses ffmpeg' \
      'Choose image for photos and graphics, video for mp4/mov/mkv files.')"

    local input_path
    input_path="$(uk_prompt \
      'Enter source file or directory to convert' \
      '' \
      '~/Pictures  |  ./assets/images  |  ./recording.mov' \
      'A directory will be scanned recursively for matching files.')"
    [[ -n "$input_path" ]] || {
      uk_warn 'No path entered. Exiting.'
      return 0
    }
    MC_PATHS+=("$input_path")

    if [[ "$MC_KIND" == 'video' ]]; then
      MC_TO="$(uk_prompt \
        'Enter target video format' \
        'mp4' \
        'mp4  →  widely compatible  |  mkv  →  open container' \
        'mp4 is the safest default for sharing and playback.')"
    else
      MC_TO="$(uk_prompt \
        'Enter target image format' \
        'webp' \
        'webp  →  small and modern  |  jpg  →  universal  |  png  →  lossless' \
        'webp gives the best size/quality ratio for web and chat use.')"

      MC_QUALITY="$(uk_prompt \
        'Enter output quality (1-100)' \
        '82' \
        '82  →  good default  |  95  →  high quality  |  60  →  smaller files' \
        'Higher values preserve more detail but produce larger files.')"

      if uk_confirm 'Strip EXIF metadata from images? (removes location, camera info)' 'Y'; then
        MC_STRIP_EXIF=1
      fi
    fi

    MC_OUTPUT="$(uk_prompt \
      'Enter output directory for converted files' \
      "$(pwd)/converted_${MC_KIND}" \
      '~/converted  |  ./output  |  leave blank for default' \
      'Converted files are written here so your originals stay intact.')"

    if uk_confirm 'Apply conversion now? (dry-run preview if you say no)' 'N'; then
      MC_APPLY=1
    fi
  elif ((${#MC_PATHS[@]} == 0)); then
    mc_usage
    return 1
  fi

  # Set default output directory if still empty
  MC_OUTPUT=${MC_OUTPUT:-"$(pwd)/converted_${MC_KIND}"}

  # Validate that the input path exists
  local path_exists=0
  for p in "${MC_PATHS[@]}"; do
    if [[ -e "$p" ]]; then
      path_exists=1
      break
    fi
  done
  if ((path_exists == 0)); then
    uk_error "None of the given paths exist: ${MC_PATHS[*]}"
    return 1
  fi

  # Collect files into an array
  mapfile -t files < <(mc_collect)
  if ((${#files[@]} == 0)); then
    uk_error "No matching files found in the provided paths. Check extensions and that the path contains supported files."
    return 1
  fi

  # Check required tools before proceeding
  mc_require_tool || exit 1

  uk_section_title "$MC_KIND -> $MC_TO | output: $MC_OUTPUT | ${#files[@]} file(s) found"

  for file in "${files[@]}"; do
    mc_convert_one "$file"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  mc_main "$@"
fi

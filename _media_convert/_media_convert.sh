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
mc_convert_one() {
  local src="$1" base out
  base="$(basename "${src%.*}")"
  out="$MC_OUTPUT/${base}.${MC_TO}"
  if ((MC_APPLY == 0)); then
    printf '  %s%s→%s %s%s%s  %s->%s  %s%s%s\n' \
      "$UK_C_DIM" "" "$UK_C_RESET" \
      "$UK_C_CYAN" "$src" "$UK_C_RESET" \
      "$UK_C_DIM" "$UK_C_RESET" \
      "$UK_C_GREEN" "$out" "$UK_C_RESET"
    return 0
  fi
  mkdir -p "$MC_OUTPUT"
  printf '  %sConverting:%s %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$src" "$UK_C_RESET"
  if [[ "$MC_KIND" == 'image' ]]; then
    local method='ffmpeg'
    if uk_has_cmd magick; then
      method="magick (quality: $MC_QUALITY$((MC_STRIP_EXIF == 1)) && printf ', EXIF stripped' || true)"
      if ((MC_STRIP_EXIF == 1)); then
        magick "$src" -strip -quality "$MC_QUALITY" "$out"
      else
        magick "$src" -quality "$MC_QUALITY" "$out"
      fi
    else
      ffmpeg -y -i "$src" -qscale:v 3 "$out" >/dev/null 2>&1
    fi
  else
    printf '  %s(using ffmpeg libx264 crf=26)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    ffmpeg -y -i "$src" -vcodec libx264 -crf 26 -preset medium -movflags +faststart "$out" >/dev/null 2>&1
  fi
  uk_success "Created: $out"
}
mc_main() {
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
  if ((${#MC_PATHS[@]} == 0)) && [[ -t 0 && -t 1 ]]; then
    uk_header 'UtilityKit Media Convert' 'Batch image and video conversion'

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

  MC_OUTPUT=${MC_OUTPUT:-"$(pwd)/converted_${MC_KIND}"}
  mc_require_tool
  uk_header 'UtilityKit Media Convert' "$MC_KIND -> $MC_TO | output: $MC_OUTPUT"
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    mc_convert_one "$file"
  done < <(mc_collect)
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  mc_main "$@"
fi

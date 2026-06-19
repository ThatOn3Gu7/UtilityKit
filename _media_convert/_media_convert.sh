#!/usr/bin/env bash
set -euo pipefail
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
      uk_has_cmd magick || uk_has_cmd ffmpeg || { uk_error 'Need ImageMagick (magick) or ffmpeg for image conversion.'; return 1; }
      ;;
    video)
      uk_has_cmd ffmpeg || { uk_error 'ffmpeg is required for video conversion.'; return 1; }
      ;;
  esac
}

mc_convert_one() {
  local src="$1" base out
  base="$(basename "${src%.*}")"
  out="$MC_OUTPUT/${base}.${MC_TO}"
  if (( MC_APPLY == 0 )); then
    uk_note "Would convert $src -> $out"
    return 0
  fi
  mkdir -p "$MC_OUTPUT"
  if [[ "$MC_KIND" == 'image' ]]; then
    if uk_has_cmd magick; then
      if (( MC_STRIP_EXIF == 1 )); then
        magick "$src" -strip -quality "$MC_QUALITY" "$out"
      else
        magick "$src" -quality "$MC_QUALITY" "$out"
      fi
    else
      ffmpeg -y -i "$src" -qscale:v 3 "$out" >/dev/null 2>&1
    fi
  else
    ffmpeg -y -i "$src" -vcodec libx264 -crf 26 -preset medium -movflags +faststart "$out" >/dev/null 2>&1
  fi
  uk_success "Created $out"
}

mc_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kind) shift; MC_KIND="${1:-image}" ;;
      --to) shift; MC_TO="${1:-webp}" ;;
      --quality) shift; MC_QUALITY="${1:-82}" ;;
      --strip-exif) MC_STRIP_EXIF=1 ;;
      --output) shift; MC_OUTPUT="${1:-}" ;;
      --apply) MC_APPLY=1 ;;
      -h|--help) mc_usage; return 0 ;;
      *) MC_PATHS+=("$1") ;;
    esac
    shift
  done
  (( ${#MC_PATHS[@]} > 0 )) || { mc_usage; return 1; }
  MC_OUTPUT=${MC_OUTPUT:-"$(pwd)/converted_${MC_KIND}"}
  mc_require_tool
  uk_header 'UtilityKit Media Convert' "$MC_KIND -> $MC_TO | output: $MC_OUTPUT"
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    mc_convert_one "$file"
  done < <(mc_collect)
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  mc_main "$@"
fi

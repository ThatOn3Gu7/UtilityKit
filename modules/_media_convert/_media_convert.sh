#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

MC_KIND='image'
MC_TO='webp'
MC_QUALITY=82
MC_APPLY=0
MC_STRIP_EXIF=0
MC_OUTPUT=''
declare -a MC_PATHS=()

mc_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage: _media_convert.sh --kind image|video --to webp|jpg|png|mp4 [--quality 82] [--strip-exif] [--output DIR] [--apply] PATH...\n\n'
  uk_help_section "$w" "Options" \
    "--kind" "Conversion type: image or video" \
    "--to" "Target format (webp, jpg, png, mp4, etc.)" \
    "--quality" "Output quality 1-100 (default: 82)" \
    "--strip-exif" "Remove EXIF metadata from images" \
    "--output DIR" "Output directory for converted files" \
    "--apply" "Actually write output (dry-run without this)" \
    "-h, --help" "Show this help"
}

mc_collect() {
  local p
  for p in "${MC_PATHS[@]}"; do
    if [[ -d "$p" ]]; then
      case "$MC_KIND" in
      image) find "$p" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0 || return 1 ;;
      video) find "$p" -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.mkv' -o -iname '*.avi' \) -print0 || return 1 ;;
      esac
    elif [[ -f "$p" ]]; then
      printf '%s\0' "$p" || return 1
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
  local src="${1:-}" base out
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

  mkdir -p "$MC_OUTPUT" || { uk_error "Unable to create output directory: $MC_OUTPUT"; return 1; }
  printf '  %sConverting:%s %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$src" "$UK_C_RESET"

  local error_log
  error_log="$(mktemp)" || { uk_error 'Unable to create conversion error log.'; return 1; }
  if [[ "$MC_KIND" == 'image' ]]; then
    if uk_has_cmd magick; then
      if ((MC_STRIP_EXIF == 1)); then
        magick "$src" -strip -quality "$MC_QUALITY" "$out" >/dev/null 2>"$error_log" &
      else
        magick "$src" -quality "$MC_QUALITY" "$out" >/dev/null 2>"$error_log" &
      fi
    else
      ffmpeg -y -i "$src" -qscale:v 3 "$out" >/dev/null 2>"$error_log" &
    fi
  else
    printf '  %s(using ffmpeg libx264 crf=26)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    ffmpeg -y -i "$src" -vcodec libx264 -crf 26 -preset medium -movflags +faststart "$out" >/dev/null 2>"$error_log" &
  fi

  local _mc_bg=$! convert_status=0
  # Canonical indeterminate bar (uk_common); waits silently on non-tty stdout.
  uk_fake_progress "$_mc_bg" 'converting...' 'done.' || convert_status=$?

  if ((convert_status != 0)); then
    [[ -s "$error_log" ]] && cat "$error_log" >&2
    rm -f "$error_log" || uk_warn "Unable to remove conversion error log: $error_log"
    uk_error "Conversion failed (exit $convert_status): $src"
    return "$convert_status"
  fi
  rm -f "$error_log" || { uk_error "Unable to remove conversion error log: $error_log"; return 1; }
  if [[ -s "$out" ]]; then
    uk_success "Created: $out"
  else
    uk_error "Conversion produced no output: $out"
    return 1
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
    case "${1:-}" in
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
    *) MC_PATHS+=("${1:-}") ;;
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
  [[ "$MC_KIND" == image || "$MC_KIND" == video ]] || { uk_error "--kind must be image or video."; return 1; }
  [[ "$MC_TO" =~ ^[A-Za-z0-9]+$ ]] || { uk_error "Invalid target format: $MC_TO"; return 1; }
  [[ "$MC_QUALITY" =~ ^[0-9]+$ ]] && ((MC_QUALITY >= 1 && MC_QUALITY <= 100)) || { uk_error "--quality must be in 1..100."; return 1; }

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

  # Collect files into an array using NUL-delimited paths.
  local collect_file
  collect_file="$(mktemp)" || { uk_error 'Unable to create media scan file.'; return 1; }
  if ! mc_collect >"$collect_file"; then
    rm -f "$collect_file" || uk_warn "Unable to remove failed media scan file."
    uk_error 'Media traversal failed; refusing a partial conversion list.'
    return 1
  fi
  local files=() file
  mapfile -d '' files <"$collect_file" || { rm -f "$collect_file"; return 1; }
  rm -f "$collect_file" || { uk_error 'Unable to remove media scan file.'; return 1; }
  if ((${#files[@]} == 0)); then
    uk_error "No matching files found in the provided paths. Check extensions and that the path contains supported files."
    return 1
  fi

  # Check required tools before proceeding
  mc_require_tool || return 1

  uk_section_title "$MC_KIND -> $MC_TO | output: $MC_OUTPUT | ${#files[@]} file(s) found"

  for file in "${files[@]}"; do
    mc_convert_one "$file" || return $?
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  mc_main "$@"
fi

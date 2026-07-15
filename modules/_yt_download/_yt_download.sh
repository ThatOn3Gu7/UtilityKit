#!/usr/bin/env bash
# _yt_download — YouTube video/audio downloader with interactive menu (yt-dlp wrapper)
# Prefix: yd_

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback functions (standalone use) ---
if ! declare -f uk_has_cmd >/dev/null 2>&1; then uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "\033[31m[ERR]\033[0m %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn >/dev/null 2>&1; then uk_warn() { printf "\033[33m[WRN]\033[0m %s\n" "$*" >&2; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "\033[32m[OK]\033[0m %s\n" "$*"; }; fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local prompt="${1:-Continue?}" default="${2:-N}" reply
    printf "  %s [%s]: " "$prompt" "$([[ "$default" =~ ^[Yy] ]] && echo 'Y/n' || echo 'y/N')" >&2
    read -r reply
    [[ -z "$reply" ]] && reply="$default"
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_prompt >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply
    printf "  %s" "$label" >&2
    [[ -n "$default" ]] && printf " [default: %s]" "$default" >&2
    printf ": " >&2
    read -r reply
    printf "%s\n" "${reply:-$default}"
  }
fi
if ! declare -f uk_section_title >/dev/null 2>&1; then
  uk_section_title() { printf "\n--- %s ---\n" "$1"; }
fi
if ! declare -f uk_banner >/dev/null 2>&1; then
  uk_banner() { printf "\n=== %s ===\n" "$2"; }
fi
if ! declare -f uk_info >/dev/null 2>&1; then uk_info() { printf "\033[36m[i]\033[0m %s\n" "$*"; }; fi
if ! declare -f uk_note >/dev/null 2>&1; then uk_note() { printf "\033[34m[i]\033[0m %s\n" "$*"; }; fi

: "${UK_I_ARROW:=>}" "${UK_C_RED:=}" "${UK_C_GREEN:=}" "${UK_C_YELLOW:=}" "${UK_C_BLUE:=}" "${UK_C_CYAN:=}" "${UK_C_MAGENTA:=}" "${UK_C_DIM:=}" "${UK_C_BOLD:=}" "${UK_C_RESET:=}" "${UK_C_BRIGHT_CYAN:=}" "${UK_C_BRIGHT_BLUE:=}" "${UK_C_BRIGHT_MAGENTA:=}" "${UK_C_WHITE:=}"
YD_DEFAULT_DIR="${HOME}/Downloads/YouTube"

# Help / Usage
yd_usage() {
  cat <<'USAGE'
Usage:
  ytdl                              Interactive download wizard
  ytdl <URL>                        Wizard with a specific URL
  ytdl list <URL>                   List all available formats
  ytdl info <URL>                   Show video metadata
  ytdl audio <URL>                  Download best audio (default mp3)
  ytdl download <URL> [options]     Download with custom options

Subcommands:
  list      Show all available formats for a video
  info      Display title, duration, channel, views
  audio     Quick audio extraction
  download  Full download with options

Options (download subcommand):
  --format CODE       Format specifier (e.g. "137+140", "best", "bv*+ba/b")
  --audio-only        Extract audio stream only
  --audio-format FMT  Output audio format: mp3, m4a, opus, flac, aac
  --subs              Embed available subtitles
  --no-thumb          Skip embedding thumbnail
  --no-meta           Skip embedding metadata
  --playlist          Download all playlist items
  --output DIR        Custom output directory
  -h, --help          Show this help

Examples:
  ytdl https://youtube.com/watch?v=dQw4w9WgXcQ
  ytdl list https://youtube.com/watch?v=dQw4w9WgXcQ
  ytdl download https://youtube.com/watch?v=dQw4w9WgXcQ --format 137+140 --subs
  ytdl audio https://youtube.com/watch?v=dQw4w9WgXcQ --audio-format opus
USAGE
}

yd_dl_usage() {
  cat <<'USAGE'
Usage: ytdl download <URL> [options]

Options:
  --format CODE       Format specifier (e.g. "137+140", "best", "bv*+ba/b")
  --audio-only        Extract audio stream only
  --audio-format FMT  Output audio format: mp3, m4a, opus, flac, aac
  --subs              Embed available subtitles
  --no-thumb          Skip embedding thumbnail
  --no-meta           Skip embedding metadata
  --playlist          Download all playlist items
  --output DIR        Custom output directory
  -h, --help          Show this help
USAGE
}

# Helpers
yd_check_deps() {
  if ! uk_has_cmd yt-dlp; then
    uk_error "yt-dlp is not installed."
    uk_info "Install it with one of:"
    uk_info "  pip install yt-dlp"
    uk_info "  brew install yt-dlp (macOS)"
    uk_info "  sudo apt install yt-dlp (Linux)"
    return 1
  fi
}

yd_yesno() {
  local val="${1:-}"
  if [[ "$val" =~ ^[Yy1] ]]; then
    printf "Yes"
  else
    printf "No"
  fi
}

yd_spinner() {
  local label="$1" tmpfile pid rc spin i
  shift
  tmpfile=$(mktemp "${TMPDIR:-/tmp}/ytdl.XXXXXX")
  "$@" >"$tmpfile" 2>&1 &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r%s %c" "$label" "${spin:$i:1}" >&2
    i=$(((i + 1) % 4))
    sleep 0.12
  done
  wait "$pid" 2>/dev/null
  rc=$?
  printf "\r%*s\r" 60 "" >&2
  cat "$tmpfile"
  rm -f "$tmpfile"
  return $rc
}

# CLI Subcommands
yd_list() {
  local url="${1:-}"
  if [[ -z "$url" ]]; then
    uk_error "Usage: ytdl list <URL>"
    return 1
  fi
  yd_check_deps || return 1
  uk_section_title "Available formats for: $url"
  yt-dlp -F -- "$url"
}

yd_info() {
  local url="${1:-}"
  if [[ -z "$url" ]]; then
    uk_error "Usage: ytdl info <URL>"
    return 1
  fi
  yd_check_deps || return 1

  local title duration upload_date views likes channel metadata yd_err
  # One tab-delimited --print template keeps stdout as pure data; stderr is
  # captured separately so WARNING/ERROR lines can never shift the field
  # mapping the way they did when stderr was folded into the output.
  yd_err="$(mktemp)" || return 1
  if ! metadata="$(yt-dlp --print '%(title)s\t%(duration_string)s\t%(upload_date)s\t%(view_count)s\t%(like_count)s\t%(channel)s' -- "$url" 2>"$yd_err")"; then
    uk_error "Unable to fetch video metadata: $(cat "$yd_err")"
    rm -f "$yd_err"
    return 1
  fi
  rm -f "$yd_err"
  IFS=$'\t' read -r title duration upload_date views likes channel <<<"$metadata"
  title="${title:-N/A}"
  views="${views:-N/A}"
  likes="${likes:-N/A}"
  channel="${channel:-N/A}"

  uk_section_title "Video Info"
  printf "  Title:      %s\n" "$title"
  printf "  Channel:    %s\n" "$channel"
  [[ -n "$duration" ]] && printf "  Duration:   %s\n" "$duration"
  [[ -n "$upload_date" ]] && printf "  Uploaded:   %s\n" "$upload_date"
  printf "  Views:      %s\n" "$views"
  printf "  Likes:      %s\n" "$likes"
}

yd_audio() {
  local url="" audio_fmt="mp3"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --audio-format)
      audio_fmt="${2:-mp3}"
      shift 2 2>/dev/null || break
      ;;
    -h | --help)
      yd_usage
      return 0
      ;;
    --*)
      shift
      ;;
    *)
      url="$1"
      shift
      ;;
    esac
  done

  if [[ -z "$url" ]]; then
    uk_error "Usage: ytdl audio <URL> [--audio-format FMT]"
    return 1
  fi
  yd_check_deps || return 1

  mkdir -p "$YD_DEFAULT_DIR"
  uk_section_title "Downloading audio as $audio_fmt..."
  echo ""
  yt-dlp -x --audio-format "$audio_fmt" \
    --embed-thumbnail \
    --embed-metadata \
    -o "${YD_DEFAULT_DIR}/%(title)s.%(ext)s" \
    -- "$url"
}

yd_download() {
  local url="" format="bv*+ba/b" audio_only=0 audio_fmt="mp3"
  local subs=0 no_thumb=0 no_meta=0 playlist=0 output="$YD_DEFAULT_DIR"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --format)
      format="${2:-bv*+ba/b}"
      shift 2 2>/dev/null || break
      ;;
    --audio-only)
      audio_only=1
      shift
      ;;
    --audio-format)
      audio_fmt="${2:-mp3}"
      shift 2 2>/dev/null || break
      ;;
    --subs)
      subs=1
      shift
      ;;
    --no-thumb)
      no_thumb=1
      shift
      ;;
    --no-meta)
      no_meta=1
      shift
      ;;
    --playlist)
      playlist=1
      shift
      ;;
    --output)
      output="${2:-$YD_DEFAULT_DIR}"
      shift 2 2>/dev/null || break
      ;;
    -h | --help)
      yd_dl_usage
      return 0
      ;;
    *)
      url="$1"
      shift
      ;;
    esac
  done

  if [[ -z "$url" ]]; then
    uk_error "Usage: ytdl download <URL> [options]"
    yd_dl_usage
    return 1
  fi
  yd_check_deps || return 1

  output="${output/#\~/$HOME}"
  mkdir -p "$output"

  local -a cmd=(yt-dlp)

  if ((audio_only)); then
    cmd+=(-x --audio-format "$audio_fmt")
  fi

  cmd+=(-f "$format")

  if ((subs)); then
    cmd+=(--embed-subs --sub-langs all)
  fi

  if ((no_thumb)); then
    cmd+=(--no-embed-thumbnail)
  else
    cmd+=(--embed-thumbnail)
  fi

  if ((no_meta)); then
    cmd+=(--no-embed-metadata)
  else
    cmd+=(--embed-metadata)
  fi

  if ((playlist)); then
    cmd+=(--yes-playlist)
  else
    cmd+=(--no-playlist)
  fi

  cmd+=(-o "${output}/%(title)s.%(ext)s")
  cmd+=(-- "$url")

  uk_section_title "Downloading..."
  uk_info "Command: ${cmd[*]}"
  echo ""
  "${cmd[@]}"
  local ret=$?
  ((ret == 0)) && uk_success "Download complete!" || uk_error "Download failed (exit code $ret)"
  return $ret
}

# Interactive Wizard
yd_wizard() {
  local url="${1:-}"

  yd_check_deps || return 1

  uk_banner "YT Download" "YouTube Downloader (yt-dlp)"
  printf '  Download videos, audio, playlists, and more with yt-dlp\n'

  # --- URL ---
  echo ""
  if [[ -z "$url" ]]; then
    url=$(uk_prompt "Paste video/playlist URL" "" \
      "https://youtube.com/watch?v=..." \
      "Supports YouTube, YouTube Music, and many other sites")
  fi
  if [[ -z "$url" ]]; then
    uk_warn "No URL provided."
    return 1
  fi

  # --- Fetch video info ---
  echo ""
  uk_info "Fetching video information..."
  local title duration channel raw_info
  raw_info=$(yd_spinner "Please wait" yt-dlp --print title --print duration_string --print channel -- "$url") || { uk_error 'Failed to fetch video information.'; return 1; }
  if [[ -n "$raw_info" ]]; then
    title=$(echo "$raw_info" | sed -n '1p')
    duration=$(echo "$raw_info" | sed -n '2p')
    channel=$(echo "$raw_info" | sed -n '3p')
  fi
  : "${title:=N/A}" "${channel:=N/A}" "${duration:=}"

  echo ""
  uk_section_title "Video"
  printf "  Title:   %s\n" "$title"
  printf "  Channel: %s\n" "$channel"
  [[ -n "$duration" ]] && printf "  Length:  %s\n" "$duration"

  # --- List formats ---
  echo ""
  uk_section_title "Available Formats"
  echo ""
  local formats_raw
  formats_raw=$(yd_spinner "Fetching formats" yt-dlp -F -- "$url") || { uk_error 'Failed to fetch formats.'; return 1; }
  if [[ -z "$formats_raw" ]]; then
    uk_error "Failed to fetch formats."
    return 1
  fi
  printf '%s\n' "$formats_raw" | sed 's/^/  /'
  echo ""

  # --- Format selection ---
  uk_info "Enter one or more format codes from the table above."
  uk_info "Common patterns:"
  printf "  %s  bv*+ba/b    (default) Best video + best audio, fallback to combined\n" "$UK_I_ARROW"
  printf "  %s  137+140      Video codec + audio codec (yt-dlp merges them)\n" "$UK_I_ARROW"
  printf "  %s  bestvideo+bestaudio  Explicit best of each, will merge\n" "$UK_I_ARROW"
  printf "  %s  best         Best single-file combined stream\n" "$UK_I_ARROW"
  echo ""

  local format
  format=$(uk_prompt "Format code(s)" "bv*+ba/b" "137+140" "Enter codes space-separated if you want multiple (e.g. 137+140)")

  # --- Audio only ---
  echo ""
  local audio_only=0
  if uk_confirm "Extract audio only?" "N"; then
    audio_only=1
  fi

  local audio_fmt="mp3"
  if ((audio_only)); then
    echo ""
    uk_info "Audio format options:"
    printf "  1) mp3   – Universal, good compatibility\n"
    printf "  2) m4a   – AAC, good quality\n"
    printf "  3) opus  – Best quality, smallest size\n"
    printf "  4) flac  – Lossless (large files)\n"
    printf "  5) aac   – Raw AAC\n"
    echo ""
    local afmt_choice
    afmt_choice=$(uk_prompt "Choose audio format [1-5]" "1" "1" "")
    case "$afmt_choice" in
    2 | m4a) audio_fmt="m4a" ;;
    3 | opus) audio_fmt="opus" ;;
    4 | flac) audio_fmt="flac" ;;
    5 | aac) audio_fmt="aac" ;;
    *) audio_fmt="mp3" ;;
    esac
  fi

  # --- Subs ---
  echo ""
  local subs=0
  if uk_confirm "Download and embed subtitles?" "Y"; then
    subs=1
  fi

  # --- Thumbnail ---
  local no_thumb=0
  if ! uk_confirm "Embed thumbnail?" "Y"; then
    no_thumb=1
  fi

  # --- Metadata ---
  local no_meta=0
  if ! uk_confirm "Embed metadata (title, uploader, etc.)?" "Y"; then
    no_meta=1
  fi

  # --- Playlist ---
  echo ""
  local playlist=0
  if uk_confirm "Download as playlist (if URL is a playlist)?" "N"; then
    playlist=1
  fi

  # --- Output directory ---
  local output
  output=$(uk_prompt "Output directory" "$YD_DEFAULT_DIR" \
    "~/Downloads/YouTube" \
    "Will be created if it does not exist")
  output="${output/#\~/$HOME}"

  # --- Filename template ---
  local template
  template=$(uk_prompt "Filename template" "%(title)s.%(ext)s" \
    "%(title)s [%(id)s].%(ext)s" \
    "See yt-dlp output template docs for variables")

  # Summary & Confirm
  echo ""

  local yn_audio yn_subs yn_thumb yn_meta yn_playlist
  if ((audio_only)); then yn_audio="Yes (${audio_fmt})"; else yn_audio="No"; fi
  if ((subs)); then yn_subs="Yes"; else yn_subs="No"; fi
  if ((no_thumb)); then yn_thumb="No"; else yn_thumb="Yes"; fi
  if ((no_meta)); then yn_meta="No"; else yn_meta="Yes"; fi
  if ((playlist)); then yn_playlist="Yes"; else yn_playlist="No (single video)"; fi

  uk_section_title "Download Summary"
  printf "  %-18s %s\n" "URL:" "$url"
  printf "  %-18s %s\n" "Title:" "${title:-N/A}"
  printf "  %-18s %s\n" "Format:" "$format"
  printf "  %-18s %s\n" "Audio only:" "$yn_audio"
  printf "  %-18s %s\n" "Subtitles:" "$yn_subs"
  printf "  %-18s %s\n" "Thumbnail:" "$yn_thumb"
  printf "  %-18s %s\n" "Metadata:" "$yn_meta"
  printf "  %-18s %s\n" "Playlist:" "$yn_playlist"
  printf "  %-18s %s\n" "Output:" "$output"
  printf "  %-18s %s\n" "Template:" "$template"
  echo ""

  if ! uk_confirm "Proceed with download?" "Y"; then
    uk_info "Download cancelled."
    return 0
  fi

  # --- Execute ---
  mkdir -p "$output"

  local -a cmd=(yt-dlp)

  if ((audio_only)); then
    cmd+=(-x --audio-format "$audio_fmt")
  fi

  cmd+=(-f "$format")

  if ((subs)); then
    cmd+=(--embed-subs --sub-langs all)
  fi

  if ((no_thumb)); then
    cmd+=(--no-embed-thumbnail)
  else
    cmd+=(--embed-thumbnail)
  fi

  if ((no_meta)); then
    cmd+=(--no-embed-metadata)
  else
    cmd+=(--embed-metadata)
  fi

  if ((playlist)); then
    cmd+=(--yes-playlist)
  else
    cmd+=(--no-playlist)
  fi

  cmd+=(-o "${output}/${template}")
  cmd+=(-- "$url")

  echo ""
  uk_section_title "Downloading..."
  uk_info "Running: yt-dlp ${cmd[*]:1}"
  echo ""
  "${cmd[@]}"
  local ret=$?
  echo ""
  ((ret == 0)) && uk_success "Download complete!" || uk_error "Download failed (exit code $ret)"
  return $ret
}

# Entry Point
yd_main() {
  if [[ $# -eq 0 ]]; then
    yd_wizard ""
    return $?
  fi

  local first="${1:-}"

  case "$first" in
  list | ls)
    shift
    yd_list "$@"
    ;;
  info | metadata)
    shift
    yd_info "$@"
    ;;
  audio | mp3)
    shift
    yd_audio "$@"
    ;;
  download | dl)
    shift
    yd_download "$@"
    ;;
  -h | --help)
    yd_usage
    return 0
    ;;
  *)
    # If it looks like a URL, launch the wizard with it
    if [[ "$first" =~ ^https?:// || "$first" =~ ^www\. || "$first" =~ ^youtu\. ]]; then
      yd_wizard "$first"
    else
      uk_error "Unknown subcommand: $first"
      yd_usage
      return 1
    fi
    ;;
  esac
}

# BASH_SOURCE guard (standalone execution)
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  # set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    yd_wizard ""
  else
    yd_main "$@"
  fi
fi

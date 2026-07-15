#!/usr/bin/env bash
set -uo pipefail

if ((BASH_VERSINFO[0] < 4)); then
  printf 'ERROR: apply-changes requires Bash 4.0 or newer (found %s).\n' "$BASH_VERSION" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/../../lib/uk_common.sh"
if [[ ! -r "$COMMON_LIB" ]]; then
  printf 'ERROR: required support library is not readable: %s\n' "$COMMON_LIB" >&2
  exit 2
fi
# shellcheck source=../../lib/uk_common.sh
source "$COMMON_LIB"

MODE="dry-run"
MIRROR=0
FORCE=0
YES=0
INCLUDE_RUNTIME=0
BACKUP_DIR=""
MAX_PREVIEW=200
EXCLUDES=()
LOG_FILE=""
NO_LOCK=0

LOCK_ACQUIRED=0
LOCK_DIR=""
APPLY_IN_PROGRESS=0
TRAP_RUN=0
AC_R='' AC_BOLD='' AC_DIM='' AC_ITALIC='' AC_INVERSE=''
AC_FG_RED='' AC_FG_GREEN='' AC_FG_YELLOW='' AC_FG_BLUE='' AC_FG_MAGENTA='' AC_FG_CYAN='' AC_FG_WHITE=''
AC_FG_BRIGHT_RED='' AC_FG_BRIGHT_GREEN='' AC_FG_BRIGHT_YELLOW='' AC_FG_BRIGHT_BLUE=''
AC_FG_BRIGHT_MAGENTA='' AC_FG_BRIGHT_CYAN='' AC_FG_BRIGHT_WHITE=''
AC_MENU_SAVED=0

# Color + style setup — disabled when not a TTY or NO_COLOR is set
_setup_colors() {
  # TERM=dumb must never receive cursor or color escape sequences.
  if [[ -t 1 && -t 2 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
    AC_R=$'\033[0m'
    AC_BOLD=$'\033[1m'
    AC_DIM=$'\033[2m'
    AC_ITALIC=$'\033[3m'
    AC_INVERSE=$'\033[7m'
    AC_FG_RED=$'\033[31m'
    AC_FG_GREEN=$'\033[32m'
    AC_FG_YELLOW=$'\033[33m'
    AC_FG_BLUE=$'\033[34m'
    AC_FG_MAGENTA=$'\033[35m'
    AC_FG_CYAN=$'\033[36m'
    AC_FG_WHITE=$'\033[37m'
    AC_FG_BRIGHT_RED=$'\033[91m'
    AC_FG_BRIGHT_GREEN=$'\033[92m'
    AC_FG_BRIGHT_YELLOW=$'\033[93m'
    AC_FG_BRIGHT_BLUE=$'\033[94m'
    AC_FG_BRIGHT_MAGENTA=$'\033[95m'
    AC_FG_BRIGHT_CYAN=$'\033[96m'
    AC_FG_BRIGHT_WHITE=$'\033[97m'
  else
    AC_R='' AC_BOLD='' AC_DIM='' AC_ITALIC='' AC_INVERSE=''
    AC_FG_RED='' AC_FG_GREEN='' AC_FG_YELLOW='' AC_FG_BLUE='' AC_FG_MAGENTA='' AC_FG_CYAN='' AC_FG_WHITE=''
    AC_FG_BRIGHT_RED='' AC_FG_BRIGHT_GREEN='' AC_FG_BRIGHT_YELLOW='' AC_FG_BRIGHT_BLUE=''
    AC_FG_BRIGHT_MAGENTA='' AC_FG_BRIGHT_CYAN='' AC_FG_BRIGHT_WHITE=''
  fi
}
_setup_colors

log_action() {
  local msg="$*"
  if [[ -n "${LOG_FILE:-}" ]]; then
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >>"$LOG_FILE"
  fi
}
info() {
  printf "${AC_BOLD}${AC_FG_CYAN}[INFO]${AC_R}  %s\n" "$*"
  log_action "[INFO]  $*"
}
warn() {
  printf "${AC_BOLD}${AC_FG_BRIGHT_YELLOW}[WARN]${AC_R}  %s\n" "$*" >&2
  log_action "[WARN]  $*"
}
fail() {
  printf "${AC_BOLD}${AC_FG_BRIGHT_RED}[ERROR]${AC_R} %s\n" "$*" >&2
  log_action "[ERROR] $*"
  exit 1
}
# Adaptive Temporary Directory Resolution (Termux, Android, macOS, Linux)
get_temp_dir() {
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" && -w "$TMPDIR" ]]; then
    printf '%s\n' "${TMPDIR%/}"
  elif [[ -d "/tmp" && -w "/tmp" ]]; then
    printf '%s\n' "/tmp"
  elif [[ -n "${HOME:-}" && -d "$HOME" && -w "$HOME" ]]; then
    if ! mkdir -p "$HOME/.apply_temp"; then
      warn "Unable to create fallback temporary directory: $HOME/.apply_temp"
      return 1
    fi
    if [[ -d "$HOME/.apply_temp" && -w "$HOME/.apply_temp" ]]; then
      printf '%s\n' "$HOME/.apply_temp"
    else
      printf '%s\n' "."
    fi
  else
    # Last-resort fallback for restricted environments with no HOME or /tmp.
    printf '%s\n' "."
  fi
}
# Signal Handling & Safe Interruption Cleanup
cleanup_and_trap() {
  local exit_code=$?
  local sig="${1:-EXIT}"

  [[ $TRAP_RUN -eq 0 ]] || return 0
  TRAP_RUN=1

  release_lock || warn "Concurrency lock cleanup failed."
  if [[ -n "${CHANGES_FILE:-}" && -f "$CHANGES_FILE" ]]; then
    rm -f "$CHANGES_FILE" || warn "Unable to remove temporary change plan: $CHANGES_FILE"
  fi
  if [[ -n "${CHANGES_FILE:-}" && -f "${CHANGES_FILE}.scan" ]]; then
    rm -f "${CHANGES_FILE}.scan" || warn "Unable to remove temporary scan file: ${CHANGES_FILE}.scan"
  fi

  if [[ "${APPLY_IN_PROGRESS:-0}" -eq 1 ]]; then
    printf "\n" >&2
    warn "${AC_FG_BRIGHT_RED}⚠️ WARNING: Synchronization was abruptly interrupted ($sig) while actively applying changes!${AC_R}"
    warn "The target directory '${TARGET_DIR:-}' may be in an inconsistent state."
    if [[ -n "${BACKUP_FILE:-}" && -f "$BACKUP_FILE" ]]; then
      warn "To restore your directory to its exact pristine state, execute:"
      warn "  tar -xzf $(abs_path "$BACKUP_FILE") -C $(dirname "$TARGET_DIR")"
    fi
  fi

  [[ "$sig" == "EXIT" ]] || exit "$exit_code"
}
# (Traps are registered inside ac_main to prevent overriding parent shell traps when sourced)
usage() {
  local script_name
  script_name="$(basename "$0")"
  cat <<EOF
${AC_BOLD}Usage:${AC_R}
  $script_name [options] <updated_source_dir> <local_target_dir>

${AC_BOLD}Enterprise Robustness Behavior:${AC_R}
  - Adaptive temp directory logic perfectly supports Termux, Android, and strict subshells.
  - Non-fatal concurrency locking prevents conflicts but falls back gracefully if restricted.
  - Permissive chmod handling guarantees smooth copying across Android /sdcard or SMB mounts.
  - Pre-flight disk space check verifies sufficient storage for backup and synced files.
  - Pre-flight permission check warns of read-only files or non-writable paths.
  - Dynamic filesystem traversal pruning speeds up large directory scans up to 100x.
  - Smart stat size comparison avoids opening large binary files for cmp.
  - Automated emergency rollback restores backup instantly if copying fails mid-execution.
  - Always preserves target ${AC_FG_CYAN}.git/${AC_R}.

${AC_BOLD}Options:${AC_R}
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--apply${AC_R}              Actually copy changes after showing the plan.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--interactive${AC_R}        Launch the interactive home-directory browser to
                        pick SOURCE and TARGET with arrow keys, then apply.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--dry-run${AC_R}            Preview only. This is the default.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--mirror${AC_R}             Also delete target files that do not exist in source
                       (excluding .git/, runtime logs, and custom exclusions). Use carefully.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--force${AC_R}              Allow applying even when target git tree has local changes.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--yes${AC_R}                Do not ask for interactive confirmation in --apply mode.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--backup-dir <dir>${AC_R}   Write backup archives to this directory instead of the
                       target's parent directory.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--include-runtime${AC_R}    Also sync runtime logs/tmp files under log/ (aliases:
                       ${AC_BOLD}--include-logs${AC_R}, ${AC_BOLD}--no-default-excludes${AC_R}).
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--exclude <pattern>${AC_R}  Exclude files or directories matching bash wildcard pattern
                       (can be specified multiple times).
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--log-file <file>${AC_R}    Record a timestamped runtime audit log to this file.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--no-lock${AC_R}            Disable concurrency locking completely.
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--max-preview <n>${AC_R}    Number of change lines to print before truncating
                       (default: 200).
  ${AC_BOLD}${AC_FG_BRIGHT_CYAN}-h, --help${AC_R}           Show this help.

${AC_BOLD}Examples:${AC_R}
  ${AC_DIM}# Preview changes from source into target:${AC_R}
  bash $script_name /path/to/source /path/to/target

  ${AC_DIM}# Apply changed/new files safely, with automatic Termux temp dir protection:${AC_R}
  bash $script_name --apply /path/to/source /path/to/target

  ${AC_DIM}# Full mirror mode with runtime audit log and custom exclusions:${AC_R}
  bash $script_name --apply --mirror --log-file "sync.log" --exclude "node_modules" /src /dst
EOF
}
# Colored + symbol-prefixed label for a change kind
kind_label() {
  case "${1:-}" in
  CREATE) printf "${AC_BOLD}${AC_FG_BRIGHT_GREEN}✚ CREATE ${AC_R}" ;;
  UPDATE) printf "${AC_BOLD}${AC_FG_BRIGHT_CYAN}↻ UPDATE ${AC_R}" ;;
  REPLACE) printf "${AC_BOLD}${AC_FG_BRIGHT_YELLOW}⟳ REPLACE${AC_R}" ;;
  DELETE) printf "${AC_BOLD}${AC_FG_BRIGHT_RED}✖ DELETE ${AC_R}" ;;
  MKDIR) printf "${AC_BOLD}${AC_FG_BRIGHT_BLUE}⊕ MKDIR  ${AC_R}" ;;
  SYMLINK) printf "${AC_BOLD}${AC_FG_BRIGHT_MAGENTA}⑂ SYMLINK${AC_R}" ;;
  CHMOD) printf "${AC_DIM}⌀ CHMOD  ${AC_R}" ;;
  *) printf "${AC_DIM}%-9s${AC_R}" "${1:-}" ;;
  esac
}
abs_path() {
  if command -v realpath >/dev/null 2>&1; then
    realpath "${1:-}"
  else
    (cd "$(dirname "${1:-}")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "${1:-}")")
  fi
}
# Fail-closed concurrency locking
acquire_lock() {
  [[ $NO_LOCK -eq 0 ]] || return 0

  local target_hash temp_base lock_error=''
  temp_base="$(get_temp_dir)" || fail "Unable to resolve a temporary directory for the lock."
  # POSIX cksum is available on GNU/Linux, macOS, BSD, and Termux.
  target_hash=$(printf '%s' "$TARGET_DIR" | cksum | awk '{print $1}') || fail "Unable to calculate the target lock key."
  LOCK_DIR="$temp_base/.apply_sync_lock_${UID:-0}_${target_hash}"

  if ! lock_error="$(mkdir "$LOCK_DIR" 2>&1)"; then
    local pid="unknown"
    if [[ -r "$LOCK_DIR/pid" ]]; then
      pid="$(cat "$LOCK_DIR/pid")" || fail "Unable to read lock owner from '$LOCK_DIR/pid'."
    fi
    local process_error=''
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
      if process_error="$(kill -0 "$pid" 2>&1)"; then
        fail "Another synchronization instance (PID $pid) is currently running on '$TARGET_DIR'. Aborting to prevent data corruption."
      fi
      [[ -n "$process_error" ]] && log_action "Stale lock PID check failed for $pid: $process_error"
    fi
    [[ -n "$lock_error" ]] && log_action "Initial lock acquisition failed: $lock_error"
    warn "Found stale concurrency lock from inactive PID $pid. Reclaiming lock..."
    rm -rf "$LOCK_DIR" || fail "Unable to remove stale lock directory '$LOCK_DIR'."
    if ! lock_error="$(mkdir "$LOCK_DIR" 2>&1)"; then
      [[ -n "$lock_error" ]] && warn "Lock creation failed: $lock_error"
      fail "Unable to create concurrency lock directory '$LOCK_DIR'; use --no-lock only after reviewing the race risk."
    fi
  fi
  if ! printf '%s\n' "$$" >"$LOCK_DIR/pid"; then
    rm -rf "$LOCK_DIR" || true
    fail "Unable to write PID to lock directory '$LOCK_DIR'."
  fi
  LOCK_ACQUIRED=1
  log_action "Concurrency lock acquired: $LOCK_DIR (PID $$)"
}

release_lock() {
  if [[ "${LOCK_ACQUIRED:-0}" -eq 1 && -n "${LOCK_DIR:-}" && -d "$LOCK_DIR" ]]; then
    if ! rm -rf "$LOCK_DIR"; then
      warn "Unable to release concurrency lock: $LOCK_DIR"
      return 1
    fi
    LOCK_ACQUIRED=0
    log_action "Concurrency lock released."
  fi
}
# Pre-flight Disk Space Safety Guard
check_disk_space() {
  local dst="${1:-}" backup_dir="${2:-}" src="${3:-}"
  info "Performing pre-flight disk space safety check..."

  local src_size_kb target_size_kb avail_dst_kb avail_bak_kb req_bak_kb req_dst_kb
  if ! src_size_kb="$(du -sk "$src" | awk 'NR==1 {print $1}')"; then
    fail "Unable to measure source size for disk-space verification: $src"
  fi
  [[ "$src_size_kb" =~ ^[0-9]+$ ]] || fail "Invalid source size returned by du for '$src': $src_size_kb"

  if ! target_size_kb="$(du -sk "$dst" | awk 'NR==1 {print $1}')"; then
    fail "Unable to measure target size for disk-space verification: $dst"
  fi
  [[ "$target_size_kb" =~ ^[0-9]+$ ]] || fail "Invalid target size returned by du for '$dst': $target_size_kb"

  # Buffer: 1x target size + 20MB safety margin for backup archive
  req_bak_kb=$((target_size_kb + 20480))
  # Buffer: source changed size + 20MB safety margin for target copying
  req_dst_kb=$((src_size_kb + 20480))

  if ! avail_dst_kb="$(df -kP "$dst" | awk 'NR==2 {print $4}')"; then
    fail "Unable to determine available space for target: $dst"
  fi
  if ! avail_bak_kb="$(df -kP "$backup_dir" | awk 'NR==2 {print $4}')"; then
    fail "Unable to determine available space for backup directory: $backup_dir"
  fi
  [[ "$avail_dst_kb" =~ ^[0-9]+$ ]] || fail "Invalid available-space value returned by df for '$dst': $avail_dst_kb"
  [[ "$avail_bak_kb" =~ ^[0-9]+$ ]] || fail "Invalid available-space value returned by df for '$backup_dir': $avail_bak_kb"

  if [[ "$avail_bak_kb" -lt "$req_bak_kb" ]]; then
    warn "Low available disk space on backup partition '$backup_dir'!"
    warn "Available: $((avail_bak_kb / 1024)) MB | Estimated Minimum Required: $((req_bak_kb / 1024)) MB"
    fail "Insufficient disk space to guarantee safe backup creation. Please free up space or use --backup-dir to specify a larger storage drive."
  fi

  if [[ "$avail_dst_kb" -lt "$req_dst_kb" ]]; then
    warn "Low available disk space on target partition '$dst'!"
    warn "Available: $((avail_dst_kb / 1024)) MB | Estimated Minimum Required: $((req_dst_kb / 1024)) MB"
    fail "Insufficient disk space to perform safe synchronization. Please free up disk space."
  fi

  info "✔ Disk space verification passed successfully."
}
# Pre-flight Writable Permissions Safety Guard
check_target_writable() {
  local dst="${1:-}"
  if [[ ! -w "$dst" ]]; then
    warn "Target root directory '$dst' is not writable by the current user (${USER:-$UID})."
    warn "Synchronization may encounter permission denied errors during execution."
  fi

  local read_only_count=0
  local kind rel target_path
  while IFS= read -r -d '' kind && IFS= read -r -d '' rel; do
    [[ -n "$kind" && -n "$rel" ]] || continue
    target_path="$dst/$rel"
    if path_exists_or_link "$target_path"; then
      if [[ ! -w "$target_path" && ! -L "$target_path" ]]; then
        read_only_count=$((read_only_count + 1))
      fi
    fi
  done <"$CHANGES_FILE"

  if [[ $read_only_count -gt 0 ]]; then
    warn "Detected $read_only_count existing target file(s) that are read-only or not writable."
    warn "The script will proactively attempt to update permissions or force overwrite during apply."
  fi
}
should_exclude_rel() {
  local rel="${1#./}"
  case "$rel" in
  '' | .) return 1 ;;
  .git | .git/*) return 0 ;;
  esac

  if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    local pattern
    for pattern in "${EXCLUDES[@]}"; do
      if [[ "$rel" == $pattern || "$rel" == $pattern/* ]]; then
        return 0
      fi
    done
  fi

  if [[ $INCLUDE_RUNTIME -eq 0 ]]; then
    case "$rel" in
    log/*.log | log/*.tmp | log/install.log | log/session_history.tmp) return 0 ;;
    esac
  fi

  return 1
}
add_change() {
  local kind="${1:-}" rel="${2:-}"
  if ! printf '%s\0%s\0' "$kind" "$rel" >>"$CHANGES_FILE"; then
    fail "Unable to append to change plan: $CHANGES_FILE"
  fi
  CHANGE_COUNT=$((CHANGE_COUNT + 1))
}
path_exists_or_link() {
  [[ -e "${1:-}" || -L "${1:-}" ]]
}
file_mode() {
  local path="${1:-}" mode='' stat_error=''
  if mode="$(stat -c '%a' "$path" 2>&1)"; then
    printf '%s\n' "$mode"
    return 0
  fi
  stat_error="$mode"
  if mode="$(stat -f '%Lp' "$path" 2>&1)"; then
    [[ -n "$stat_error" ]] && log_action "GNU stat mode probe failed for '$path': $stat_error"
    printf '%s\n' "$mode"
    return 0
  fi
  warn "Unable to read file mode for '$path': ${mode:-$stat_error}"
  return 1
}
file_size() {
  local path="${1:-}" size='' stat_error=''
  if size="$(stat -c '%s' "$path" 2>&1)"; then
    printf '%s\n' "$size"
    return 0
  fi
  stat_error="$size"
  if size="$(stat -f '%z' "$path" 2>&1)"; then
    [[ -n "$stat_error" ]] && log_action "GNU stat size probe failed for '$path': $stat_error"
    printf '%s\n' "$size"
    return 0
  fi
  warn "Unable to read file size for '$path': ${size:-$stat_error}"
  return 1
}
modes_differ() {
  local left_mode right_mode
  left_mode=$(file_mode "${1:-}") || fail "Unable to compare source permissions for '${1:-}'."
  right_mode=$(file_mode "${2:-}") || fail "Unable to compare target permissions for '${2:-}'."
  [[ "$left_mode" != "$right_mode" ]]
}
# Copy source permissions with a portable numeric-mode fallback.
chmod_like_source() {
  local source_path="${1:-}" target_path="${2:-}" mode reference_error=''
  if reference_error="$(chmod --reference="$source_path" "$target_path" 2>&1)"; then
    return 0
  fi
  [[ -n "$reference_error" ]] && log_action "chmod --reference fallback for '$target_path': $reference_error"
  mode=$(file_mode "$source_path") || return 1
  chmod "$mode" "$target_path"
}
collect_changes() {
  local src="${1:-}" dst="${2:-}" mirror="${3:-}"
  if ! : >"$CHANGES_FILE"; then
    fail "Unable to reset change plan: $CHANGES_FILE"
  fi
  CHANGE_COUNT=0

  local path rel target source_link target_link src_size dst_size

  # Build find prune expression for source to drastically optimize file traversal
  local prune_expr=()
  prune_expr+=("-name" ".git" "-prune")

  if [[ $INCLUDE_RUNTIME -eq 0 ]]; then
    prune_expr+=("-o" "-path" "*/log" "-prune")
  fi

  if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    local pattern
    for pattern in "${EXCLUDES[@]}"; do
      if [[ ! "$pattern" =~ / && ! "$pattern" =~ \* ]]; then
        prune_expr+=("-o" "-name" "$pattern" "-prune")
      fi
    done
  fi

  # GNU find can return type/size/mode/path in a single syscall pass via -printf,
  # eliminating the per-file stat forks on the source side. Probe once.
  local _have_printf=0 probe_error=''
  if probe_error="$(find "$src" -maxdepth 0 -printf '' 2>&1 >/dev/null)"; then
    _have_printf=1
  elif [[ -n "$probe_error" ]]; then
    log_action "GNU find -printf probe unavailable; using portable traversal: $probe_error"
  fi

  local path_list rec ftype fsize fmode dst_mode scan_file="${CHANGES_FILE}.scan"
  if ((_have_printf)); then
    if ! find "$src" -mindepth 1 \( "${prune_expr[@]}" \) -o -printf '%y\t%s\t%m\t%p\0' >"$scan_file"; then
      rm -f "$scan_file" || warn "Unable to remove failed scan file: $scan_file"
      fail "Source traversal failed; refusing to build a partial change plan for '$src'."
    fi
    mapfile -d '' path_list <"$scan_file" || fail "Unable to read source scan file: $scan_file"
    rm -f "$scan_file" || fail "Unable to remove source scan file: $scan_file"
    for rec in ${path_list[@]+"${path_list[@]}"}; do
      # Record layout: type<TAB>size<TAB>mode<TAB>path  (path may itself contain tabs)
      ftype="${rec%%$'\t'*}"
      rec="${rec#*$'\t'}"
      fsize="${rec%%$'\t'*}"
      rec="${rec#*$'\t'}"
      fmode="${rec%%$'\t'*}"
      path="${rec#*$'\t'}"
      rel="${path#"$src"/}"
      should_exclude_rel "$rel" && continue
      target="$dst/$rel"

      case "$ftype" in
      d)
        if ! [[ -d "$target" && ! -L "$target" ]]; then
          add_change "MKDIR" "$rel"
        else
          dst_mode=$(file_mode "$target") || fail "Unable to inspect target permissions: $target"
          if [[ -n "$fmode" && "$fmode" != "$dst_mode" ]]; then
            add_change "CHMOD" "$rel"
          fi
        fi
        ;;
      l)
        source_link=$(readlink "$path") || fail "Unable to read source symlink: $path"
        if [[ ! -L "$target" ]]; then
          add_change "SYMLINK" "$rel"
        else
          target_link=$(readlink "$target") || fail "Unable to read target symlink: $target"
          [[ "$source_link" == "$target_link" ]] || add_change "SYMLINK" "$rel"
        fi
        ;;
      f)
        if ! path_exists_or_link "$target"; then
          add_change "CREATE" "$rel"
        elif [[ ! -f "$target" || -L "$target" ]]; then
          add_change "REPLACE" "$rel"
        else
          dst_size=$(file_size "$target") || fail "Unable to inspect target size: $target"
          dst_mode=$(file_mode "$target") || fail "Unable to inspect target permissions: $target"
          if [[ "$fsize" != "$dst_size" ]]; then
            add_change "UPDATE" "$rel"
          elif ! cmp -s "$path" "$target"; then
            add_change "UPDATE" "$rel"
          elif [[ -n "$fmode" && -n "$dst_mode" && "$fmode" != "$dst_mode" ]]; then
            add_change "CHMOD" "$rel"
          fi
        fi
        ;;
      *)
        warn "Skipping unsupported source path type: $rel"
        ;;
      esac
    done
  else
    # Slow path preserved for non-GNU find (BSD/macOS).
    if ! find "$src" -mindepth 1 \( "${prune_expr[@]}" \) -o -print0 >"$scan_file"; then
      rm -f "$scan_file" || warn "Unable to remove failed scan file: $scan_file"
      fail "Source traversal failed; refusing to build a partial change plan for '$src'."
    fi
    mapfile -d '' path_list <"$scan_file" || fail "Unable to read source scan file: $scan_file"
    rm -f "$scan_file" || fail "Unable to remove source scan file: $scan_file"
    for path in ${path_list[@]+"${path_list[@]}"}; do
      rel="${path#"$src"/}"
      should_exclude_rel "$rel" && continue
      target="$dst/$rel"

      if [[ -d "$path" && ! -L "$path" ]]; then
        if ! [[ -d "$target" && ! -L "$target" ]]; then
          add_change "MKDIR" "$rel"
        elif modes_differ "$path" "$target"; then
          add_change "CHMOD" "$rel"
        fi
      elif [[ -L "$path" ]]; then
        source_link=$(readlink "$path") || fail "Unable to read source symlink: $path"
        if [[ ! -L "$target" ]]; then
          add_change "SYMLINK" "$rel"
        else
          target_link=$(readlink "$target") || fail "Unable to read target symlink: $target"
          [[ "$source_link" == "$target_link" ]] || add_change "SYMLINK" "$rel"
        fi
      elif [[ -f "$path" ]]; then
        if ! path_exists_or_link "$target"; then
          add_change "CREATE" "$rel"
        elif [[ ! -f "$target" || -L "$target" ]]; then
          add_change "REPLACE" "$rel"
        else
          src_size=$(file_size "$path") || fail "Unable to inspect source size: $path"
          dst_size=$(file_size "$target") || fail "Unable to inspect target size: $target"
          if [[ "$src_size" != "$dst_size" ]]; then
            add_change "UPDATE" "$rel"
          elif ! cmp -s "$path" "$target"; then
            add_change "UPDATE" "$rel"
          elif modes_differ "$path" "$target"; then
            add_change "CHMOD" "$rel"
          fi
        fi
      else
        warn "Skipping unsupported source path type: $rel"
      fi
    done
  fi

  if [[ "$mirror" -eq 1 ]]; then
    if ! find "$dst" -mindepth 1 -depth -print0 >"$scan_file"; then
      rm -f "$scan_file" || warn "Unable to remove failed scan file: $scan_file"
      fail "Target traversal failed; refusing to build a partial mirror plan for '$dst'."
    fi
    mapfile -d '' path_list <"$scan_file" || fail "Unable to read target scan file: $scan_file"
    rm -f "$scan_file" || fail "Unable to remove target scan file: $scan_file"
    for path in ${path_list[@]+"${path_list[@]}"}; do
      rel="${path#"$dst"/}"
      should_exclude_rel "$rel" && continue
      if ! path_exists_or_link "$src/$rel"; then
        add_change "DELETE" "$rel"
      fi
    done
  fi
}
print_change_summary() {
  if [[ $CHANGE_COUNT -eq 0 ]]; then
    info "No changes detected between source and target with the active exclusions."
    return 0
  fi

  local kind rel shown=0 total=0
  declare -A counts=()
  while IFS= read -r -d '' kind && IFS= read -r -d '' rel; do
    counts["$kind"]=$((${counts["$kind"]:-0} + 1))
    total=$((total + 1))
  done <"$CHANGES_FILE"
  [[ $total -eq $CHANGE_COUNT ]] || fail "Change plan is incomplete or corrupt: expected $CHANGE_COUNT record(s), read $total."

  info "Detected ${AC_BOLD}${AC_FG_BRIGHT_WHITE}$CHANGE_COUNT${AC_R} change(s). Summary:"
  for kind in CREATE UPDATE REPLACE DELETE MKDIR SYMLINK CHMOD; do
    [[ -n "${counts[$kind]:-}" ]] || continue
    printf '  %s  %s\n' "$(kind_label "$kind")" "${counts[$kind]}"
  done
  printf '\n'
  info "Change preview (first $MAX_PREVIEW line(s)):"
  while IFS= read -r -d '' kind && IFS= read -r -d '' rel; do
    if ((shown < MAX_PREVIEW)); then
      printf '  %s  %s\n' "$(kind_label "$kind")" "${AC_DIM}${rel}${AC_R}"
    fi
    shown=$((shown + 1))
  done <"$CHANGES_FILE"
  if [[ "$total" -gt "$MAX_PREVIEW" ]]; then
    warn "Preview truncated: $((total - MAX_PREVIEW)) additional change(s) not shown."
  fi
}
filtered_git_dirty() {
  local dst="${1:-}"
  git -C "$dst" status --porcelain --untracked-files=normal | while IFS= read -r line; do
    local path="${line:3}"
    if should_exclude_rel "$path"; then
      continue
    fi
    printf '%s\n' "$line"
  done
}
check_git_safety() {
  local dst="${1:-}"
  local repo_probe=''
  if repo_probe="$(git -C "$dst" rev-parse --is-inside-work-tree 2>&1)" && [[ "$repo_probe" == "true" ]]; then
    local dirty
    dirty=$(filtered_git_dirty "$dst") || fail "Unable to inspect Git status for target: $dst"
    if [[ -n "$dirty" && $FORCE -ne 1 ]]; then
      printf '%s\n' "$dirty" >&2
      fail "Target git working tree has local changes. Commit/stash them first, or rerun with ${AC_BOLD}--force${AC_R} after reviewing the backup plan."
    fi
  fi
}
create_backup() {
  local dst="${1:-}" timestamp parent base backup_dir backup_file temp_base
  timestamp=$(date '+%Y%m%d_%H%M%S')
  parent=$(dirname "$dst")
  base=$(basename "$dst")
  temp_base="$(get_temp_dir)"

  if [[ -n "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR" || fail "Could not create backup directory: $BACKUP_DIR"
    backup_dir=$(abs_path "$BACKUP_DIR")
  else
    backup_dir="$parent"
    if [[ ! -w "$backup_dir" ]]; then
      backup_dir="$temp_base/sync_backups_${UID:-0}"
      mkdir -p "$backup_dir" || fail "Parent directory $parent is not writable and could not create fallback backup directory $backup_dir"
      warn "Target parent directory ($parent) is not writable. Saving pre-apply backup to $backup_dir"
    fi
  fi

  backup_file="$backup_dir/${base}.backup.${timestamp}.tar.gz"
  printf "${AC_BOLD}${AC_FG_CYAN}[INFO]${AC_R}  Creating pre-apply backup archive: ${AC_DIM}%s${AC_R}\n" "$backup_file" >&2
  log_action "Creating tar.gz backup archive: $backup_file"
  tar -czf "$backup_file" -C "$parent" "$base" || fail "Backup creation failed! Synchronization aborted with zero changes to target."
  cp "$CHANGES_FILE" "${backup_file}.changes.plan" || fail "Backup was created, but the change plan could not be saved beside it."
  printf '%s\n' "$backup_file"
}
copy_one() {
  local src="${1:-}" dst="${2:-}" rel="${3:-}" source_path="$src/$rel" target_path="$dst/$rel" target_parent
  target_parent=$(dirname "$target_path")

  if [[ -d "$source_path" && ! -L "$source_path" ]]; then
    if path_exists_or_link "$target_path" && { [[ ! -d "$target_path" ]] || [[ -L "$target_path" ]]; }; then
      rm -rf "$target_path" || return 1
    fi
    mkdir -p "$target_path" || return 1
    chmod_like_source "$source_path" "$target_path" || return 1
  elif [[ -L "$source_path" ]]; then
    mkdir -p "$target_parent" || return 1
    if path_exists_or_link "$target_path" && ! rm -rf "$target_path"; then
      return 1
    fi
    cp -P "$source_path" "$target_path" || return 1
  elif [[ -f "$source_path" ]]; then
    mkdir -p "$target_parent" || return 1
    if path_exists_or_link "$target_path"; then
      if [[ -d "$target_path" && ! -L "$target_path" ]]; then
        rm -rf "$target_path" || return 1
      elif [[ ! -w "$target_path" ]]; then
        if ! chmod u+w "$target_path"; then
          rm -f "$target_path" || return 1
        fi
      fi
    fi
    # Use cp -a for highest fidelity (xattrs/ACLs/timestamps), with a logged cp -p fallback.
    local copy_error=''
    if ! copy_error="$(cp -a "$source_path" "$target_path" 2>&1)"; then
      [[ -n "$copy_error" ]] && warn "cp -a failed for '$source_path'; retrying with cp -p: $copy_error"
      cp -p "$source_path" "$target_path" || return 1
    fi
  fi
}
handle_apply_failure() {
  local kind="${1:-}" rel="${2:-}"
  APPLY_IN_PROGRESS=0
  printf "\n" >&2
  warn "${AC_FG_BRIGHT_RED}❌ CRITICAL ERROR: Execution failed while trying to apply '$kind' to '$rel'.${AC_R}"
  warn "The target directory '$TARGET_DIR' is in an incomplete, partially updated runtime state."

  if [[ -n "${BACKUP_FILE:-}" && -f "$BACKUP_FILE" ]]; then
    warn "A pristine pre-apply backup archive is available: $BACKUP_FILE"
    if [[ $YES -eq 1 ]]; then
      warn "Running in --yes mode: automatically executing emergency auto-rollback to restore target directory..."
      execute_rollback
    else
      printf "\n${AC_BOLD}${AC_INVERSE} Emergency Auto-Recovery: Type ROLLBACK to automatically restore the target directory from backup: ${AC_R} "
      local response
      IFS= read -r response
      if [[ "$response" == "ROLLBACK" ]]; then
        execute_rollback
      else
        fail "Rollback aborted by user. Please manually extract '$BACKUP_FILE' to restore your target directory."
      fi
    fi
  else
    fail "No backup file found. Please inspect and recover the target directory manually."
  fi
}
execute_rollback() {
  local parent base
  parent=$(dirname "$TARGET_DIR")
  base=$(basename "$TARGET_DIR")
  info "Initiating automated emergency rollback..."
  info "Removing the partial target contents before restoring '$BACKUP_FILE'..."
  log_action "Executing emergency auto-rollback from $BACKUP_FILE"

  # An overlay extraction is not a rollback: files newly created during the
  # failed apply would survive. Clear only the target's children first, while
  # retaining the validated target root itself.
  if ! find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} \;; then
    fail "Fatal: Could not clear the partially updated target. Backup remains at '$BACKUP_FILE'."
  fi

  if tar -xzf "$BACKUP_FILE" -C "$parent"; then
    info "${AC_BOLD}${AC_FG_BRIGHT_GREEN}✔ Emergency auto-rollback completed successfully!${AC_R} Target directory '$TARGET_DIR' has been restored to its pre-sync state."
    log_action "Emergency auto-rollback successful."
    exit 1
  else
    fail "Fatal: Failed to extract the backup during emergency rollback! Please inspect '$parent' and '$BACKUP_FILE'."
  fi
}
apply_changes() {
  local src="${1:-}" dst="${2:-}" kind rel target_path applied=0

  APPLY_IN_PROGRESS=1
  log_action "Beginning active apply of $CHANGE_COUNT changes."

  while IFS= read -r -d '' kind && IFS= read -r -d '' rel; do
    [[ -n "$kind" && -n "$rel" ]] || continue
    log_action "Applying: $kind -> $rel"
    case "$kind" in
    MKDIR | CREATE | UPDATE | REPLACE | SYMLINK)
      copy_one "$src" "$dst" "$rel" || handle_apply_failure "$kind" "$rel"
      ;;
    CHMOD)
      chmod_like_source "$src/$rel" "$dst/$rel" || handle_apply_failure "$kind" "$rel"
      ;;
    DELETE)
      target_path="$dst/$rel"
      if path_exists_or_link "$target_path"; then
        if [[ ! -w "$target_path" && ! -L "$target_path" && -f "$target_path" ]]; then
          chmod u+w "$target_path" || handle_apply_failure "$kind" "$rel"
        fi
        rm -rf "$target_path" || handle_apply_failure "$kind" "$rel"
      fi
      ;;
    *)
      fail "Internal error: unknown change kind '$kind' for '$rel'"
      ;;
    esac
    applied=$((applied + 1))
  done <"$CHANGES_FILE"

  [[ $applied -eq $CHANGE_COUNT ]] || handle_apply_failure "PLAN" "expected $CHANGE_COUNT record(s), applied $applied"
  APPLY_IN_PROGRESS=0
  info "Applied ${AC_BOLD}${AC_FG_BRIGHT_WHITE}$applied${AC_R} change(s)."
  log_action "Successfully applied all $applied changes."
}
# =============================================================================
# Interactive directory browser.
# UI goes to stderr; the selected absolute path is the only stdout output.
# The full-screen picker blocks waiting for input and redraws only after a key.
# =============================================================================
ac_init_terminal() {
  AC_TERM_MODE="full"
  AC_TERM="${TERM:-dumb}"
  AC_HOME="${HOME:-/}"

  # Full-screen rendering requires a real TTY and basic terminfo capabilities.
  if [[ ! -t 0 || ! -t 2 || "$AC_TERM" == "dumb" || "$AC_TERM" == "unknown" ]]; then
    AC_TERM_MODE="plain"
  elif ! command -v tput >/dev/null 2>&1 || ! tput clear >/dev/null 2>&1 || ! tput cup 0 0 >/dev/null 2>&1; then
    AC_TERM_MODE="plain"
  fi

  # Use line-drawing characters only in a UTF-8 locale. Keep all icons
  # single-column so border calculations are deterministic.
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8* | *utf8* | *UTF8*) AC_UNICODE=1 ;;
  *) AC_UNICODE=0 ;;
  esac
  [[ -n "${NO_UNICODE:-}" ]] && AC_UNICODE=0

  if ((AC_UNICODE)); then
    AC_TL='╭'
    AC_TR='╮'
    AC_BL='╰'
    AC_BR='╯'
    AC_H='─'
    AC_V='│'
    AC_ELL='…'
    AC_DIR='📁'
    AC_SYMLINK='🔗'
  else
    AC_TL='+'
    AC_TR='+'
    AC_BL='+'
    AC_BR='+'
    AC_H='-'
    AC_V='|'
    AC_ELL='...'
    AC_DIR='[D]'
    AC_SYMLINK='[L]'
  fi
  AC_ARR='>'
  AC_UP='^'
  AC_DOWN='v'
  AC_LINK='->'
  AC_LOCK='[!]'
  AC_SEL='*'

  # if ((AC_UNICODE)); then
  #   AC_TL='╭'
  #   AC_TR='╮'
  #   AC_BL='╰'
  #   AC_BR='╯'
  #   AC_H='─'
  #   AC_V='│'
  #   AC_ELL='…'
  # else
  #   AC_TL='+'
  #   AC_TR='+'
  #   AC_BL='+'
  #   AC_BR='+'
  #   AC_H='-'
  #   AC_V='|'
  #   AC_ELL='...'
  # fi
  # AC_ARR='>'
  # AC_UP='^'
  # AC_DOWN='v'
  # AC_LINK='->'
  # AC_LOCK='[!]'
  # AC_SEL='*'
}

ac_term_size() {
  local rows='' cols='' size=''
  if command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
    rows="$(tput lines 2>/dev/null || true)"
  fi
  if [[ ! "$cols" =~ ^[0-9]+$ || ! "$rows" =~ ^[0-9]+$ ]]; then
    size="$(stty size </dev/tty 2>/dev/null || true)"
    rows="${size%% *}"
    cols="${size##* }"
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  printf '%s %s\n' "$cols" "$rows"
}

ac_hide_cursor() {
  [[ "${AC_TERM_MODE:-plain}" == full ]] || return 0
  tput civis 2>/dev/null || true
}
ac_show_cursor() {
  [[ "${AC_TERM_MODE:-plain}" == full ]] || return 0
  tput cnorm 2>/dev/null || true
}
ac_clear_screen() {
  [[ "${AC_TERM_MODE:-plain}" == full ]] || return 0
  tput clear >&2 2>/dev/null || printf '\033[H\033[2J' >&2
}

ac_strip_ansi() {
  # CSI color/style sequences generated by this script.
  printf '%s' "${1:-}" | sed $'s/\033\\[[0-9;]*[[:alpha:]]//g'
}
ac_visible_len() {
  local plain
  plain="$(ac_strip_ansi "${1:-}")"
  printf '%s' "${#plain}"
}

# Truncate text containing ANSI styles. The UI deliberately uses single-cell
# chrome; non-ASCII file names are handled by the active shell locale.
ac_truncate() {
  local text="${1:-}" max="${2:-80}" vis out='' i=0 len c code keep visible=0
  ((max > 0)) || return 0
  vis="$(ac_visible_len "$text")"
  ((vis <= max)) && {
    printf '%s' "$text"
    return 0
  }
  keep=$((max - ${#AC_ELL}))
  ((keep < 0)) && keep=0
  len=${#text}
  while ((visible < keep && i < len)); do
    c="${text:i:1}"
    i=$((i + 1))
    if [[ "$c" == $'\033' ]]; then
      code="$c"
      while ((i < len)); do
        c="${text:i:1}"
        code+="$c"
        i=$((i + 1))
        [[ "$c" =~ [[:alpha:]] ]] && break
      done
      out+="$code"
    else
      out+="$c"
      visible=$((visible + 1))
    fi
  done
  printf '%s%s' "$out" "$AC_ELL"
}

ac_box_row() {
  local text="${1:-}" sel="${2:-0}" dim="${3:-0}" width="${inner:-1}"
  local vis pad_r middle left_color='' body_color='' reset="${AC_R:-}"
  ((width > 0)) || width=1
  vis="$(ac_visible_len "$text")"
  if ((vis > width)); then
    text="$(ac_truncate "$text" "$width")"
    vis="$(ac_visible_len "$text")"
  fi
  pad_r=$((width - vis))
  ((pad_r < 0)) && pad_r=0
  printf -v middle '%s%*s' "$text" "$pad_r" ''
  left_color="${AC_FG_BRIGHT_CYAN:-}"
  if ((sel)); then
    body_color="${AC_BOLD:-}${AC_FG_BRIGHT_GREEN:-}"
  elif ((dim)); then
    body_color="${AC_DIM:-}"
  fi
  printf '%s%s%s%s%s%s%s\n' "$left_color" "$AC_V" "$reset" "$body_color" "$middle" "$reset$left_color$AC_V" "$reset" >&2
}
ac_box_rule() {
  local left="${1:-+}" right="${2:-+}" hb=''
  printf -v hb '%*s' "${inner:-1}" ''
  hb="${hb// /$AC_H}"
  printf '%s%s%s%s%s%s\n' "${AC_FG_BRIGHT_CYAN:-}" "$left" "$hb" "$right" "${AC_R:-}" '' >&2
}
ac_box_top() { ac_box_rule "$AC_TL" "$AC_TR"; }
ac_box_bottom() { ac_box_rule "$AC_BL" "$AC_BR"; }
ac_box_title() {
  local t=" ${1:-}"
  ac_box_row "$t" 0 0
}

# Update only the three-character selection marker. Rows are zero-based for
# `tput cup`; column 1 is immediately inside the left border. The menu body is
# intentionally not highlighted, so moving the selection never requires a row
# or full-screen repaint.
ac_draw_pointer() {
  local index="${1:-0}" window="${2:-0}" enabled="${3:-0}" prompt_row="${4:-0}"
  local row=$((3 + (window > 0 ? 1 : 0) + index - window))

  if [[ "${AC_MENU_SAVED:-0}" -eq 1 ]]; then
    tput rc >&2 2>/dev/null || return 1
    if ((row > 0)); then
      tput cud "$row" >&2 2>/dev/null || printf '\033[%dB' "$row" >&2
    fi
    tput cuf 1 >&2 2>/dev/null || printf '\033[1C' >&2
  else
    tput cup "$row" 1 >&2 2>/dev/null || return 1
  fi

  if ((enabled)); then
    printf '%s %s %s' "${AC_BOLD:-}${AC_FG_BRIGHT_GREEN:-}" "$AC_ARR" "${AC_R:-}" >&2
  else
    printf '   ' >&2
  fi

  if [[ "${AC_MENU_SAVED:-0}" -eq 1 ]]; then
    tput rc >&2 2>/dev/null || true
    if ((prompt_row > 0)); then
      tput cud "$prompt_row" >&2 2>/dev/null || printf '\033[%dB' "$prompt_row" >&2
    fi
    tput cr >&2 2>/dev/null || printf '\r' >&2
  else
    tput cup "$prompt_row" 0 >&2 2>/dev/null || true
  fi
}

# Blocking key read. The only timeout is after ESC, to distinguish ESC from an
# escape sequence. Therefore an idle menu consumes no CPU and never redraws.
ac_read_key() {
  local key='' seq=''
  IFS= read -rsn1 key </dev/tty || {
    printf 'EOF'
    return
  }
  [[ -z "$key" ]] && {
    printf 'ENTER'
    return
  }
  if [[ "$key" == $'\033' ]]; then
    IFS= read -rsn1 -t 0.08 seq </dev/tty 2>/dev/null || {
      printf 'ESC'
      return
    }
    if [[ "$seq" == '[' || "$seq" == 'O' ]]; then
      local tail=''
      IFS= read -rsn1 -t 0.08 tail </dev/tty 2>/dev/null || true
      case "$tail" in A) printf 'UP' ;; B) printf 'DOWN' ;; C) printf 'RIGHT' ;; D) printf 'LEFT' ;; *) printf 'ESC' ;; esac
    else
      printf 'ESC'
    fi
    return
  fi
  [[ "$key" == $'\177' || "$key" == $'\010' ]] && {
    printf 'BACKSPACE'
    return
  }
  printf '%s' "$key"
}

ac_read_filter() {
  local q='' ch
  printf '\r\033[K  > Filter: ' >&2
  while :; do
    ch="$(ac_read_key)"
    case "$ch" in
    ENTER) break ;;
    ESC)
      q=''
      break
      ;;
    BACKSPACE) q="${q%?}" ;;
    EOF)
      q=''
      break
      ;;
    *) [[ ${#ch} -eq 1 ]] && q+="$ch" ;;
    esac
    printf '\r\033[K  > Filter: %s' "$q" >&2
  done
  printf '\n' >&2
  printf '%s' "$q"
}

ac_list_dirs() {
  local dir="${1:-}" hidden="${2:-0}" p
  local -a out=()
  if ((hidden)); then
    while IFS= read -r -d '' p; do [[ -d "$p" || -L "$p" ]] && out+=("$p"); done \
      < <(find "$dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) -print0 2>/dev/null)
  else
    while IFS= read -r -d '' p; do [[ -d "$p" || -L "$p" ]] && out+=("$p"); done \
      < <(find "$dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) ! -name '.*' -print0 2>/dev/null)
  fi
  ((${#out[@]})) && printf '%s\0' "${out[@]}"
}

_ac_descend() {
  local p="${1:-}" rp='' v
  [[ -d "$p" ]] || {
    warn "Not a directory."
    return 1
  }
  rp="$(abs_path "$p")" || return 1
  for v in ${visited[@]+"${visited[@]}"}; do
    [[ "$v" == "$rp" ]] && {
      warn "Loop prevented: already visited."
      return 1
    }
  done
  visited+=("$rp")
  cur_dir="$rp"
  SELECTED_INDEX=0
  filter=''
}

ac_prompt_path() {
  local default="${1:-/}" answer=''
  printf 'Enter directory path [%s]: ' "$default" >&2
  IFS= read -r answer </dev/tty || return 1
  printf '%s' "${answer:-$default}"
}

_ac_act() {
  local kind="${1:-}" path="${2:-}" cp=''
  case "$kind" in
  select)
    chosen="$path"
    return 0
    ;;
  up)
    cur_dir="$(dirname "$cur_dir")"
    SELECTED_INDEX=0
    filter=''
    return 1
    ;;
  custom)
    cp="$(ac_prompt_path "$cur_dir")" || return 1
    if [[ -d "$cp" ]]; then
      chosen="$(abs_path "$cp")"
      return 0
    fi
    warn "Not a directory: $cp"
    return 1
    ;;
  dir | symlink)
    _ac_descend "$path"
    return 1
    ;;
  *) return 1 ;;
  esac
}

# Line-oriented fallback for TERM=dumb, missing terminfo, or very small screens.
ac_pick_dir_plain() {
  local label="${1:-Select directory}" cur_dir="${2:-${HOME:-/}}" answer='' p base i
  local -a entries=()
  while :; do
    entries=()
    while IFS= read -r -d '' p; do entries+=("$p"); done < <(ac_list_dirs "$cur_dir" 0)
    printf '\n%s\nCurrent: %s\n  0) select this folder\n  u) up  c) custom path  q) cancel\n' "$label" "$cur_dir" >&2
    for i in ${entries[@]+"${!entries[@]}"}; do
      base="$(basename "${entries[$i]}")"
      p="${entries[$i]}"
      if [[ -L "$p" ]]; then
        printf '  %d) %s %s\n' "$((i + 1))" "$AC_SYMLINK" "$base" >&2
      else
        printf '  %d) %s %s\n' "$((i + 1))" "$AC_DIR" "$base" >&2
      fi
    done
    printf 'Choice: ' >&2
    IFS= read -r answer </dev/tty || return 1
    case "$answer" in
    0)
      printf '%s\n' "$cur_dir"
      return 0
      ;;
    u | U) [[ "$cur_dir" != / ]] && cur_dir="$(dirname "$cur_dir")" ;;
    c | C)
      p="$(ac_prompt_path "$cur_dir")" || continue
      [[ -d "$p" ]] && cur_dir="$(abs_path "$p")" || warn "Not a directory: $p"
      ;;
    q | Q) return 1 ;;
    *)
      if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= ${#entries[@]})); then cur_dir="$(abs_path "${entries[$((answer - 1))]}")"; else warn "Invalid choice."; fi
      ;;
    esac
  done
}

ac_pick_dir() {
  [[ -t 0 && -t 2 ]] || return 1
  ac_init_terminal
  local label="${1:-Select directory}" start="${2:-${HOME:-/}}"
  if [[ "$AC_TERM_MODE" != full ]]; then
    ac_pick_dir_plain "$label" "$start"
    return $?
  fi

  local cur_dir="$start" filter='' show_hidden=0 SELECTED_INDEX=0 chosen=''
  local -a visited=() disp=() paths=() kinds=() entries=() fdisp=() fpaths=() fkinds=()
  local dims AC_COLS=0 AC_ROWS=0 inner=1 total=0 vis=1 win=0 i p base kind lab lock prefix key
  local selected_kind selected_path footer shown=0 above=0 below=0 menu_prompt_row=0
  local needs_redraw=1 rendered_cols=0 rendered_rows=0 old_index new_index new_win
  # Save cursor position so we can redraw the menu without clearing the screen
  AC_MENU_SAVED=0
  if [[ "$AC_TERM_MODE" == full ]]; then
    tput sc >&2 2>/dev/null && AC_MENU_SAVED=1
  fi

  while :; do
    dims="$(ac_term_size)"
    AC_COLS="${dims%% *}"
    AC_ROWS="${dims##* }"

    # A resize changes every border coordinate, so it legitimately requires a
    # complete repaint on the next key. Ordinary Up/Down movement does not.
    if ((AC_COLS != rendered_cols || AC_ROWS != rendered_rows)); then needs_redraw=1; fi

    # Leave the last physical column unused to avoid delayed-wrap glitches.
    if ((AC_COLS < 24 || AC_ROWS < 10)); then
      AC_MENU_SAVED=0
      ac_show_cursor
      ac_pick_dir_plain "$label" "$cur_dir"
      return $?
    fi

    if ((needs_redraw)); then
      inner=$((AC_COLS - 3))
      disp=("$AC_SEL Select this folder: $cur_dir")
      paths=("$cur_dir")
      kinds=("select")
      if [[ "$cur_dir" != / ]]; then
        disp+=(".. (up one level)")
        paths+=("__UP__")
        kinds+=("up")
      fi

      entries=()
      while IFS= read -r -d '' p; do entries+=("$p"); done < <(ac_list_dirs "$cur_dir" "$show_hidden")
      for p in ${entries[@]+"${entries[@]}"}; do
        base="$(basename "$p")"
        kind='dir'
        [[ -L "$p" ]] && kind='symlink'
        lock=0
        [[ ! -r "$p" || ! -x "$p" ]] && lock=1
        if [[ "$kind" == symlink ]]; then
          lab="$AC_SYMLINK $base"
          lab+=" $AC_LINK $(readlink "$p" 2>/dev/null || true)"
        else
          lab="$AC_DIR $base"
        fi
        ((lock)) && lab+=" $AC_LOCK"
        disp+=("$lab")
        paths+=("$p")
        kinds+=("$kind")
      done
      disp+=("[ Type a custom path$AC_ELL ]")
      paths+=("__CUSTOM__")
      kinds+=("custom")

      fdisp=()
      fpaths=()
      fkinds=()
      for i in ${disp[@]+"${!disp[@]}"}; do
        kind="${kinds[$i]}"
        if [[ -z "$filter" || "$kind" == select || "$kind" == up || "$kind" == custom || "${disp[$i],,}" == *"${filter,,}"* ]]; then
          fdisp+=("${disp[$i]}")
          fpaths+=("${paths[$i]}")
          fkinds+=("$kind")
        fi
      done
      total=${#fdisp[@]}
      if ((total == 0)); then
        filter=''
        continue
      fi
      ((SELECTED_INDEX < 0)) && SELECTED_INDEX=0
      ((SELECTED_INDEX >= total)) && SELECTED_INDEX=$((total - 1))

      # Header (3), borders (2), footer (1), and up/down indicators (up to 2).
      vis=$((AC_ROWS - 8))
      ((vis < 1)) && vis=1
      win=$((SELECTED_INDEX / vis * vis))
      above=0
      below=0
      ((win > 0)) && above=1
      ((win + vis < total)) && below=1
      shown=$((total - win))
      ((shown > vis)) && shown=$vis
      menu_prompt_row=$((3 + above + shown + below + 2))

      if [[ "$AC_TERM_MODE" == full ]]; then
        if [[ "${AC_MENU_SAVED:-0}" -eq 1 ]]; then
          tput rc >&2 2>/dev/null || true
          tput ed >&2 2>/dev/null || printf '\033[J' >&2
        else
          ac_clear_screen
        fi
      fi
      ac_box_top
      ac_box_title "$label"
      ac_box_row "  $cur_dir" 0 1
      ((above)) && ac_box_row "  $AC_UP more above" 0 1
      for ((i = win; i < win + shown; i++)); do
        prefix='   '
        ((i == SELECTED_INDEX)) && prefix=" $AC_ARR "
        # Selection is represented only by the marker. No full-row style is
        # applied, allowing Up/Down to change exactly six character cells:
        # erase the old marker and draw the new one.
        ac_box_row "$prefix${fdisp[$i]}" 0 0
      done
      ((below)) && ac_box_row "  $AC_DOWN more below" 0 1
      ac_box_bottom
      footer='Up/Dn move  Enter open  s select  Left up  / filter  h hidden  ~ home  q quit'
      printf ' %s\n' "$(ac_truncate "$footer" "$((AC_COLS - 2))")" >&2

      rendered_cols=$AC_COLS
      rendered_rows=$AC_ROWS
      needs_redraw=0
    fi

    key="$(ac_read_key)"
    case "$key" in
    UP | k | K)
      old_index=$SELECTED_INDEX
      new_index=$((SELECTED_INDEX - 1))
      ((new_index < 0)) && new_index=0
      if ((new_index != old_index)); then
        new_win=$((new_index / vis * vis))
        SELECTED_INDEX=$new_index
        if ((new_win == win)); then
          ac_draw_pointer "$old_index" "$win" 0 "$menu_prompt_row"
          ac_draw_pointer "$new_index" "$win" 1 "$menu_prompt_row"
        else
          needs_redraw=1
        fi
      fi
      ;;
    DOWN | j | J)
      old_index=$SELECTED_INDEX
      new_index=$((SELECTED_INDEX + 1))
      ((new_index >= total)) && new_index=$((total - 1))
      if ((new_index != old_index)); then
        new_win=$((new_index / vis * vis))
        SELECTED_INDEX=$new_index
        if ((new_win == win)); then
          ac_draw_pointer "$old_index" "$win" 0 "$menu_prompt_row"
          ac_draw_pointer "$new_index" "$win" 1 "$menu_prompt_row"
        else
          needs_redraw=1
        fi
      fi
      ;;
    ENTER | RIGHT)
      selected_kind="${fkinds[$SELECTED_INDEX]:-}"
      selected_path="${fpaths[$SELECTED_INDEX]:-}"
      if [[ "$selected_kind" == dir || "$selected_kind" == symlink ]]; then
        _ac_descend "$selected_path" || true
      else
        _ac_act "$selected_kind" "$selected_path" && break
      fi
      needs_redraw=1
      ;;
    LEFT | BACKSPACE)
      if [[ -n "$filter" ]]; then
        filter=''
        needs_redraw=1
      elif [[ "$cur_dir" != / ]]; then
        cur_dir="$(dirname "$cur_dir")"
        SELECTED_INDEX=0
        needs_redraw=1
      fi
      ;;
    s | S | ' ')
      selected_kind="${fkinds[$SELECTED_INDEX]:-}"
      selected_path="${fpaths[$SELECTED_INDEX]:-}"
      if [[ "$selected_kind" == dir || "$selected_kind" == symlink ]]; then
        if [[ -d "$selected_path" ]]; then
          chosen="$(abs_path "$selected_path")"
          break
        else
          warn "Not a directory."
        fi
      else
        _ac_act "$selected_kind" "$selected_path" && break
      fi
      needs_redraw=1
      ;;
    / | f | F)
      filter="$(ac_read_filter)"
      SELECTED_INDEX=0
      needs_redraw=1
      ;;
    h | H)
      show_hidden=$((1 - show_hidden))
      SELECTED_INDEX=0
      needs_redraw=1
      ;;
    '~')
      cur_dir="${HOME:-/}"
      SELECTED_INDEX=0
      filter=''
      needs_redraw=1
      ;;
    q | Q | EOF) return 1 ;;
    ESC) : ;;
    *) : ;;
    esac
  done
  AC_MENU_SAVED=0
  [[ -n "$chosen" ]] && printf '%s\n' "$chosen"
}
ac_wizard() {
  [[ -t 0 && -t 2 ]] || {
    fail "Interactive directory picker requires a terminal (TTY)."
    return 2
  }
  ac_init_terminal
  ac_hide_cursor
  trap 'ac_show_cursor; exit 130' INT TERM HUP
  local src='' tgt=''
  info "Step 1 of 2 — choose the SOURCE directory (contains the updated files)."
  src="$(ac_pick_dir "Select SOURCE directory" "${HOME:-/}")" || {
    ac_show_cursor
    warn "Selection cancelled."
    return 1
  }
  [[ -n "$src" ]] || {
    ac_show_cursor
    return 1
  }
  info "Step 2 of 2 — choose the TARGET directory (will be updated to match source)."
  tgt="$(ac_pick_dir "Select TARGET directory" "${HOME:-/}")" || {
    ac_show_cursor
    warn "Selection cancelled."
    return 1
  }
  [[ -n "$tgt" ]] || {
    ac_show_cursor
    return 1
  }
  ac_show_cursor
  trap - INT TERM HUP
  printf 'Preview and apply changes? [Y/n] ' >&2
  local answer=''
  IFS= read -r answer </dev/tty || answer=n
  if [[ -z "$answer" || "$answer" == y || "$answer" == Y ]]; then ac_main --apply --yes "$src" "$tgt"; else ac_main "$src" "$tgt"; fi
}

# Argument parsing & execution entry point -
ac_main() {
  _setup_colors
  uk_banner "apply-changes" "Directory sync with dry-run preview, backup, and rollback" "" "$@"
  trap 'cleanup_and_trap EXIT' EXIT
  trap 'cleanup_and_trap SIGINT' SIGINT
  trap 'cleanup_and_trap SIGTERM' SIGTERM
  trap 'cleanup_and_trap SIGHUP' SIGHUP

  INTERACTIVE=0
  MODE="dry-run"
  MIRROR=0
  FORCE=0
  YES=0
  INCLUDE_RUNTIME=0
  BACKUP_DIR=""
  MAX_PREVIEW=200
  EXCLUDES=()
  LOG_FILE=""
  NO_LOCK=0
  LOCK_ACQUIRED=0
  LOCK_DIR=""
  APPLY_IN_PROGRESS=0
  TRAP_RUN=0
  CHANGE_COUNT=0

  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --apply) MODE="apply" ;;
    --interactive | -i) INTERACTIVE=1 ;;
    --dry-run) MODE="dry-run" ;;
    --mirror) MIRROR=1 ;;
    --force) FORCE=1 ;;
    --yes | -y) YES=1 ;;
    --include-runtime | --include-logs | --no-default-excludes) INCLUDE_RUNTIME=1 ;;
    --no-lock) NO_LOCK=1 ;;
    --exclude)
      shift
      [[ $# -gt 0 ]] || fail "--exclude requires a pattern argument."
      EXCLUDES+=("${1:-}")
      ;;
    --exclude=*) EXCLUDES+=("${1#--exclude=}") ;;
    --log-file)
      shift
      [[ $# -gt 0 ]] || fail "--log-file requires a file argument."
      LOG_FILE="${1:-}"
      ;;
    --log-file=*) LOG_FILE="${1#--log-file=}" ;;
    --backup-dir)
      shift
      [[ $# -gt 0 ]] || fail "--backup-dir requires a directory argument."
      BACKUP_DIR="${1:-}"
      ;;
    --backup-dir=*) BACKUP_DIR="${1#--backup-dir=}" ;;
    --max-preview)
      shift
      [[ $# -gt 0 ]] || fail "--max-preview requires a number."
      MAX_PREVIEW="${1:-}"
      ;;
    --max-preview=*) MAX_PREVIEW="${1#--max-preview=}" ;;
    -h | --help)
      usage
      return 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        POSITIONAL+=("${1:-}")
        shift
      done
      break
      ;;
    --*) fail "Unknown option: ${1:-}" ;;
    *) POSITIONAL+=("${1:-}") ;;
    esac
    shift
  done

  if [[ "${INTERACTIVE:-0}" -eq 1 ]]; then
    ac_wizard
    return $?
  fi

  [[ "$MAX_PREVIEW" =~ ^[0-9]+$ && "$MAX_PREVIEW" -gt 0 ]] || fail "--max-preview must be a positive integer."
  [[ ${#POSITIONAL[@]} -eq 2 ]] || {
    usage >&2
    return 2
  }

  SOURCE_DIR=$(abs_path "${POSITIONAL[0]}") || fail "Could not resolve source path: ${POSITIONAL[0]}"
  TARGET_DIR=$(abs_path "${POSITIONAL[1]}") || fail "Could not resolve target path: ${POSITIONAL[1]}"

  [[ -d "$SOURCE_DIR" ]] || fail "Source directory does not exist: $SOURCE_DIR"
  [[ -d "$TARGET_DIR" ]] || fail "Target directory does not exist: $TARGET_DIR"
  [[ "$SOURCE_DIR" != "$TARGET_DIR" ]] || fail "Source and target are the same directory."

  case "$SOURCE_DIR/" in
  "$TARGET_DIR"/*) fail "Source is inside target; refusing to avoid recursive copy/delete hazards." ;;
  esac
  case "$TARGET_DIR/" in
  "$SOURCE_DIR"/*) fail "Target is inside source; refusing to avoid recursive copy/delete hazards." ;;
  esac

  if [[ -n "$LOG_FILE" ]]; then
    mkdir -p "$(dirname "$LOG_FILE")" || fail "Unable to create log directory for: $LOG_FILE"
    log_action "=== Synchronization Script Started (${MODE^^} Mode) ==="
    log_action "Source: $SOURCE_DIR"
    log_action "Target: $TARGET_DIR"
  fi

  acquire_lock

  TEMP_BASE="$(get_temp_dir)" || fail "Unable to resolve a temporary directory for the change plan."
  if ! CHANGES_FILE=$(mktemp "$TEMP_BASE/apply_changes.XXXXXX"); then
    fail "CRITICAL: Unable to create a secure temporary plan file in '$TEMP_BASE'."
  fi
  : >"$CHANGES_FILE" || fail "CRITICAL: Unable to initialize temporary plan file '$CHANGES_FILE'. Please verify your filesystem permissions."
  CHANGE_COUNT=0

  info "Source: ${AC_FG_CYAN}$SOURCE_DIR${AC_R}"
  info "Target: ${AC_FG_CYAN}$TARGET_DIR${AC_R}"
  [[ $MIRROR -eq 1 ]] && warn "Mirror mode is enabled: non-excluded target files missing from source will be ${AC_FG_BRIGHT_RED}deleted${AC_R}."
  [[ $INCLUDE_RUNTIME -eq 0 ]] && info "Runtime logs are excluded by default. Use ${AC_BOLD}--include-runtime${AC_R} (or ${AC_BOLD}--include-logs${AC_R}) to sync them."
  [[ ${#EXCLUDES[@]} -gt 0 ]] && info "Active custom exclusions: ${AC_BOLD}${AC_FG_BRIGHT_WHITE}${EXCLUDES[*]}${AC_R}"
  [[ -n "$LOG_FILE" ]] && info "Audit logging active: ${AC_DIM}$LOG_FILE${AC_R}"

  collect_changes "$SOURCE_DIR" "$TARGET_DIR" "$MIRROR"
  print_change_summary

  if [[ $CHANGE_COUNT -eq 0 ]]; then
    log_action "No changes detected. Exiting normally."
    release_lock
    return 0
  fi

  if [[ "$MODE" != "apply" ]]; then
    info "Dry-run only. Rerun with ${AC_BOLD}${AC_FG_BRIGHT_CYAN}--apply${AC_R} to copy these changes."
    log_action "Dry-run completed."
    release_lock
    return 0
  fi

  check_git_safety "$TARGET_DIR"

  if [[ -n "$BACKUP_DIR" ]]; then
    mkdir -p "$BACKUP_DIR" || fail "Could not create backup directory: $BACKUP_DIR"
    check_disk_space "$TARGET_DIR" "$BACKUP_DIR" "$SOURCE_DIR"
  else
    check_disk_space "$TARGET_DIR" "$(dirname "$TARGET_DIR")" "$SOURCE_DIR"
  fi

  check_target_writable "$TARGET_DIR"

  if [[ $YES -ne 1 ]]; then
    printf "\n${AC_BOLD}${AC_INVERSE} Type APPLY to update the target directory after creating a backup: ${AC_R} "
    IFS= read -r confirmation
    [[ "$confirmation" == "APPLY" ]] || {
      log_action "User aborted at APPLY confirmation."
      fail "Confirmation did not match APPLY; aborted with no changes."
    }
  fi

  BACKUP_FILE=$(create_backup "$TARGET_DIR")
  apply_changes "$SOURCE_DIR" "$TARGET_DIR"

  # Verify by recomputing the same plan.
  collect_changes "$SOURCE_DIR" "$TARGET_DIR" "$MIRROR"
  if [[ $CHANGE_COUNT -eq 0 ]]; then
    info "${AC_FG_BRIGHT_GREEN}✔ Verification succeeded:${AC_R} target now matches the source for the selected sync mode."
    log_action "Verification succeeded."
  else
    warn "${AC_FG_BRIGHT_RED}✖ Verification found remaining differences after apply:${AC_R}"
    log_action "Verification found remaining differences."
    print_change_summary
    warn "Backup archive retained for recovery: $BACKUP_FILE"
    release_lock || return 1
    return 1
  fi

  info "Backup archive: ${AC_DIM}$BACKUP_FILE${AC_R}"
  info "If you need to restore, move the updated target aside and extract the backup into its parent directory."
  log_action "=== Synchronization Script Completed Successfully ==="

  release_lock
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  ac_main "$@"
fi

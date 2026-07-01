#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

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
# Color + style setup — disabled when not a TTY or NO_COLOR is set
_setup_colors() {
  if [[ -t 1 && -t 2 && -z "${NO_COLOR:-}" ]]; then
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
    mkdir -p "$HOME/.apply_temp" 2>/dev/null || true
    if [[ -d "$HOME/.apply_temp" && -w "$HOME/.apply_temp" ]]; then
      printf '%s\n' "$HOME/.apply_temp"
    else
      printf '%s\n' "."
    fi
  fi
}
# Signal Handling & Safe Interruption Cleanup
cleanup_and_trap() {
  local exit_code=$?
  local sig="${1:-EXIT}"

  [[ $TRAP_RUN -eq 0 ]] || return 0
  TRAP_RUN=1

  release_lock
  if [[ -n "${CHANGES_FILE:-}" && -f "$CHANGES_FILE" ]]; then
    rm -f "$CHANGES_FILE" 2>/dev/null || true
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
# Non-fatal Graceful Concurrency Locking
acquire_lock() {
  [[ $NO_LOCK -eq 0 ]] || return 0

  local target_hash temp_base
  temp_base="$(get_temp_dir)"
  target_hash=$(printf '%s' "$TARGET_DIR" | md5sum | awk '{print ${1:-}}' 2>/dev/null || echo "default")
  LOCK_DIR="$temp_base/.apply_sync_lock_${UID:-0}_${target_hash}"

  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    local pid
    pid=$(cat "$LOCK_DIR/pid" 2>/dev/null || echo "unknown")
    if [[ "$pid" != "unknown" ]] && kill -0 "$pid" 2>/dev/null; then
      fail "Another synchronization instance (PID $pid) is currently running on '$TARGET_DIR'. Aborting to prevent data corruption."
    else
      warn "Found stale concurrency lock from inactive PID $pid. Reclaiming lock..."
      rm -rf "$LOCK_DIR" 2>/dev/null || true
      if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        warn "⚠️ Unable to create concurrency lock directory '$LOCK_DIR'. Proceeding safely without locking."
        LOCK_ACQUIRED=0
        return 0
      fi
    fi
  fi
  printf '%s\n' "$$" >"$LOCK_DIR/pid" 2>/dev/null || {
    warn "⚠️ Unable to write PID to lock directory '$LOCK_DIR'. Proceeding safely without locking."
    LOCK_ACQUIRED=0
    return 0
  }
  LOCK_ACQUIRED=1
  log_action "Concurrency lock acquired: $LOCK_DIR (PID $$)"
}

release_lock() {
  if [[ "${LOCK_ACQUIRED:-0}" -eq 1 && -n "${LOCK_DIR:-}" && -d "$LOCK_DIR" ]]; then
    rm -rf "$LOCK_DIR" 2>/dev/null || true
    LOCK_ACQUIRED=0
    log_action "Concurrency lock released."
  fi
}
# Pre-flight Disk Space Safety Guard
check_disk_space() {
  local dst="${1:-}" backup_dir="${2:-}" src="${3:-}"
  info "Performing pre-flight disk space safety check..."

  local src_size_kb avail_dst_kb avail_bak_kb req_bak_kb req_dst_kb
  src_size_kb=$(du -sk "$src" 2>/dev/null | awk '{print ${1:-}}' || echo 0)

  local target_size_kb
  target_size_kb=$(du -sk "$dst" 2>/dev/null | awk '{print ${1:-}}' || echo 0)

  # Buffer: 1x target size + 20MB safety margin for backup archive
  req_bak_kb=$((target_size_kb + 20480))
  # Buffer: source changed size + 20MB safety margin for target copying
  req_dst_kb=$((src_size_kb + 20480))

  avail_dst_kb=$(df -kP "$dst" 2>/dev/null | awk 'NR==2 {print ${4:-}}' || echo 999999999)
  avail_bak_kb=$(df -kP "$backup_dir" 2>/dev/null | awk 'NR==2 {print ${4:-}}' || echo 999999999)

  if [[ "$avail_bak_kb" =~ ^[0-9]+$ && "$avail_bak_kb" -lt "$req_bak_kb" ]]; then
    warn "Low available disk space on backup partition '$backup_dir'!"
    warn "Available: $((avail_bak_kb / 1024)) MB | Estimated Minimum Required: $((req_bak_kb / 1024)) MB"
    fail "Insufficient disk space to guarantee safe backup creation. Please free up space or use --backup-dir to specify a larger storage drive."
  fi

  if [[ "$avail_dst_kb" =~ ^[0-9]+$ && "$avail_dst_kb" -lt "$req_dst_kb" ]]; then
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
  while IFS=$'\t' read -r kind rel; do
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
  printf '%s\t%s\n' "$kind" "$rel" >>"$CHANGES_FILE"
  CHANGE_COUNT=$((CHANGE_COUNT + 1))
}
path_exists_or_link() {
  [[ -e "${1:-}" || -L "${1:-}" ]]
}
file_mode() {
  stat -c '%a' "${1:-}" 2>/dev/null || stat -f '%Lp' "${1:-}" 2>/dev/null || true
}
modes_differ() {
  local left_mode right_mode
  left_mode=$(file_mode "${1:-}")
  right_mode=$(file_mode "${2:-}")
  [[ -n "$left_mode" && -n "$right_mode" && "$left_mode" != "$right_mode" ]]
}
# Permissive chmod ensures silent fallback on Android /sdcard, FAT, or SMB shares
chmod_like_source() {
  local source_path="${1:-}" target_path="${2:-}" mode
  chmod --reference="$source_path" "$target_path" 2>/dev/null && return 0
  mode=$(file_mode "$source_path")
  [[ -n "$mode" ]] || return 0
  chmod "$mode" "$target_path" 2>/dev/null || true
}
collect_changes() {
  local src="${1:-}" dst="${2:-}" mirror="${3:-}"
  : >"$CHANGES_FILE"
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
  local _have_printf=0
  if find "$src" -maxdepth 0 -printf '' >/dev/null 2>&1; then
    _have_printf=1
  fi

  local path_list rec ftype fsize fmode tmeta dst_mode
  if ((_have_printf)); then
    mapfile -d '' path_list < <(find "$src" -mindepth 1 \( "${prune_expr[@]}" \) -o -printf '%y\t%s\t%m\t%p\0')
    for rec in "${path_list[@]}"; do
      # Record layout: type<TAB>size<TAB>mode<TAB>path  (path may itself contain tabs)
      ftype="${rec%%$'\t'*}"; rec="${rec#*$'\t'}"
      fsize="${rec%%$'\t'*}"; rec="${rec#*$'\t'}"
      fmode="${rec%%$'\t'*}"; path="${rec#*$'\t'}"
      rel="${path#"$src"/}"
      should_exclude_rel "$rel" && continue
      target="$dst/$rel"

      case "$ftype" in
      d)
        if ! [[ -d "$target" && ! -L "$target" ]]; then
          add_change "MKDIR" "$rel"
        else
          dst_mode=$(file_mode "$target")
          if [[ -n "$fmode" && -n "$dst_mode" && "$fmode" != "$dst_mode" ]]; then
            add_change "CHMOD" "$rel"
          fi
        fi
        ;;
      l)
        source_link=$(readlink "$path" 2>/dev/null || true)
        if [[ ! -L "$target" ]]; then
          add_change "SYMLINK" "$rel"
        else
          target_link=$(readlink "$target" 2>/dev/null || true)
          [[ "$source_link" == "$target_link" ]] || add_change "SYMLINK" "$rel"
        fi
        ;;
      f)
        if ! path_exists_or_link "$target"; then
          add_change "CREATE" "$rel"
        elif [[ ! -f "$target" || -L "$target" ]]; then
          add_change "REPLACE" "$rel"
        else
          # One stat per target file for size + mode together (GNU); BSD fallback below.
          if tmeta=$(stat -c '%s %a' "$target" 2>/dev/null); then
            dst_size="${tmeta% *}"
            dst_mode="${tmeta#* }"
          else
            dst_size=$(stat -f '%z' "$target" 2>/dev/null || echo -2)
            dst_mode=$(stat -f '%Lp' "$target" 2>/dev/null || echo "")
          fi
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
    mapfile -d '' path_list < <(find "$src" -mindepth 1 \( "${prune_expr[@]}" \) -o -print0)
    for path in "${path_list[@]}"; do
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
        source_link=$(readlink "$path" 2>/dev/null || true)
        if [[ ! -L "$target" ]]; then
          add_change "SYMLINK" "$rel"
        else
          target_link=$(readlink "$target" 2>/dev/null || true)
          [[ "$source_link" == "$target_link" ]] || add_change "SYMLINK" "$rel"
        fi
      elif [[ -f "$path" ]]; then
        if ! path_exists_or_link "$target"; then
          add_change "CREATE" "$rel"
        elif [[ ! -f "$target" || -L "$target" ]]; then
          add_change "REPLACE" "$rel"
        else
          src_size=$(stat -c '%s' "$path" 2>/dev/null || stat -f '%z' "$path" 2>/dev/null || echo -1)
          dst_size=$(stat -c '%s' "$target" 2>/dev/null || stat -f '%z' "$target" 2>/dev/null || echo -2)
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
    mapfile -d '' path_list < <(find "$dst" -mindepth 1 -depth -print0)
    for path in "${path_list[@]}"; do
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

  info "Detected ${AC_BOLD}${AC_FG_BRIGHT_WHITE}$CHANGE_COUNT${AC_R} change(s). Summary:"
  while IFS=$'\t' read -r kind cnt; do
    printf '  %s  %s\n' "$(kind_label "$kind")" "$cnt"
  done < <(awk -F '\t' '{ count[${1:-}]++ } END { for (kind in count) printf "%s\t%d\n", kind, count[kind] }' "$CHANGES_FILE" | sort)
  printf '\n'
  info "Change preview (first $MAX_PREVIEW line(s)):"
  while IFS=$'\t' read -r kind rel; do
    printf '  %s  %s\n' "$(kind_label "$kind")" "${AC_DIM}${rel}${AC_R}"
  done < <(sed -n "1,${MAX_PREVIEW}p" "$CHANGES_FILE")
  local total
  total=$(wc -l <"$CHANGES_FILE" | tr -d ' ')
  if [[ "$total" -gt "$MAX_PREVIEW" ]]; then
    warn "Preview truncated: $((total - MAX_PREVIEW)) additional change(s) not shown."
  fi
}
filtered_git_dirty() {
  local dst="${1:-}"
  git -C "$dst" status --porcelain --untracked-files=normal 2>/dev/null | while IFS= read -r line; do
    local path="${line:3}"
    if should_exclude_rel "$path"; then
      continue
    fi
    printf '%s\n' "$line"
  done
}
check_git_safety() {
  local dst="${1:-}"
  if git -C "$dst" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local dirty
    dirty=$(filtered_git_dirty "$dst")
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
  cp "$CHANGES_FILE" "${backup_file}.changes.txt" 2>/dev/null || true
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
    rm -rf "$target_path" 2>/dev/null || true
    cp -P "$source_path" "$target_path" || return 1
  elif [[ -f "$source_path" ]]; then
    mkdir -p "$target_parent" || return 1
    if path_exists_or_link "$target_path"; then
      if [[ -d "$target_path" && ! -L "$target_path" ]]; then
        rm -rf "$target_path" || return 1
      elif [[ ! -w "$target_path" ]]; then
        chmod u+w "$target_path" 2>/dev/null || rm -f "$target_path" 2>/dev/null || true
      fi
    fi
    # Use cp -a for highest fidelity (xattrs/ACLs/timestamps), fallback smoothly to cp -p
    cp -a "$source_path" "$target_path" 2>/dev/null || cp -p "$source_path" "$target_path" || return 1
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
  info "Extracting backup archive '$BACKUP_FILE' back into '$parent'..."
  log_action "Executing emergency auto-rollback from $BACKUP_FILE"
  if tar -xzf "$BACKUP_FILE" -C "$parent"; then
    info "${AC_BOLD}${AC_FG_BRIGHT_GREEN}✔ Emergency auto-rollback completed successfully!${AC_R} Target directory '$TARGET_DIR' has been fully restored to its exact pre-sync pristine state."
    log_action "Emergency auto-rollback successful."
    exit 1
  else
    fail "Fatal: Failed to fully extract backup archive during emergency auto-rollback! Please inspect '$parent' and '$BACKUP_FILE'."
  fi
}
apply_changes() {
  local src="${1:-}" dst="${2:-}" line kind rel target_path applied=0

  APPLY_IN_PROGRESS=1
  log_action "Beginning active apply of $CHANGE_COUNT changes."

  while IFS=$'\t' read -r kind rel; do
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
          chmod u+w "$target_path" 2>/dev/null || true
        fi
        rm -rf "$target_path" 2>/dev/null || handle_apply_failure "$kind" "$rel"
      fi
      ;;
    *)
      fail "Internal error: unknown change kind '$kind' for '$rel'"
      ;;
    esac
    applied=$((applied + 1))
  done <"$CHANGES_FILE"

  APPLY_IN_PROGRESS=0
  info "Applied ${AC_BOLD}${AC_FG_BRIGHT_WHITE}$applied${AC_R} change(s)."
  log_action "Successfully applied all $applied changes."
}
# Argument parsing & execution entry point -
ac_main() {
  uk_banner "apply-changes" "Directory sync with dry-run preview, backup, and rollback" "" "$@"
  _setup_colors
  trap 'cleanup_and_trap EXIT' EXIT
  trap 'cleanup_and_trap SIGINT' SIGINT
  trap 'cleanup_and_trap SIGTERM' SIGTERM
  trap 'cleanup_and_trap SIGHUP' SIGHUP

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
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    log_action "=== Synchronization Script Started (${MODE^^} Mode) ==="
    log_action "Source: $SOURCE_DIR"
    log_action "Target: $TARGET_DIR"
  fi

  acquire_lock

  TEMP_BASE="$(get_temp_dir)"
  CHANGES_FILE=$(mktemp "$TEMP_BASE/apply_changes.XXXXXX" 2>/dev/null || echo "$TEMP_BASE/apply_changes.$$.tmp")
  touch "$CHANGES_FILE" 2>/dev/null || CHANGES_FILE="./apply_changes.$$.tmp"
  : >"$CHANGES_FILE" || fail "CRITICAL: Unable to create temporary plan file '$CHANGES_FILE'. Please verify your filesystem permissions."
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

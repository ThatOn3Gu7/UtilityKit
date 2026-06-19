#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

DJ_APPLY=0
DJ_CONTAINERS=0
DJ_IMAGES=0
DJ_VOLUMES=0
DJ_ALL=0

dj_usage() {
  cat <<USAGE
Usage:
  _docker_janitor.sh [OPTIONS]

Options:
  --containers   Prune stopped containers.
  --images       Prune dangling images.
  --volumes      Prune dangling volumes.
  --all          Select all prune categories.
  --apply        Execute pruning operations.
  -h, --help     Show help.
USAGE
}

dj_check() {
  uk_has_cmd docker || { uk_error 'docker command not found.'; return 1; }
  docker info >/dev/null 2>&1 || { uk_error 'Docker daemon is not reachable.'; return 1; }
}

dj_count() {
  docker "$@" 2>/dev/null | awk 'NF{c++} END{print c+0}'
}

dj_preview() {
  uk_header 'UtilityKit Docker Janitor' 'Stopped containers, dangling images, and orphaned volumes'
  printf 'Stopped containers : %s\n' "$(dj_count ps -aq -f status=exited)"
  printf 'Dangling images    : %s\n' "$(dj_count images -q -f dangling=true)"
  printf 'Dangling volumes   : %s\n' "$(dj_count volume ls -qf dangling=true)"
  printf '\n'
  docker system df 2>/dev/null || true
}

dj_run() {
  (( DJ_ALL == 1 )) && DJ_CONTAINERS=1 DJ_IMAGES=1 DJ_VOLUMES=1
  (( DJ_CONTAINERS == 1 )) && {
    if (( DJ_APPLY == 1 )); then docker container prune -f; else uk_note 'Would prune stopped containers.'; fi
  }
  (( DJ_IMAGES == 1 )) && {
    if (( DJ_APPLY == 1 )); then docker image prune -f; else uk_note 'Would prune dangling images.'; fi
  }
  (( DJ_VOLUMES == 1 )) && {
    if (( DJ_APPLY == 1 )); then docker volume prune -f; else uk_note 'Would prune dangling volumes.'; fi
  }
}

dj_interactive() {
  dj_preview
  uk_confirm 'Prune stopped containers?' 'Y' && DJ_CONTAINERS=1
  uk_confirm 'Prune dangling images?' 'Y' && DJ_IMAGES=1
  uk_confirm 'Prune dangling volumes?' 'N' && DJ_VOLUMES=1
  uk_confirm 'Apply pruning now?' 'N' && DJ_APPLY=1
  dj_run
}

dj_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --containers) DJ_CONTAINERS=1 ;;
      --images) DJ_IMAGES=1 ;;
      --volumes) DJ_VOLUMES=1 ;;
      --all) DJ_ALL=1 ;;
      --apply) DJ_APPLY=1 ;;
      -h|--help) dj_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done
  dj_check
  if (( DJ_CONTAINERS + DJ_IMAGES + DJ_VOLUMES + DJ_ALL == 0 )); then
    dj_interactive
  else
    dj_preview
    dj_run
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then dj_main "$@"; fi

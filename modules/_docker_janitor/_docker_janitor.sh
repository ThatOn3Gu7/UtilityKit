#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

DJ_APPLY=0
DJ_CONTAINERS=0
DJ_IMAGES=0
DJ_VOLUMES=0
DJ_ALL=0

# Fallback uk_confirm if not defined in uk_common.sh
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local prompt="${1:-}" default="${2:-}"
    local answer
    printf '%s [%s/%s]: ' "$prompt" "$([[ "$default" == "Y" ]] && echo "Y" || echo "y")" \
      "$([[ "$default" == "N" ]] && echo "N" || echo "n")" >&2
    read -r answer
    case "$answer" in
    Y | y) return 0 ;;
    N | n) return 1 ;;
    *) [[ "$default" == "Y" || "$default" == "y" ]] && return 0 || return 1 ;;
    esac
  }
fi
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
  uk_has_cmd docker || {
    uk_error 'docker command not found.'
    return 1
  }
  if ! docker info >/dev/null 2>&1; then
    uk_error 'Docker daemon is not reachable. Is Docker running? Do you have permissions?'
    return 1
  fi
  return 0
}
dj_count() {
  # Print count of items from a docker command
  local count
  count=$(docker "$@" 2>&1 | awk 'NF{c++} END{print c+0}')
  echo "$count"
}
dj_preview() {

  local containers images volumes
  containers="$(dj_count ps -aq -f status=exited)"
  images="$(dj_count images -q -f dangling=true)"
  volumes="$(dj_count volume ls -qf dangling=true)"

  printf '  %s%sStopped containers%s  %s%s%s  %s(exited and no longer running)%s\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$containers" "$UK_C_RESET" \
    "$UK_C_DIM" "$UK_C_RESET"
  printf '  %s%sDangling images%s     %s%s%s  %s(untagged layers with no active reference)%s\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$images" "$UK_C_RESET" \
    "$UK_C_DIM" "$UK_C_RESET"
  printf '  %s%sDangling volumes%s    %s%s%s  %s(volumes no longer attached to any container)%s\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$volumes" "$UK_C_RESET" \
    "$UK_C_DIM" "$UK_C_RESET"

  printf '\n  %sDisk usage summary:%s\n' "$UK_C_DIM" "$UK_C_RESET"
  if docker system df 2>/dev/null; then
    docker system df 2>/dev/null | sed 's/^/  /'
  else
    printf '  %sCould not retrieve disk usage summary.%s\n' "$UK_C_YELLOW" "$UK_C_RESET"
  fi
}
dj_run() {
  ((DJ_ALL == 1)) && DJ_CONTAINERS=1 DJ_IMAGES=1 DJ_VOLUMES=1

  if ((DJ_CONTAINERS == 1)); then
    if ((DJ_APPLY == 1)); then
      docker container prune -f
    else
      uk_note 'Would prune stopped containers (dry‑run).'
    fi
  fi
  if ((DJ_IMAGES == 1)); then
    if ((DJ_APPLY == 1)); then
      docker image prune -f
    else
      uk_note 'Would prune dangling images (dry‑run).'
    fi
  fi
  if ((DJ_VOLUMES == 1)); then
    if ((DJ_APPLY == 1)); then
      docker volume prune -f
    else
      uk_note 'Would prune dangling volumes (dry‑run).'
    fi
  fi
  if ((DJ_APPLY == 1)); then
    uk_success 'Prune operations completed.'
  fi
}
dj_interactive() {
  dj_preview
  printf '\n'
  uk_note 'Select which resources to prune. Nothing is deleted until you confirm at the end.'
  printf '\n'

  uk_confirm 'Prune stopped containers? (removes exited containers — images and volumes are untouched)' 'Y' && DJ_CONTAINERS=1
  uk_confirm 'Prune dangling images? (removes untagged image layers — named images are safe)' 'Y' && DJ_IMAGES=1
  uk_confirm 'Prune dangling volumes? (removes volumes with no container — data inside will be lost)' 'N' && DJ_VOLUMES=1

  printf '\n'
  uk_confirm 'Apply all selected prune operations now? (this is permanent and cannot be undone)' 'N' && DJ_APPLY=1
  dj_run
}
dj_main() {
  uk_banner "docker-janitor" "Prune stopped containers, dangling images, and orphan volumes" "" "$@"
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --containers) DJ_CONTAINERS=1 ;;
    --images) DJ_IMAGES=1 ;;
    --volumes) DJ_VOLUMES=1 ;;
    --all) DJ_ALL=1 ;;
    --apply) DJ_APPLY=1 ;;
    -h | --help)
      dj_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  dj_check || return 1

  if ((DJ_CONTAINERS + DJ_IMAGES + DJ_VOLUMES + DJ_ALL == 0)); then
    dj_interactive
  else
    dj_preview
    dj_run
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  dj_main "$@"
fi


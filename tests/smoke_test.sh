#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

run_test() {
  local name="$1"
  shift
  printf '== %s ==\n' "$name"
  if "$@"; then
    PASS=$((PASS+1))
  else
    FAIL=$((FAIL+1))
    printf 'FAILED: %s\n' "$name" >&2
  fi
  printf '\n'
}

syntax_check() {
  local f
  while IFS= read -r -d '' f; do
    bash -n "$f"
  done < <(find "$ROOT" -type f -name '*.sh' -print0)
}

help_check() {
  bash "$ROOT/main.sh" help >/dev/null
  bash "$ROOT/setup.sh" --help >/dev/null
  local cmds=(apply rename cacheclean symlink disk env git docker scaffold dup logs proc port ssl api pass ssh shred media toc pomodoro cheat zen)
  local cmd
  for cmd in "${cmds[@]}"; do
    bash "$ROOT/main.sh" "$cmd" --help >/dev/null || return 1
  done
}

core_smoke() {
  mkdir -p "$TMP/src/sub" "$TMP/dst/sub"
  printf 'new\n' > "$TMP/src/a.txt"
  printf 'nested\n' > "$TMP/src/sub/b.txt"
  printf 'old\n' > "$TMP/dst/a.txt"
  printf 'old file\n' > "$TMP/dst/obsolete.txt"
  NO_COLOR=1 bash "$ROOT/_apply_changes/_apply_changes.sh" --apply --yes --mirror "$TMP/src" "$TMP/dst" >/dev/null
  [[ -f "$TMP/dst/sub/b.txt" && ! -f "$TMP/dst/obsolete.txt" ]]

  mkdir -p "$TMP/rename_src"
  printf '1' > "$TMP/rename_src/file.js"
  printf '#keep' > "$TMP/rename_src/README.md"
  mkdir -p "$TMP/rename_out"
  NO_COLOR=1 bash "$ROOT/_rename_batch/_rename_batch.sh" "$TMP/rename_src" txt "$TMP/rename_out" >/dev/null
  [[ -f "$TMP/rename_out/file.txt" && ! -f "$TMP/rename_out/README.txt" ]]

  mkdir -p "$TMP/links"
  printf 'config' > "$TMP/original.conf"
  printf 'old' > "$TMP/links/app.conf"
  NO_COLOR=1 bash "$ROOT/_symlink_manager/_symlink_manager.sh" --apply -y "$TMP/original.conf" "$TMP/links/app.conf" >/dev/null
  [[ -L "$TMP/links/app.conf" ]]

  printf '0\n' | NO_COLOR=1 bash "$ROOT/_disk_analyzer/_disk_analyzer.sh" --count 2 "$TMP" >/dev/null
  NO_COLOR=1 bash "$ROOT/_cache_clean/_cache_clean.sh" --help >/dev/null
}

roadmap_smoke() {
  mkdir -p "$TMP/envproj"
  cat > "$TMP/envproj/.env.example" <<EOF
API_URL=
TOKEN=
EOF
  cat > "$TMP/envproj/.env.local" <<EOF
API_URL=http://localhost
TOKEN=abc
EOF
  cp "$TMP/envproj/.env.local" "$TMP/envproj/.env"
  bash "$ROOT/_env_manager/_env_manager.sh" --dir "$TMP/envproj" --compare >/dev/null
  bash "$ROOT/_env_manager/_env_manager.sh" --dir "$TMP/envproj" --validate >/dev/null

  mkdir -p "$TMP/gitrepo"
  git -C "$TMP/gitrepo" init -q
  git -C "$TMP/gitrepo" config user.email test@example.com
  git -C "$TMP/gitrepo" config user.name tester
  printf 'root\n' > "$TMP/gitrepo/file.txt"
  git -C "$TMP/gitrepo" add . && git -C "$TMP/gitrepo" commit -qm init
  local base_branch
  base_branch=$(git -C "$TMP/gitrepo" rev-parse --abbrev-ref HEAD)
  git -C "$TMP/gitrepo" checkout -qb feat
  printf 'branch\n' >> "$TMP/gitrepo/file.txt"
  git -C "$TMP/gitrepo" commit -am 'feat' -q
  git -C "$TMP/gitrepo" checkout -q "$base_branch"
  git -C "$TMP/gitrepo" merge --no-ff -m 'merge feat' -q feat
  bash "$ROOT/_git_sweep/_git_sweep.sh" --repo "$TMP/gitrepo" --delete-merged-local >/dev/null

  bash "$ROOT/_project_scaffold/_project_scaffold.sh" --type bash --name demo --dest "$TMP" >/dev/null
  [[ -f "$TMP/demo/main.sh" ]]

  mkdir -p "$TMP/dupes"
  printf 'same' > "$TMP/dupes/a.txt"
  cp "$TMP/dupes/a.txt" "$TMP/dupes/b.txt"
  bash "$ROOT/_duplicate_finder/_duplicate_finder.sh" "$TMP/dupes" --delete --apply >/dev/null
  [[ -f "$TMP/dupes/a.txt" && ! -f "$TMP/dupes/b.txt" ]]

  mkdir -p "$TMP/logs"
  printf 'old log' > "$TMP/logs/app.log"
  touch -d '10 days ago' "$TMP/logs/app.log"
  bash "$ROOT/_log_rotator/_log_rotator.sh" --path "$TMP/logs" --older-than 1 --archive-dir "$TMP/archives" --apply >/dev/null
  find "$TMP/archives" -type f -name '*.tar.gz' | grep -q .

  sleep 20 &
  local sleeper=$!
  bash "$ROOT/_process_killer/_process_killer.sh" --pid "$sleeper" --signal TERM >/dev/null
  wait "$sleeper" 2>/dev/null || true

  python3 -m http.server 8765 --directory "$TMP" >/dev/null 2>&1 &
  local server=$!
  sleep 1
  bash "$ROOT/_port_inspector/_port_inspector.sh" 8765 >/dev/null || true
  kill "$server" 2>/dev/null || true

  bash "$ROOT/_ssl_checker/_ssl_checker.sh" --help >/dev/null

  python3 -m http.server 8766 --directory "$TMP" >/dev/null 2>&1 &
  local api_server=$!
  sleep 1
  bash "$ROOT/_api_tester/_api_tester.sh" --method GET --url http://127.0.0.1:8766 >/dev/null
  kill "$api_server" 2>/dev/null || true

  bash "$ROOT/_password_gen/_password_gen.sh" --mode passphrase >/dev/null

  mkdir -p "$TMP/home/.ssh"
  cat > "$TMP/home/.ssh/config" <<EOF
Host demo-host
  HostName example.com
EOF
  HOME="$TMP/home" bash "$ROOT/_ssh_assistant/_ssh_assistant.sh" >/dev/null

  printf 'secret' > "$TMP/secret.txt"
  bash "$ROOT/_shredder/_shredder.sh" --apply "$TMP/secret.txt" >/dev/null
  [[ ! -f "$TMP/secret.txt" ]]

  bash "$ROOT/_media_convert/_media_convert.sh" --help >/dev/null

  mkdir -p "$TMP/md"
  printf '# Title\n\n## Section\n\n|a|bb|\n|-|-|\n|1|22|\n\n[doc](ref.txt)\n' > "$TMP/md/doc.md"
  printf 'ref' > "$TMP/md/ref.txt"
  bash "$ROOT/_markdown_toc/_markdown_toc.sh" "$TMP/md/doc.md" --apply --check-links --align-tables >/dev/null
  grep -q 'utilitykit:toc:start' "$TMP/md/doc.md"

  bash "$ROOT/_pomodoro/_pomodoro.sh" --work 1 --break 1 --cycles 1 --unit seconds --no-bell >/dev/null

  bash "$ROOT/_cheat_sheet/_cheat_sheet.sh" --add demo --text 'docker logs -f app' --tags docker,logs >/dev/null
  bash "$ROOT/_cheat_sheet/_cheat_sheet.sh" --search docker >/dev/null

  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/_zen_mode/_zen_mode.sh" --mode waves --duration 1 >/dev/null
}

run_test 'Syntax check' syntax_check
run_test 'Help / routing coverage' help_check
run_test 'Core tool smoke tests' core_smoke
run_test 'Roadmap tool smoke tests' roadmap_smoke

printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
(( FAIL == 0 ))

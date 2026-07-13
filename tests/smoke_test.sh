#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

run_test() {
  local name="${1:-}"
  shift
  printf '== %s ==\n' "$name"
  if "$@"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
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
  local cmds=(apply rename move cacheclean symlink disk env git docker scaffold dup proc port ssl api pass ssh shred media toc pomodoro cheat network cron dotenv disk-health service git-stats backup clipboard weather json tmux font toolbox search github links log-inspect csv hash archive snapshot open-files battery release license regex todo qr secret dns ipinfo uuid time bench yaml ytdl pdf image fwatch tunnel hooks installed)
  local cmd
  for cmd in "${cmds[@]}"; do
    bash "$ROOT/main.sh" "$cmd" --help >/dev/null || return 1
  done
}
core_smoke() {
  mkdir -p "$TMP/src/sub" "$TMP/dst/sub"
  printf 'new\n' >"$TMP/src/a.txt"
  printf 'nested\n' >"$TMP/src/sub/b.txt"
  printf 'old\n' >"$TMP/dst/a.txt"
  printf 'old file\n' >"$TMP/dst/obsolete.txt"
  NO_COLOR=1 bash "$ROOT/modules/_apply_changes/_apply_changes.sh" --apply --yes --mirror "$TMP/src" "$TMP/dst" >/dev/null
  [[ -f "$TMP/dst/sub/b.txt" && ! -f "$TMP/dst/obsolete.txt" ]]

  mkdir -p "$TMP/move_src/sub" "$TMP/move_out"
  printf 'alpha' >"$TMP/move_src/a.txt"
  printf 'skip' >"$TMP/move_src/sub/skip.md"
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_move_in_batch/_move_in_batch.sh" --target "$TMP/move_src" --output "$TMP/move_out" --exclude .md >/dev/null
  [[ -f "$TMP/move_out/a.txt" && ! -f "$TMP/move_out/sub/skip.md" ]]

  mkdir -p "$TMP/rename_src"
  printf '1' >"$TMP/rename_src/file.js"
  printf '#keep' >"$TMP/rename_src/README.md"
  mkdir -p "$TMP/rename_out"
  NO_COLOR=1 bash "$ROOT/modules/_rename_batch/_rename_batch.sh" "$TMP/rename_src" txt "$TMP/rename_out" >/dev/null
  [[ -f "$TMP/rename_out/file.txt" && ! -f "$TMP/rename_out/README.txt" ]]

  mkdir -p "$TMP/links"
  printf 'config' >"$TMP/original.conf"
  printf 'old' >"$TMP/links/app.conf"
  NO_COLOR=1 bash "$ROOT/modules/_symlink_manager/_symlink_manager.sh" --apply -y "$TMP/original.conf" "$TMP/links/app.conf" >/dev/null
  [[ -L "$TMP/links/app.conf" ]]

  printf '0\n' | NO_COLOR=1 bash "$ROOT/modules/_disk_analyzer/_disk_analyzer.sh" --count 2 "$TMP" >/dev/null
  NO_COLOR=1 bash "$ROOT/modules/_cache_clean/_cache_clean.sh" --help >/dev/null
}
roadmap_smoke() {
  mkdir -p "$TMP/envproj"
  cat >"$TMP/envproj/.env.example" <<EOF
API_URL=
TOKEN=
EOF
  cat >"$TMP/envproj/.env.local" <<EOF
API_URL=http://localhost
TOKEN=abc
EOF
  cp "$TMP/envproj/.env.local" "$TMP/envproj/.env"
  bash "$ROOT/modules/_env_manager/_env_manager.sh" --dir "$TMP/envproj" --compare >/dev/null
  bash "$ROOT/modules/_env_manager/_env_manager.sh" --dir "$TMP/envproj" --validate >/dev/null

  mkdir -p "$TMP/gitrepo"
  git -C "$TMP/gitrepo" init -q
  git -C "$TMP/gitrepo" config user.email test@example.com
  git -C "$TMP/gitrepo" config user.name tester
  printf 'root\n' >"$TMP/gitrepo/file.txt"
  git -C "$TMP/gitrepo" add . && git -C "$TMP/gitrepo" commit -qm init
  local base_branch
  base_branch=$(git -C "$TMP/gitrepo" rev-parse --abbrev-ref HEAD)
  git -C "$TMP/gitrepo" checkout -qb feat
  printf 'branch\n' >>"$TMP/gitrepo/file.txt"
  git -C "$TMP/gitrepo" commit -am 'feat' -q
  git -C "$TMP/gitrepo" checkout -q "$base_branch"
  git -C "$TMP/gitrepo" merge --no-ff -m 'merge feat' -q feat
  bash "$ROOT/modules/_git_sweep/_git_sweep.sh" --repo "$TMP/gitrepo" --delete-merged-local >/dev/null

  bash "$ROOT/modules/_project_scaffold/_project_scaffold.sh" --type bash --name demo --dest "$TMP" >/dev/null
  [[ -f "$TMP/demo/main.sh" ]]

  mkdir -p "$TMP/dupes"
  printf 'same' >"$TMP/dupes/a.txt"
  cp "$TMP/dupes/a.txt" "$TMP/dupes/b.txt"
  bash "$ROOT/modules/_duplicate_finder/_duplicate_finder.sh" "$TMP/dupes" --delete --apply >/dev/null
  [[ -f "$TMP/dupes/a.txt" && ! -f "$TMP/dupes/b.txt" ]]

  sleep 20 &
  local sleeper=$!
  bash "$ROOT/modules/_process_killer/_process_killer.sh" --pid "$sleeper" --signal TERM >/dev/null
  wait "$sleeper" 2>/dev/null || true

  python3 -m http.server 8765 --directory "$TMP" >/dev/null 2>&1 &
  local server=$!
  sleep 1
  bash "$ROOT/modules/_port_inspector/_port_inspector.sh" 8765 >/dev/null || true
  kill "$server" 2>/dev/null || true

  bash "$ROOT/modules/_ssl_checker/_ssl_checker.sh" --help >/dev/null

  python3 -m http.server 8766 --directory "$TMP" >/dev/null 2>&1 &
  local api_server=$!
  sleep 1
  bash "$ROOT/modules/_api_tester/_api_tester.sh" --method GET --url http://127.0.0.1:8766 >/dev/null
  kill "$api_server" 2>/dev/null || true

  bash "$ROOT/modules/_password_gen/_password_gen.sh" --mode passphrase >/dev/null

  mkdir -p "$TMP/home/.ssh"
  cat >"$TMP/home/.ssh/config" <<EOF
Host demo-host
  HostName example.com
EOF
  HOME="$TMP/home" bash "$ROOT/modules/_ssh_assistant/_ssh_assistant.sh" >/dev/null

  printf 'secret' >"$TMP/secret.txt"
  bash "$ROOT/modules/_shredder/_shredder.sh" --apply "$TMP/secret.txt" >/dev/null
  [[ ! -f "$TMP/secret.txt" ]]

  bash "$ROOT/modules/_media_convert/_media_convert.sh" --help >/dev/null

  mkdir -p "$TMP/md"
  printf '# Title\n\n## Section\n\n|a|bb|\n|-|-|\n|1|22|\n\n[doc](ref.txt)\n' >"$TMP/md/doc.md"
  printf 'ref' >"$TMP/md/ref.txt"
  bash "$ROOT/modules/_markdown_toc/_markdown_toc.sh" "$TMP/md/doc.md" --apply --check-links --align-tables >/dev/null
  grep -q 'utilitykit:toc:start' "$TMP/md/doc.md"

  bash "$ROOT/modules/_pomodoro/_pomodoro.sh" --work 1 --break 1 --cycles 1 --unit seconds --no-bell >/dev/null

  bash "$ROOT/modules/_cheat_sheet/_cheat_sheet.sh" --add demo --text 'docker logs -f app' --tags docker,logs >/dev/null
  bash "$ROOT/modules/_cheat_sheet/_cheat_sheet.sh" --search docker >/dev/null
}
new_tools_smoke() {
  printf '{"users":[{"name":"ada","id":1}],"ok":true}
' >"$TMP/data.json"
  bash "$ROOT/modules/_json_explorer/_json_explorer.sh" "$TMP/data.json" --path users.0.name | grep -q 'ada'

  printf '# Doc

[local](ref.txt)
' >"$TMP/doc.md"
  printf 'ref' >"$TMP/ref.txt"
  bash "$ROOT/modules/_link_checker/_link_checker.sh" "$TMP/doc.md" >/dev/null

  printf 'name,role
ada,dev
' >"$TMP/data.csv"
  bash "$ROOT/modules/_csv_toolkit/_csv_toolkit.sh" "$TMP/data.csv" --columns | grep -q name

  printf 'hello' >"$TMP/hash.txt"
  bash "$ROOT/modules/_hash_tools/_hash_tools.sh" "$TMP/hash.txt" | grep -q hash.txt

  bash "$ROOT/modules/_git_stats/_git_stats.sh" --repo "$ROOT" >/dev/null

  mkdir -p "$TMP/backup_src" "$TMP/backup_dst"
  printf 'copy' >"$TMP/backup_src/file.txt"
  bash "$ROOT/modules/_backup_sync/_backup_sync.sh" --source "$TMP/backup_src" --dest "$TMP/backup_dst" >/dev/null

  bash "$ROOT/modules/_project_search/_project_search.sh" --text 'UtilityKit' "$ROOT/README.md" >/dev/null || true
  bash "$ROOT/modules/_regex_lab/_regex_lab.sh" --pattern 'Util' --text 'UtilityKit' | grep -q Util
  bash "$ROOT/modules/_license_helper/_license_helper.sh" --generate mit --name Tester | grep -q 'MIT License'
  bash "$ROOT/modules/_toolbox_bootstrap/_toolbox_bootstrap.sh" >/dev/null
  bash "$ROOT/modules/_font_inspector/_font_inspector.sh" --glyphs >/dev/null
  bash "$ROOT/modules/_system_snapshot/_system_snapshot.sh" >/dev/null

  # --- _installed: PATH executables counted, JSON summary is well-formed
  local inst_out
  inst_out="$(NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_installed/_installed.sh" --commands --count 2>/dev/null)"
  printf '%s\n' "$inst_out" | grep -q 'unique command'
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_installed/_installed.sh" --commands --json 2>/dev/null | grep -q '"commands"'

  # --- _installed: version formatting renders "[ - name → vX ]" / "[ - name ]"
  local fmt_out
  fmt_out="$(cd "$ROOT" && bash -c 'source lib/uk_common.sh; source modules/_installed/_installed.sh; ic_format_pkg nvim 2.2.5; ic_format_pkg gobin ""; ic_format_pkg fzf v0.58.0' 2>/dev/null)"
  printf '%s\n' "$fmt_out" | grep -q '\[ - nvim → v2.2.5 \]'
  printf '%s\n' "$fmt_out" | grep -q '\[ - gobin \]'
  printf '%s\n' "$fmt_out" | grep -q '\[ - fzf → v0.58.0 \]'
}

wave1_tools_smoke() {
  # --- _qr_tool: help + graceful missing-encoder path
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_qr_tool/_qr_tool.sh" --help | grep -q 'Subcommands'

  # --- _clipboard_history: add + list + get + remove
  local CH_STORE="$TMP/clip_data/utilitykit/clipboard.jsonl"
  mkdir -p "$(dirname "$CH_STORE")"
  XDG_DATA_HOME="$TMP/clip_data" NO_COLOR=1 NO_UNICODE=1 \
    bash "$ROOT/modules/_clipboard_history/_clipboard_history.sh" add "alpha entry" >/dev/null
  XDG_DATA_HOME="$TMP/clip_data" NO_COLOR=1 NO_UNICODE=1 \
    bash "$ROOT/modules/_clipboard_history/_clipboard_history.sh" add "beta entry"  >/dev/null
  XDG_DATA_HOME="$TMP/clip_data" NO_COLOR=1 NO_UNICODE=1 \
    bash "$ROOT/modules/_clipboard_history/_clipboard_history.sh" list | grep -q 'beta entry'
  XDG_DATA_HOME="$TMP/clip_data" NO_COLOR=1 NO_UNICODE=1 \
    bash "$ROOT/modules/_clipboard_history/_clipboard_history.sh" show --last --no-clip | grep -q 'beta entry'
  XDG_DATA_HOME="$TMP/clip_data" NO_COLOR=1 NO_UNICODE=1 \
    bash "$ROOT/modules/_clipboard_history/_clipboard_history.sh" find alpha | grep -q 'alpha entry'

  # --- _secret_scan: finds a planted AWS key, exits 1
  mkdir -p "$TMP/secretproj"
  printf 'aws = "AKIAIOSFODNN7EXAMPLE"\n' >"$TMP/secretproj/config.rb"
  printf 'safe = 42\n' >>"$TMP/secretproj/config.rb"
  local rc=0
  NO_COLOR=1 NO_UNICODE=1 \
    bash "$ROOT/modules/_secret_scan/_secret_scan.sh" --path "$TMP/secretproj" \
      --no-entropy --no-gitignore >/dev/null 2>&1 || rc=$?
  [[ "$rc" -eq 1 ]]

  # --- _dns_probe: help works even without a backend (degrades gracefully)
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_dns_probe/_dns_probe.sh" --help | grep -q 'DOMAIN'

  # --- _ip_info: local-only report works even offline
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_ip_info/_ip_info.sh" --local --no-network >/dev/null
}

run_test 'Syntax check' syntax_check
run_test 'Help / routing coverage' help_check
run_test 'Core tool smoke tests' core_smoke
run_test 'Roadmap tool smoke tests' roadmap_smoke
run_test 'New utility smoke tests' new_tools_smoke
run_test 'Wave-1 tool smoke tests' wave1_tools_smoke

wave2_tools_smoke() {
  # --- _regex_lab: match and substitution
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_regex_lab/_regex_lab.sh" -p '\d+' -t 'hello 42 world 99' | grep -q '2 match'

  # --- _uuid_gen: generates a valid UUID v4
  local uuid_out
  uuid_out="$(NO_COLOR=1 bash "$ROOT/modules/_uuid_gen/_uuid_gen.sh" uuid4 2>/dev/null)"
  [[ "$uuid_out" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]

  # --- _uuid_gen: bulk count
  local count
  count="$(NO_COLOR=1 bash "$ROOT/modules/_uuid_gen/_uuid_gen.sh" short --count 5 2>/dev/null | grep -c . || true)"
  [[ "$count" -eq 5 ]]

  # --- _time_convert: now works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_time_convert/_time_convert.sh" now | grep -q 'Epoch'

  # --- _time_convert: epoch conversion
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_time_convert/_time_convert.sh" epoch 1700000000 | grep -q 'ISO 8601'

  # --- _http_bench: help works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_http_bench/_http_bench.sh" --help | grep -q 'requests'

  # --- _yaml_toolkit: lint validates YAML
  printf 'key: value\n' >"$TMP/test.yaml"
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_yaml_toolkit/_yaml_toolkit.sh" lint "$TMP/test.yaml" | grep -q 'Valid'

  # --- _pdf_toolkit: help works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_pdf_toolkit/_pdf_toolkit.sh" --help | grep -q 'Usage'

  # --- _image_tool: help works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_image_tool/_image_tool.sh" --help | grep -q 'Usage'

  # --- _file_watcher: help works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_file_watcher/_file_watcher.sh" --help | grep -q 'Usage'
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/main.sh" fwatch --help | grep -q 'Usage'

  # --- _ssh_tunnel: help works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_ssh_tunnel/_ssh_tunnel.sh" --help | grep -q 'Usage'

  # --- _git_hooks: help works
  NO_COLOR=1 NO_UNICODE=1 bash "$ROOT/modules/_git_hooks/_git_hooks.sh" --help | grep -q 'Usage'
}

run_test 'Wave-2 tool smoke tests' wave2_tools_smoke

apply_interactive_test() {
  # 1) Non-TTY guard: the interactive picker must abort fast (non-zero), never hang.
  bash "$ROOT/main.sh" apply -i </dev/null >/dev/null 2>&1
  [[ $? -ne 0 ]] || return 1

  # 2) Drive the real picker through a pty: pick src, pick dst, then apply.
  #    Skip gracefully when `script` (util-linux) is unavailable.
  script -c 'true' /dev/null >/dev/null 2>&1 || { return 0; }
  mkdir -p "$TMP/ihome/src/sub" "$TMP/ihome/dst"
  printf 'v2\n' >"$TMP/ihome/src/new.txt"
  printf 'old\n' >"$TMP/ihome/dst/old.txt"
  # Keys: filter "src" -> descend -> select current; filter "dst" -> descend -> select; confirm.
  local keys=$'/src\n\e[B\e[B\ns/dst\n\e[B\e[B\ns\n'
  local cmd="HOME='$TMP/ihome' NO_COLOR=1 bash '$ROOT/main.sh' apply -i"
  script -qec "$cmd" /dev/null <<<"$keys" >/dev/null 2>&1 || true
  [[ -f "$TMP/ihome/dst/new.txt" ]] || return 1
  [[ "$(cat "$TMP/ihome/dst/new.txt")" == "v2" ]] || return 1
  return 0
}

run_test 'apply-changes interactive guard + picker' apply_interactive_test

printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
((FAIL == 0))

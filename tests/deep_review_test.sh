#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass(){ printf 'PASS %s\n' "$1"; PASS=$((PASS+1)); }
fail(){ printf 'FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
run_test(){ local name="$1"; shift; if "$@"; then pass "$name"; else fail "$name"; fi; }

all_sh_files(){ (cd "$ROOT" && rg --files -g '*.sh' | sort); }

t_syntax(){
  (cd "$ROOT" && bash -n $(all_sh_files)) >/tmp/uk_deep_syntax.out 2>&1
}

t_source_safety(){
  local f
  while IFS= read -r f; do
    case "$f" in tests/*|setup.sh|main.sh|lib/uk_common.sh|_cache_clean/plugins/*) continue;; esac
    (cd "$ROOT" && bash -c 'source lib/uk_common.sh; C_RESET="sentinel-reset"; C_GREEN="sentinel-green"; UK_C_RESET="sentinel-uk"; source "$1" >/dev/null; [[ "$C_RESET" == "sentinel-reset" && "$C_GREEN" == "sentinel-green" && "$UK_C_RESET" == "sentinel-uk" ]]' _ "$f") || return 1
  done < <(all_sh_files)
}

t_password_entropy(){
  local out
  out="$(cd "$ROOT" && bash -c 'source lib/uk_common.sh; source _password_gen/_password_gen.sh; pg_main --mode passphrase --words 4' 2>/dev/null)" || return 1
  grep -Eq 'Entropy[[:space:]]*:.*~20\.[0-9]+ bits' <<<"$out" && ! grep -q '~93' <<<"$out"
}

t_weather_url(){
  local out
  out="$(cd "$ROOT" && bash -c 'source lib/uk_common.sh; source _weather/_weather.sh; curl(){ printf "%s\n" "$*"; }; wt_main "New York" --units metric' 2>/dev/null)" || return 1
  grep -q 'New+York' <<<"$out" && ! grep -q 'New York' <<<"$out"
}

t_license_detect(){
  local tmp out1 out2
  tmp="$(mktemp -d)" || return 1
  out1="$(cd "$tmp" && bash -c 'source "'$ROOT'/lib/uk_common.sh"; source "'$ROOT'/_license_helper/_license_helper.sh"; lic_main --detect' 2>&1)"
  : > "$tmp/LICENSE"
  out2="$(cd "$tmp" && bash -c 'source "'$ROOT'/lib/uk_common.sh"; source "'$ROOT'/_license_helper/_license_helper.sh"; lic_main --detect' 2>&1)"
  rm -rf "$tmp"
  grep -q 'No license file' <<<"$out1" && ! grep -q 'No license file' <<<"$out2"
}

t_todo_done_empty(){
  local tmp out rc
  tmp="$(mktemp -d)" || return 1
  out="$(XDG_DATA_HOME="$tmp/data" bash -c 'source "'$ROOT'/lib/uk_common.sh"; source "'$ROOT'/_todo_manager/_todo_manager.sh"; td_main --done ""' 2>&1)"; rc=$?
  rm -rf "$tmp"
  [[ $rc -ne 0 ]] && grep -q 'positive integer' <<<"$out"
}

t_todo_done_valid(){
  local tmp f
  tmp="$(mktemp -d)" || return 1
  XDG_DATA_HOME="$tmp/data" bash -c 'source "'$ROOT'/lib/uk_common.sh"; source "'$ROOT'/_todo_manager/_todo_manager.sh"; td_main --add "write tests" --tag qa; td_main --done 1' >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }
  f="$tmp/data/utilitykit/todos.tsv"
  grep -q '^done' "$f"
  local rc=$?; rm -rf "$tmp"; return $rc
}

t_rename_color_preserve(){
  (cd "$ROOT" && bash -c 'C_RESET=$'"'"'\033[0m'"'"'; before="$C_RESET"; source _rename_batch/_rename_batch.sh >/dev/null; [[ "$C_RESET" == "$before" ]]')
}

t_prompt_scan(){
  # Command substitution is allowed because uk_prompt reads from /dev/tty and writes prompts to stderr.
  ! rg -n '\|.*uk_prompt|uk_prompt.*\|[[:space:]]*$' "$ROOT/main.sh" "$ROOT"/_*/_*.sh >/dev/null
}

t_stat_fallback(){
  local tmp out
  tmp="$(mktemp)" || return 1; printf 'abcde' > "$tmp"
  out="$(cd "$ROOT" && bash -c 'source _cache_clean/_cache_clean.sh; stat(){ return 1; }; cc_file_size "$1"' _ "$tmp")" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"; [[ "$out" == 5 ]]
}

t_termux_paths(){
  # Informational audit: permitted hardcoded paths are guarded/fallback paths in this codebase.
  ! rg -n '(^|[^!])(/usr/bin|/etc/)' "$ROOT" -g '*.sh' -g '!tests/deep_review_test.sh' >/dev/null
}

t_find_printf(){
  ! rg -n 'find .*-printf' "$ROOT" -g '*.sh' -g '!_rename_batch/_rename_batch.sh' -g '!tests/deep_review_test.sh' >/dev/null && rg -n 'if find .* -printf' "$ROOT/_rename_batch/_rename_batch.sh" >/dev/null
}

t_archive_traversal(){
  local tmp arc dest out rc
  tmp="$(mktemp -d)" || return 1; arc="$tmp/bad.tar"; dest="$tmp/out"
  python3 - <<PY
import tarfile, io
with tarfile.open('$arc','w') as t:
    data=b'bad'
    info=tarfile.TarInfo('../evil.txt')
    info.size=len(data)
    t.addfile(info, io.BytesIO(data))
PY
  out="$(cd "$ROOT" && bash -c 'source lib/uk_common.sh; source _archive_manager/_archive_manager.sh; am_main --extract "$1" --dest "$2"' _ "$arc" "$dest" 2>&1)"; rc=$?
  rm -rf "$tmp"
  [[ $rc -ne 0 ]] && grep -q 'unsafe paths' <<<"$out"
}

t_cron_validation(){
  local out rc
  out="$(cd "$ROOT" && bash -c 'source lib/uk_common.sh; source _cron_manager/_cron_manager.sh; crontab(){ if [[ "$1" == "-l" ]]; then return 1; fi; cat >/dev/null; }; cm_main --add "not a cron"' 2>&1)"; rc=$?
  [[ $rc -ne 0 ]] && grep -q 'Expected five cron fields' <<<"$out"
}

t_duplicate_empty(){
  local tmp out rc
  tmp="$(mktemp -d)" || return 1
  out="$(cd "$ROOT" && bash -c 'source lib/uk_common.sh; source _duplicate_finder/_duplicate_finder.sh; df_main "$1"' _ "$tmp" 2>&1)"; rc=$?
  rm -rf "$tmp"
  [[ $rc -eq 0 ]] && grep -qi 'No exact duplicates found' <<<"$out"
}

run_test 'syntax check' t_syntax
run_test 'sourcing safety preserves color variables' t_source_safety
run_test 'password entropy reflects 37-word list' t_password_entropy
run_test 'weather URL encodes spaces' t_weather_url
run_test 'license detect handles unmatched globs' t_license_detect
run_test 'todo --done rejects empty ID' t_todo_done_empty
run_test 'todo --done updates valid ID' t_todo_done_valid
run_test 'rename batch preserves C_RESET when sourced' t_rename_color_preserve
run_test 'uk_prompt is not piped' t_prompt_scan
run_test 'stat fallback reaches wc -c' t_stat_fallback
run_test 'Termux path portability audit' t_termux_paths
run_test 'find -printf portability audit' t_find_printf
run_test 'archive traversal is rejected' t_archive_traversal
run_test 'cron --add validates malformed entry' t_cron_validation
run_test 'duplicate finder handles empty directory' t_duplicate_empty
printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]

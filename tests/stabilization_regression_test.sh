#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

run_test() {
  local name="$1"; shift
  printf '== %s ==\n' "$name"
  if "$@"; then
    PASS=$((PASS + 1))
    printf 'PASS\n\n'
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL: %s\n\n' "$name" >&2
  fi
}

json_ok() { python3 -m json.tool >/dev/null; }

ssh_assistant_single_help() {
  local out
  out="$(NO_COLOR=1 bash "$ROOT/_ssh_assistant/_ssh_assistant.sh" --help)"
  [[ "$(grep -c '^Usage:' <<<"$out")" -eq 1 ]]
}

http_bench_json() {
  local out
  out="$(NO_COLOR=1 bash "$ROOT/_http_bench/_http_bench.sh" http://127.0.0.1:1 -n 1 -c 1 --json)"
  python3 - <<PY <<<"$out"
import json,sys
obj=json.load(sys.stdin)
assert obj['backend'] == 'curl'
assert obj['requests'] == 1
assert obj['completed'] == 1
PY
}

regex_lab_regressions() {
  NO_COLOR=1 bash "$ROOT/_regex_lab/_regex_lab.sh" -p '\\d+' -t 'hello 42 world 99' | grep -q '2 match'
  NO_COLOR=1 bash "$ROOT/_regex_lab/_regex_lab.sh" -p '(a)(b)' -t 'ab' --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["matches"][0]["captures"]["1"] == "a"'
  if NO_COLOR=1 bash "$ROOT/_regex_lab/_regex_lab.sh" -p '[' -t abc >/dev/null 2>&1; then return 1; fi
  NO_COLOR=1 bash "$ROOT/_regex_lab/_regex_lab.sh" -p '[0-9]+' -s '[N]' -t 'a1 b22' | grep -Fq 'a[N] b[N]'
}

yaml_merge_works() {
  printf 'a:\n  x: 1\n' >"$TMP/base.yml"
  printf 'a:\n  y: 2\nb: 3\n' >"$TMP/overlay.yml"
  NO_COLOR=1 bash "$ROOT/_yaml_toolkit/_yaml_toolkit.sh" merge "$TMP/base.yml" "$TMP/overlay.yml" >"$TMP/merged.yml"
  grep -q 'x: 1' "$TMP/merged.yml" && grep -q 'y: 2' "$TMP/merged.yml" && grep -q 'b: 3' "$TMP/merged.yml"
}

image_json_valid() {
  local img="$TMP/fake.png"
  printf x >"$img"
  NO_COLOR=1 bash "$ROOT/_image_tool/_image_tool.sh" info "$img" --json | python3 -m json.tool >/dev/null
}

secret_colon_filename_json() {
  local d="$TMP/sec"
  mkdir -p "$d"
  printf 'AWS=AKIA1234567890ABCDEF\nSECRET=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN\n' >"$d/a:b.env"
  set +e
  NO_COLOR=1 bash "$ROOT/_secret_scan/_secret_scan.sh" --path "$d" --no-entropy --json >"$TMP/secrets.jsonl"
  local rc=$?
  set -e
  [[ "$rc" -eq 1 ]]
  python3 - <<'PY' "$TMP/secrets.jsonl"
import json,sys
seen=False
for line in open(sys.argv[1], encoding='utf-8'):
    if not line.strip(): continue
    obj=json.loads(line)
    assert ':' in obj['file']
    assert 'AKIA1234567890ABCDEF' not in obj['match']
    seen=True
assert seen
PY
}

time_convert_regressions() {
  NO_COLOR=1 bash "$ROOT/_time_convert/_time_convert.sh" epoch 1700000000 --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["rfc3339"] and d["human"]'
  NO_COLOR=1 bash "$ROOT/_time_convert/_time_convert.sh" parse '2024-01-15T10:30:00Z' --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["iso"]'
  if NO_COLOR=1 bash "$ROOT/_time_convert/_time_convert.sh" diff 2024-01-01 >/dev/null 2>&1; then return 1; fi
  NO_COLOR=1 bash "$ROOT/_time_convert/_time_convert.sh" diff 2024-01-01 2024-01-02 --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["seconds"] == 86400'
}

api_tester_regressions() {
  if NO_COLOR=1 bash "$ROOT/_api_tester/_api_tester.sh" --url http://127.0.0.1:1 >/"$TMP/api.out" 2>"$TMP/api.err"; then return 1; fi
  grep -q 'curl failed' "$TMP/api.err"
  NO_COLOR=1 bash "$ROOT/_api_tester/_api_tester.sh" --url http://127.0.0.1:1 --header 'Authorization: Bearer SECRET' >/"$TMP/api_header.out" 2>/dev/null || true
  grep -q 'Authorization: <redacted>' "$TMP/api_header.out" && ! grep -q 'SECRET' "$TMP/api_header.out"
  local data="$TMP/api-data"
  mkdir -p "$data"
  XDG_DATA_HOME="$data" NO_COLOR=1 bash "$ROOT/_api_tester/_api_tester.sh" --save prof --method GET --url http://example.com --expect 2xx >/dev/null
  XDG_DATA_HOME="$data" NO_COLOR=1 bash "$ROOT/_api_tester/_api_tester.sh" --show prof | python3 -m json.tool >/dev/null
}

env_compare_missing_fails() {
  if NO_COLOR=1 bash "$ROOT/_env_manager/_env_manager.sh" --dir "$TMP/nope" --compare >/dev/null 2>"$TMP/env.err"; then return 1; fi
  grep -q 'Missing active env file' "$TMP/env.err"
}

todo_out_of_range_fails() {
  local data="$TMP/todo-data"
  XDG_DATA_HOME="$data" NO_COLOR=1 bash "$ROOT/_todo_manager/_todo_manager.sh" --add 'write tests' >/dev/null
  if XDG_DATA_HOME="$data" NO_COLOR=1 bash "$ROOT/_todo_manager/_todo_manager.sh" --done 9 >/dev/null 2>"$TMP/todo.err"; then return 1; fi
  grep -q 'out of range' "$TMP/todo.err"
}

weather_help_plain() {
  NO_COLOR=1 bash "$ROOT/_weather/_weather.sh" --help >"$TMP/weather.help"
  ! grep -q '\\033' "$TMP/weather.help"
}

uuid_validation() {
  if NO_COLOR=1 bash "$ROOT/_uuid_gen/_uuid_gen.sh" short --len abc >/dev/null 2>"$TMP/uuid.err"; then return 1; fi
  grep -q -- '--len must' "$TMP/uuid.err"
  NO_COLOR=1 bash "$ROOT/_uuid_gen/_uuid_gen.sh" short --alphabet ab --len 12 --count 2 | awk 'length($0)==12 && $0 !~ /[^ab]/ {ok++} END{exit ok==2?0:1}'
}

ssh_tunnel_safety() {
  local cfg="$TMP/sshcfg"
  XDG_CONFIG_HOME="$cfg" NO_COLOR=1 bash "$ROOT/_ssh_tunnel/_ssh_tunnel.sh" list --json | python3 -m json.tool >/dev/null
  [[ "$(stat -c '%a' "$cfg/utilitykit/tunnels.conf" 2>/dev/null || stat -f '%Lp' "$cfg/utilitykit/tunnels.conf")" == "600" ]]
  if XDG_CONFIG_HOME="$cfg" NO_COLOR=1 bash "$ROOT/_ssh_tunnel/_ssh_tunnel.sh" create host:abc --name 'bad/name' >/dev/null 2>"$TMP/tunnel.err"; then return 1; fi
  grep -q 'Tunnel name' "$TMP/tunnel.err"
}

setup_launcher_validation() {
  if NO_COLOR=1 bash "$ROOT/setup.sh" --no-menu --launcher-name '../bad' --install-dir "$TMP/uk" --bin-dir "$TMP/bin" --no-path >/dev/null 2>"$TMP/setup.err"; then return 1; fi
  grep -q 'Invalid launcher name' "$TMP/setup.err"
}

run_test 'ssh assistant duplicate body removed' ssh_assistant_single_help
run_test 'http bench JSON no crash / sane counts' http_bench_json
run_test 'regex lab JSON/errors/substitution' regex_lab_regressions
run_test 'yaml merge works' yaml_merge_works
run_test 'image info emits valid JSON' image_json_valid
run_test 'secret scan handles colon filenames and redacts JSON' secret_colon_filename_json
run_test 'time convert JSON/parse/diff regressions' time_convert_regressions
run_test 'api tester failure status, redaction, JSON profiles' api_tester_regressions
run_test 'env compare missing files fails' env_compare_missing_fails
run_test 'todo out-of-range ID fails' todo_out_of_range_fails
run_test 'weather help has no literal ANSI escapes' weather_help_plain
run_test 'uuid validates length and custom alphabet' uuid_validation
run_test 'ssh tunnel validates config/name' ssh_tunnel_safety
run_test 'setup validates launcher name' setup_launcher_validation

printf 'PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]

#!/usr/bin/env bash
# scripts/gen_man.sh — Generate man(1) pages from _README.md files
#
# Converts every modules/_<tool>/_<tool>_README.md into
# man/utility-<tool>.1 using a hand-rolled awk converter (no pandoc needed).
# Run this whenever README files change, then commit the updated man/ dir.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAN_DIR="$UK_ROOT/man"

# shellcheck disable=SC1091
source "$UK_ROOT/lib/uk_common.sh"

mkdir -p "$MAN_DIR"

generated=0
skipped=0

for readme in "$UK_ROOT"/modules/_*/_*_README.md; do
  [[ -f "$readme" ]] || continue
  module_dir="$(dirname "$readme")"
  tool_key="$(basename "$module_dir")"
  tool_key="${tool_key#_}"

  man_file="$MAN_DIR/utility-${tool_key}.1"

  # Extract title (first # heading, stripped of alias like "(`cmd`)")
  title="$(head -20 "$readme" | awk '
    /^# / {
      s = substr($0,3)
      gsub(/^[[:space:]]+/,"",s)
      gsub(/ \(`[^)]*`\)/,"",s)
      print s
      exit
    }')"

  # Extract description (first non-blank non-heading line after title)
  desc="$(awk '
    /^# / { s=1; next }
    s && !/^$/ && !/^#/ && !/^-{3,}$/ { print; exit }
  ' "$readme")"

  # Derive synopsis action word from tool_key
  synopsis_action="${tool_key}"

  date_str="$(date '+%B %Y')"

  awk \
    -v tool_key="$tool_key" \
    -v title="$title" \
    -v desc="$desc" \
    -v synopsis_action="$synopsis_action" \
    -v date="$date_str" \
    -v version="$UK_VERSION" '
function inline(s) {
  while (match(s, /`[^`]+`/)) {
    s = substr(s,1,RSTART-1) "\\fC" substr(s,RSTART+1,RLENGTH-2) "\\fP" substr(s,RSTART+RLENGTH)
  }
  while (match(s, /\*\*[^*]+\*\*/)) {
    s = substr(s,1,RSTART-1) "\\fB" substr(s,RSTART+2,RLENGTH-4) "\\fP" substr(s,RSTART+RLENGTH)
  }
  while (match(s, /\*[^*]+\*/)) {
    s = substr(s,1,RSTART-1) "\\fI" substr(s,RSTART+1,RLENGTH-2) "\\fP" substr(s,RSTART+RLENGTH)
  }
  while (match(s, /\[[^]]*\]\([^)]*\)/)) {
    idx = index(substr(s, RSTART), "](")
    inner = substr(s, RSTART+1, idx-1)
    s = substr(s,1,RSTART-1) inner substr(s,RSTART+RLENGTH)
  }
  return s
}
BEGIN {
  print ".TH UTILITYKIT 1 \"" date "\" \"UtilityKit v" version "\" \"UtilityKit Tools\""
  print ".SH NAME"
  print "utility-" tool_key " \\- " desc
  print ".SH SYNOPSIS"
  print ".B utility " synopsis_action
  print "[\\fIoptions\\fP]"
  print ".SH DESCRIPTION"
  print desc
  body = 0
}
/^# / { next }
body == 0 && /^##[^#]/ { body = 1; s = substr($0,4); gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); print ".SH " toupper(s); next }
body == 0 { next }
/^```/ {
  if (code) { print ".EE"; code = 0 } else { print ".EX"; code = 1 }
  next
}
code { print; next }
/^##[^#]/ {
  s = substr($0,4); gsub(/^[[:space:]]+|[[:space:]]+$/,"",s)
  print ".SH " toupper(s)
  next
}
/^###[^#]/ {
  s = substr($0,5); gsub(/^[[:space:]]+|[[:space:]]+$/,"",s)
  print ".SS " s
  next
}
/^-{3,}$/ { print ".PP"; next }
/^$/ { print ".PP"; next }
/^>[[:space:]]/ { s = substr($0,3); $0 = s }
/^- / {
  s = substr($0, 3)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  print ".IP \\(bu 4"
  print inline(s)
  next
}
/^[0-9]+\. / {
  sub(/^[0-9]+\. /, "")
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
  print ".IP \\(em 4"
  print inline($0)
  next
}
/^\|/ {
  if ($0 ~ /^[-|: ]+$/) next
  gsub(/^\||\|$/, ""); gsub(/\|/, "  |  "); gsub(/^[[:space:]]+|[[:space:]]+$/, "")
  print inline($0)
  next
}
{ print inline($0) }' "$readme" > "$man_file"

  chmod 644 "$man_file"
  echo "  ✓ utility-${tool_key}.1  ($title)"
  generated=$((generated + 1))
done

echo ""
echo "Generated $generated man pages in $MAN_DIR"

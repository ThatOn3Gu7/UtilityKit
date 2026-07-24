#!/usr/bin/env bash
# _qr_tool — encode text/URL/Wi-Fi/vCard to QR (PNG or terminal ASCII); decode from image.
# Prefix: qr_
# Fallback chain (encode): qrencode  →  python3 qrcode  →  online segno service (curl, opt-in)
# Fallback chain (decode): zbarimg   →  python3 pyzbar
# Termux notes: qrencode + zbar available via `pkg install qrencode zbar`.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source the shared helpers.
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions (only used if _qr_tool.sh is executed standalone
#     without uk_common.sh available on disk). Keeps parity with sibling tools.
if ! declare -f uk_has_cmd >/dev/null 2>&1; then uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error   >/dev/null 2>&1; then uk_error()   { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn    >/dev/null 2>&1; then uk_warn()    { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info    >/dev/null 2>&1; then uk_info()    { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note    >/dev/null 2>&1; then uk_note()    { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner  >/dev/null 2>&1; then uk_banner()  { :; }; fi
if ! declare -f uk_prompt  >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''
    printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_expand_path >/dev/null 2>&1; then
  uk_expand_path() { local i="${1:-}"; printf '%s\n' "${i/#\~/$HOME}"; }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then echo macos
    else echo linux; fi
  }
fi
# --------------------------

qr_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_qr_tool.sh <subcommand> [OPTIONS]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Subcommands" \
    "encode --text TXT" "Encode arbitrary text/URL" \
    "encode --wifi SSID" "Encode Wi-Fi config (WPA/WPA2)" \
    "encode --vcard NAME" "Encode a minimal vCard 3.0" \
    "decode --image FILE" "Decode a QR image (PNG/JPG/GIF)"
  printf '\n'
  uk_help_section "$w" "Options" \
    "--out FILE" "Write PNG to FILE (encode). Default: print ASCII to terminal" \
    "--size" "Terminal ASCII size: SMALL or LARGE (default: SMALL)" \
    "--level L|M|Q|H" "Error-correction level (default: M)" \
    "--margin N" "Quiet-zone modules (default: 2)" \
    "--no-color" "Disable ANSI (also respects NO_COLOR=1)" \
    "--json" "Machine-readable output (decode subcommand)" \
    "-h, --help" "Show this help"
  printf '\n'
  uk_help_section "$w" "Backends" \
    "qrencode" "Primary encoder, falls back to python3-qrcode" \
    "zbarimg" "Primary decoder, falls back to python3-pyzbar"
  printf '\n'
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_qr_tool.sh${UK_C_RESET:-} ${UK_C_DIM:-}encode --text \"https://example.com\"${UK_C_RESET:-}" "Encode URL to QR" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_qr_tool.sh${UK_C_RESET:-} ${UK_C_DIM:-}encode --text \"hello\" --out qr.png${UK_C_RESET:-}" "Encode to PNG file" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_qr_tool.sh${UK_C_RESET:-} ${UK_C_DIM:-}encode --wifi HomeNet --psk hunter2 --enc WPA${UK_C_RESET:-}" "Encode Wi-Fi config" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_qr_tool.sh${UK_C_RESET:-} ${UK_C_DIM:-}encode --vcard \"Ada\" --email ada@ex.com${UK_C_RESET:-}" "Encode vCard" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_qr_tool.sh${UK_C_RESET:-} ${UK_C_DIM:-}decode --image qr.png --json${UK_C_RESET:-}" "Decode QR image"
}

# ---- Helpers ----------------------------------------------------------------

# Escape Wi-Fi / vCard reserved chars per WPA-Supplicant/QR conventions:
# backslash, semicolon, comma, colon, double quote get a leading backslash.
qr_esc_wifi() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//;/\\;}"
  s="${s//,/\\,}"
  s="${s//:/\\:}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

qr_detect_encoder() {
  if uk_has_cmd qrencode; then
    printf 'qrencode\n'
    return 0
  fi
  if uk_has_cmd python3 && python3 -c 'import qrcode' >/dev/null 2>&1; then
    printf 'python\n'
    return 0
  fi
  return 1
}

qr_detect_decoder() {
  if uk_has_cmd zbarimg; then
    printf 'zbarimg\n'
    return 0
  fi
  if uk_has_cmd python3 && python3 -c 'from pyzbar.pyzbar import decode' >/dev/null 2>&1; then
    printf 'pyzbar\n'
    return 0
  fi
  return 1
}

# Print a beautified separator with the given label.
qr_section() {
  local title="${1:-}"
  printf '\n%s%s%s\n' "${UK_C_BRIGHT_CYAN:-}${UK_C_BOLD:-}" "$title" "${UK_C_RESET:-}"
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}

# ---- Payload builders -------------------------------------------------------

qr_build_wifi_payload() {
  local ssid="$1" psk="${2:-}" enc="${3:-WPA}" hidden="${4:-false}"
  local esc_ssid esc_psk
  esc_ssid="$(qr_esc_wifi "$ssid")"
  esc_psk="$(qr_esc_wifi "$psk")"

  case "$enc" in
    WPA|WPA2|WPA3) enc='WPA' ;;
    WEP)           enc='WEP' ;;
    nopass|NONE|none|OPEN|open) enc='nopass' ;;
    *)
      uk_warn "Unknown --enc '$enc'; falling back to WPA."
      enc='WPA'
      ;;
  esac

  local out="WIFI:T:${enc};S:${esc_ssid};"
  [[ "$enc" != "nopass" ]] && out+="P:${esc_psk};"
  [[ "$hidden" == "true" ]] && out+="H:true;"
  out+=";"
  printf '%s' "$out"
}

qr_build_vcard_payload() {
  local name="$1" phone="${2:-}" email="${3:-}" org="${4:-}" title="${5:-}"
  local out='BEGIN:VCARD\nVERSION:3.0\n'
  out+="FN:${name}\n"
  [[ -n "$phone" ]] && out+="TEL;TYPE=CELL:${phone}\n"
  [[ -n "$email" ]] && out+="EMAIL:${email}\n"
  [[ -n "$org"   ]] && out+="ORG:${org}\n"
  [[ -n "$title" ]] && out+="TITLE:${title}\n"
  out+='END:VCARD'
  printf '%b' "$out"
}

# ---- Encode ----------------------------------------------------------------

qr_encode_qrencode() {
  local payload="$1" out="$2" level="$3" margin="$4" size="$5"
  local args=(-l "$level" -m "$margin")
  if [[ -n "$out" ]]; then
    args+=(-o "$out" -t PNG -s 8)
    printf '%s' "$payload" | qrencode "${args[@]}"
    return $?
  fi
  # Terminal output.
  if [[ "$size" == "LARGE" ]]; then
    args+=(-t ASCII)
  else
    # Prefer UTF-8 blocks; fall back to ANSIUTF8 if plain UTF-8 unsupported.
    args+=(-t UTF8)
  fi
  printf '%s' "$payload" | qrencode "${args[@]}"
}

qr_encode_python() {
  local payload="$1" out="$2" level="$3" margin="$4" size="$5"
  python3 - "$payload" "$out" "$level" "$margin" "$size" <<'PY'
import sys, os
try:
    import qrcode
except ImportError:
    print("[ERR] python 'qrcode' library not installed. pip install qrcode[pil]",
          file=sys.stderr); sys.exit(2)

payload, out, level, margin, size = sys.argv[1:6]
ec_map = {
    'L': qrcode.constants.ERROR_CORRECT_L,
    'M': qrcode.constants.ERROR_CORRECT_M,
    'Q': qrcode.constants.ERROR_CORRECT_Q,
    'H': qrcode.constants.ERROR_CORRECT_H,
}
ec = ec_map.get(level.upper(), qrcode.constants.ERROR_CORRECT_M)

qr = qrcode.QRCode(version=None, error_correction=ec,
                   box_size=8, border=int(margin))
qr.add_data(payload); qr.make(fit=True)

if out:
    try:
        img = qr.make_image(fill_color="black", back_color="white")
        img.save(out)
        print(f"[OK] wrote {out}")
    except Exception as e:
        print(f"[ERR] PNG write failed: {e}", file=sys.stderr); sys.exit(1)
else:
    # Terminal rendering. LARGE = 1 module per char, SMALL = half-block UTF-8.
    invert = False
    if size.upper() == 'LARGE':
        qr.print_ascii(invert=invert)
    else:
        # Half-block: two vertical modules per glyph — halves the width.
        matrix = qr.get_matrix()
        for y in range(0, len(matrix), 2):
            row = ''
            for x in range(len(matrix[y])):
                top = matrix[y][x]
                bot = matrix[y+1][x] if y+1 < len(matrix) else False
                row += ('█' if top and bot else
                        '▀' if top and not bot else
                        '▄' if not top and bot else ' ')
            print(row)
PY
}

qr_do_encode() {
  local payload="$1" out="$2" level="$3" margin="$4" size="$5"
  local encoder
  encoder="$(qr_detect_encoder 2>/dev/null || true)"
  if [[ -z "$encoder" ]]; then
    uk_error "No QR encoder found. Install one of:"
    printf '   %s* qrencode%s     (recommended, tiny native binary)\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    printf '   %s* pip install qrcode[pil]%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    case "$(uk_platform 2>/dev/null || echo unknown)" in
      termux) printf '   %sTermux:%s pkg install qrencode\n' "${UK_C_YELLOW:-}" "${UK_C_RESET:-}" ;;
      macos)  printf '   %smacOS:%s  brew install qrencode\n' "${UK_C_YELLOW:-}" "${UK_C_RESET:-}" ;;
      linux)  printf '   %sLinux:%s  apt install qrencode  |  dnf install qrencode\n' "${UK_C_YELLOW:-}" "${UK_C_RESET:-}" ;;
    esac
    return 2
  fi

  # If writing to file, make sure the parent dir exists.
  if [[ -n "$out" ]]; then
    local out_dir
    out_dir="$(dirname -- "$out")"
    [[ -d "$out_dir" ]] || mkdir -p "$out_dir" 2>/dev/null || {
      uk_error "Cannot create output directory: $out_dir"
      return 1
    }
  fi

  qr_section "QR encode"
  printf '  %sencoder:%s %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$encoder"
  printf '  %spayload:%s %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" \
    "$(printf '%s' "$payload" | head -c 80)$([[ ${#payload} -gt 80 ]] && printf '…')"
  printf '  %sbytes:  %s %d\n\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "${#payload}"

  case "$encoder" in
    qrencode) qr_encode_qrencode "$payload" "$out" "$level" "$margin" "$size" ;;
    python)   qr_encode_python   "$payload" "$out" "$level" "$margin" "$size" ;;
  esac
  local rc=$?

  if [[ "$rc" -eq 0 && -n "$out" ]]; then
    uk_success "wrote $out"
  elif [[ "$rc" -ne 0 ]]; then
    uk_error "encoder exited with status $rc"
  fi
  return "$rc"
}

# ---- Decode ----------------------------------------------------------------

qr_do_decode() {
  local image="$1" want_json="$2"
  if [[ ! -f "$image" ]]; then
    uk_error "Image not found: $image"
    return 1
  fi

  local decoder
  decoder="$(qr_detect_decoder 2>/dev/null || true)"
  if [[ -z "$decoder" ]]; then
    uk_error "No QR decoder found. Install one of:"
    printf '   %s* zbarimg  (from the zbar-tools package)%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    printf '   %s* pip install pyzbar pillow%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    return 2
  fi

  qr_section "QR decode"
  printf '  %sdecoder:%s %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$decoder"
  printf '  %simage:  %s %s\n\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$image"

  local raw
  case "$decoder" in
    zbarimg)
      raw="$(zbarimg -q --raw "$image" 2>/dev/null || true)"
      ;;
    pyzbar)
      raw="$(python3 - "$image" <<'PY'
import sys
try:
    from pyzbar.pyzbar import decode
    from PIL import Image
except ImportError as e:
    print(f"[ERR] {e}", file=sys.stderr); sys.exit(2)
img = Image.open(sys.argv[1])
for d in decode(img):
    print(d.data.decode('utf-8', 'replace'))
PY
)"
      ;;
  esac

  if [[ -z "$raw" ]]; then
    uk_warn 'No QR code detected in the image.'
    [[ "$want_json" == "1" ]] && printf '{"ok":false,"payloads":[]}\n'
    return 1
  fi

  if [[ "$want_json" == "1" ]]; then
    # Emit a JSON array without needing jq: rely on python3 if available,
    # otherwise a hand-rolled safe encoder.
    if uk_has_cmd python3; then
      printf '%s' "$raw" | python3 -c '
import sys, json
lines = [l for l in sys.stdin.read().splitlines() if l != ""]
print(json.dumps({"ok": True, "payloads": lines}, ensure_ascii=False))'
    else
      printf '{"ok":true,"payloads":['
      local first=1 line
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local esc="${line//\\/\\\\}"
        esc="${esc//\"/\\\"}"
        [[ $first -eq 1 ]] || printf ','
        printf '"%s"' "$esc"
        first=0
      done <<<"$raw"
      printf ']}\n'
    fi
  else
    local idx=1 line
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '  %s[%d]%s %s\n' "${UK_C_BRIGHT_CYAN:-}" "$idx" "${UK_C_RESET:-}" "$line"
      idx=$((idx + 1))
    done <<<"$raw"
  fi
  return 0
}

# ---- Main ------------------------------------------------------------------

qr_main() {
  # uk_banner ignores flags after the first three, so we pass "$@" for parity.
  uk_banner "qr-tool" "QR encode/decode: text · URL · Wi-Fi · vCard" "" "$@"

  local sub=""
  local text="" out="" level="M" margin="2" size="SMALL"
  local wifi_ssid="" wifi_psk="" wifi_enc="WPA" wifi_hidden="false"
  local vcard_name="" vcard_phone="" vcard_email="" vcard_org="" vcard_title=""
  local image="" want_json=0

  # Subcommand is optional but recommended. Default to "encode" if a --text
  # is given without a subcommand — nicer ergonomics from the wizard.
  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
      encode|decode) sub="$1"; shift ;;
      -h|--help)     qr_usage; return 0 ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --text)   shift; text="${1:-}" ;;
      --wifi)   shift; wifi_ssid="${1:-}" ;;
      --psk)    shift; wifi_psk="${1:-}" ;;
      --enc)    shift; wifi_enc="${1:-}" ;;
      --hidden) wifi_hidden="true" ;;
      --vcard)  shift; vcard_name="${1:-}" ;;
      --phone)  shift; vcard_phone="${1:-}" ;;
      --email)  shift; vcard_email="${1:-}" ;;
      --org)    shift; vcard_org="${1:-}" ;;
      --title)  shift; vcard_title="${1:-}" ;;
      --image)  shift; image="${1:-}" ;;
      --out)    shift; out="${1:-}" ;;
      --level)  shift; level="${1:-M}" ;;
      --margin) shift; margin="${1:-2}" ;;
      --size)   shift; size="${1:-SMALL}" ;;
      --json)   want_json=1 ;;
      --no-color) UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                  UK_C_YELLOW='' UK_C_BLUE='' UK_C_MAGENTA='' UK_C_CYAN=''
                  UK_C_BRIGHT_CYAN='' UK_C_BRIGHT_BLUE='' UK_C_WHITE='' ;;
      -h|--help) qr_usage; return 0 ;;
      *) uk_error "Unknown option: ${1:-}"; qr_usage; return 1 ;;
    esac
    shift || true
  done

  # Infer subcommand when possible.
  if [[ -z "$sub" ]]; then
    if [[ -n "$image" ]]; then
      sub="decode"
    elif [[ -n "$text$wifi_ssid$vcard_name" ]]; then
      sub="encode"
    else
      qr_usage
      return 1
    fi
  fi

  # Normalize error-correction level.
  case "${level^^}" in L|M|Q|H) level="${level^^}" ;; *)
    uk_warn "Invalid --level '$level'; using M."; level='M' ;;
  esac
  [[ "$margin" =~ ^[0-9]+$ ]] || { uk_warn "Invalid --margin; using 2."; margin=2; }
  case "${size^^}" in SMALL|LARGE) size="${size^^}" ;; *) size='SMALL' ;; esac

  case "$sub" in
    encode)
      local payload=""
      if   [[ -n "$text" ]];       then payload="$text"
      elif [[ -n "$wifi_ssid" ]];  then
        payload="$(qr_build_wifi_payload "$wifi_ssid" "$wifi_psk" "$wifi_enc" "$wifi_hidden")"
      elif [[ -n "$vcard_name" ]]; then
        payload="$(qr_build_vcard_payload "$vcard_name" "$vcard_phone" \
                    "$vcard_email" "$vcard_org" "$vcard_title")"
      else
        uk_error "encode requires --text, --wifi SSID, or --vcard NAME."
        return 1
      fi
      qr_do_encode "$payload" "$out" "$level" "$margin" "$size"
      ;;
    decode)
      [[ -z "$image" ]] && { uk_error "decode requires --image FILE"; return 1; }
      qr_do_decode "$image" "$want_json"
      ;;
    *)
      qr_usage
      return 1
      ;;
  esac
}

qr_wizard() {
  uk_banner "qr-tool" "QR encode/decode: text · URL · Wi-Fi · vCard" ""
  local mode text out level size ssid psk enc hidden name phone email image json

  mode="$(uk_prompt 'Action: text, url, wifi, vcard, or decode' 'text' \
    'text | url | wifi | vcard | decode' \
    'text/url encodes a plain string. wifi builds a Wi-Fi login QR. decode reads an image file.')"

  case "$mode" in
    text|url)
      text="$(uk_prompt 'Text or URL to encode' 'https://example.com' \
        'https://github.com' 'Any string works.')"
      out="$(uk_prompt 'Save PNG to file (blank = terminal ASCII)' '' \
        './qr.png' 'Leave blank to print a scannable QR in the terminal.')"
      level="$(uk_prompt 'Error-correction L/M/Q/H' 'M' 'H' 'H tolerates more damage but is denser.')"
      size="$(uk_prompt 'Terminal size SMALL or LARGE' 'SMALL' 'LARGE' 'LARGE = 1 module per char (more compatible).')"
      local -a a=(encode --text "$text" --level "$level" --size "$size")
      [[ -n "$out" ]] && a+=(--out "$(uk_expand_path "$out" 2>/dev/null || printf '%s' "$out")")
      qr_main "${a[@]}"
      ;;
    wifi)
      ssid="$(uk_prompt 'Wi-Fi SSID' 'HomeNet' 'MyNetwork' 'The network name broadcast by the AP.')"
      enc="$(uk_prompt 'Encryption WPA/WEP/nopass' 'WPA' 'WPA' 'Use nopass for open networks.')"
      psk=""
      [[ "$enc" != "nopass" ]] && psk="$(uk_prompt 'Passphrase' '' 'hunter2' 'Escape chars handled automatically.')"
      if uk_confirm 'Hidden SSID?' 'N'; then hidden="--hidden"; else hidden=""; fi
      out="$(uk_prompt 'Save PNG to file (blank = terminal)' '' './wifi.png' '')"
      local -a a=(encode --wifi "$ssid" --enc "$enc")
      [[ -n "$psk"    ]] && a+=(--psk "$psk")
      [[ -n "$hidden" ]] && a+=("$hidden")
      [[ -n "$out"    ]] && a+=(--out "$(uk_expand_path "$out" 2>/dev/null || printf '%s' "$out")")
      qr_main "${a[@]}"
      ;;
    vcard)
      name="$(uk_prompt 'Contact full name' 'Ada Lovelace' 'Ada Lovelace' 'Required.')"
      phone="$(uk_prompt 'Phone (blank to skip)' '' '555-0100' '')"
      email="$(uk_prompt 'Email (blank to skip)' '' 'ada@example.com' '')"
      out="$(uk_prompt 'Save PNG to file (blank = terminal)' '' './card.png' '')"
      local -a a=(encode --vcard "$name")
      [[ -n "$phone" ]] && a+=(--phone "$phone")
      [[ -n "$email" ]] && a+=(--email "$email")
      [[ -n "$out"   ]] && a+=(--out "$(uk_expand_path "$out" 2>/dev/null || printf '%s' "$out")")
      qr_main "${a[@]}"
      ;;
    decode)
      image="$(uk_prompt 'Path to QR image (PNG/JPG)' '' './qr.png' 'File must exist and contain at least one QR.')"
      if uk_confirm 'JSON output?' 'N'; then json="--json"; else json=""; fi
      local -a a=(decode --image "$(uk_expand_path "$image" 2>/dev/null || printf '%s' "$image")")
      [[ -n "$json" ]] && a+=("$json")
      qr_main "${a[@]}"
      ;;
    *)
      uk_warn "Unknown action: $mode"
      qr_usage
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    qr_wizard
  else
    qr_main "$@"
  fi
fi

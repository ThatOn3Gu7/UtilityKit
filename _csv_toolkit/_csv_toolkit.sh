#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

csvt_usage() {
  cat <<'USAGE'
Usage: _csv_toolkit.sh FILE [--columns] [--head N]

Options:
  --columns    Print only the header row (column names)
  --head N     Show the first N data rows (default: 10)
  -h, --help   Show this help
USAGE
}
csvt_main() {
  uk_banner "csv-toolkit" "CSV column header print and row preview" "" "$@"
  local file='' cols=0 headn=10

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --columns) cols=1 ;;
    --head)
      shift
      headn="${1:-10}"
      ;;
    -h | --help)
      csvt_usage
      return 0
      ;;
    --*)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    *) file="${1:-}" ;;
    esac
    shift
  done

  # Validate input
  if [[ -z "$file" ]]; then
    uk_error "No CSV file specified."
    csvt_usage
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    uk_error "File not found: $file"
    return 1
  fi
  if [[ ! -r "$file" ]]; then
    uk_error "File is not readable: $file"
    return 1
  fi

  # Validate head number
  if ! [[ "$headn" =~ ^[1-9][0-9]*$ ]]; then
    uk_error "N must be a positive integer for --head."
    return 1
  fi

  # Check for Python 3
  if ! uk_has_cmd python3; then
    uk_error "python3 is required but not found in PATH."
    return 1
  fi

  # Run the Python CSV tool
  python3 - "$file" "$cols" "$headn" <<'PYTHON'
import csv
import sys
import os

def main():
    if len(sys.argv) < 4:
        sys.exit(1)

    filename = sys.argv[1]
    show_columns = sys.argv[2] == '1'
    head_limit = int(sys.argv[3])

    try:
        with open(filename, newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.", file=sys.stderr)
        sys.exit(1)
    except csv.Error as e:
        print(f"Error parsing CSV: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)

    if not rows:
        print("CSV file is empty.")
        return

    if show_columns:
        # Print only the header row
        print('\n'.join(rows[0]))
    else:
        # Print preview rows
        header = rows[0] if rows else []
        data_rows = rows[1:] if len(rows) > 1 else []

        print(' | '.join(header))
        print('-' * 40)
        for row in data_rows[:head_limit]:
            print(' | '.join(row))

        total_rows = max(len(data_rows), 0)
        print(f'\nTotal data rows: {total_rows}')

if __name__ == '__main__':
    main()
PYTHON
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  csvt_main "$@"
fi


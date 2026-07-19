#compdef utility
# zsh completion for utility (UtilityKit)
# Auto-generated from UK_REGISTRY by scripts/gen_completions.sh — DO NOT EDIT.
# Install (either):
#   source /path/to/completions/utility.zsh    # in ~/.zshrc, after compinit
#   cp utility.zsh ~/.zsh/completions/_utility # any dir in $fpath

_utility() {
  local -a commands
  commands=(
    'apply:Robust Directory Synchronization'
    'rename:Recursive File Renaming & Copying'
    'cacheclean:Intelligent System Cache Cleanup'
    'symlink:Dotfiles & System Config Management'
    'disk:Storage Inspection & Quick Archiving'
    'env:compare, validate, and switch .env profiles'
    'git:clean merged branches, stashes, and artifacts'
    'scaffold:generate starter projects from guided templates'
    'dup:find exact duplicate files and reclaim space'
    'proc:inspect memory pressure and terminate processes'
    'port:find which process owns a local port'
    'ssl:inspect certificate expiry, DNS, and TLS support'
    'api:send HTTP requests and save reusable profiles'
    'pass:generate passphrases or random strings'
    'ssh:list SSH hosts and run connection helpers'
    'shred:securely erase sensitive files with fallbacks'
    'media:batch convert images/videos when tools exist'
    'toc:generate TOCs, check links, align tables'
    'pomodoro:run focused work/break cycles'
    'cheat:store, search, and show command snippets'
    'move:copy/move files safely with exclusions'
    'docker:clean containers, images, and volumes'
    'network:ping, DNS, public IP, and route diagnostics'
    'service:check HTTP services and response times'
    'git-stats:summarize authors, branches, and changed files'
    'json:pretty-print, inspect, and extract JSON paths'
    'links:validate Markdown local and HTTP links'
    'backup:dry-run-first backup wrapper with fallbacks'
    'search:search files/text with rg/grep/find fallbacks'
    'log-inspect:summarize warnings, errors, repeated lines'
    'csv:inspect CSV headers and preview rows'
    'cron:list/add/remove crontab entries safely'
    'dotenv:encrypt selected .env values with gpg'
    'disk-health:SMART health check when smartctl exists'
    'weather:terminal forecast lookup with cache fallback'
    'tmux:list, create, attach, or kill tmux sessions'
    'font:check glyph support and list fonts'
    'toolbox:detect recommended CLI tools'
    'github:wrap common gh CLI tasks'
    'hash:create checksums for files and trees'
    'archive:list, create, and safely extract archives'
    'snapshot:collect a compact diagnostic summary'
    'open-files:find processes using paths or ports'
    'battery:show battery and power diagnostics'
    'release:run git release checks and optional tags'
    'license:detect or generate simple license text'
    'todo:plain-text tasks with tags and search'
    'update:detect and update every package manager found'
    'qr:encode text/URL/Wi-Fi/vCard, decode images'
    'clipboard:persistent clipboard log with pins & search'
    'secret:find leaked credentials via regex + entropy'
    'dns:multi-resolver DNS queries & propagation checks'
    'ipinfo:public/local IP, ASN, GeoIP, WHOIS lookup'
    'regex:live regex tester with match & substitution preview'
    'uuid:generate UUID v4/v7, ULID, NanoID, short IDs'
    'time:epoch ↔ ISO 8601 ↔ human, cron analyzer'
    'bench:HTTP benchmark with p50/p95/p99 & RPS stats'
    'yaml:lint, convert, query, and merge YAML files'
    'ytdl:download YouTube videos via yt-dlp (format selection, subs, audio)'
    'pdf:count pages, info, merge, split, extract text from PDFs'
    'image:resize, convert, strip EXIF, optimize images'
    'fwatch:run command on file change with glob patterns'
    'tunnel:create, list, kill, restart persistent SSH port-forwards'
    'hooks:install, remove, list, show git hook templates'
    'installed:list packages & PATH executables by manager'
    'setup:run the installer (setup.sh)'
    'doctor:registry + installation integrity checks'
    'help:show top-level help'
    'version:print UtilityKit version'
  )

  if (( CURRENT == 2 )); then
    _describe -t commands 'utility command' commands
    return
  fi

  local -a flags
  case "${words[2]}" in
  apply) flags=(--apply --backup-dir --dry-run --exclude --force --help --include-logs --include-runtime --interactive --log-file --max-preview --mirror --no-default-excludes --no-lock --yes -h -i -y) ;;
  rename) flags=(--all --force --help --version -f -h -v) ;;
  cacheclean) flags=(--debug --delete --fancy --force-root --help --no-color --no-fancy --older-than --quiet --version --yes -V -h -q -y) ;;
  symlink) flags=(--apply --backup-dir --help --yes -h -y) ;;
  disk) flags=(--count --help -h -n) ;;
  env) flags=(--active --apply --compare --decrypt --dir --encrypt --example --help --profile --validate -h) ;;
  git) flags=(--apply --clean-artifacts --delete-merged-local --delete-merged-remote --drop-stashes --gc --help --repo -h) ;;
  scaffold) flags=(--dest --force --help --name --type -h) ;;
  dup) flags=(--apply --delete --hardlink --help -h) ;;
  proc) flags=(--help --pid --signal -h) ;;
  port) flags=(--help --kill -h) ;;
  ssl) flags=(--help --no-dns --no-tls --port -h) ;;
  api) flags=(--body --body-file --expect --header --help --list --method --run --save --show --url -h) ;;
  pass) flags=(--copy --help --length --mode --separator --words -h) ;;
  ssh) flags=(--add --config --connect --copy-id --help -h) ;;
  shred) flags=(--apply --help --passes -h) ;;
  media) flags=(--apply --help --kind --output --quality --strip-exif --to -h) ;;
  toc) flags=(--align-tables --apply --check-links --help -h) ;;
  pomodoro) flags=(--break --cycles --help --no-bell --unit --work -h) ;;
  cheat) flags=(--add --delete --file --help --list --search --show --tags --text -h) ;;
  move) flags=(--exclude --flatten --help --interactive --method --output --target --version -e -f -h -i -m -o -t -v) ;;
  docker) flags=(--all --apply --containers --help --images --volumes -h) ;;
  network) flags=(--count --dns --help --no-public-ip --no-trace -h) ;;
  service) flags=(--help --insecure --interval --profile --save -h) ;;
  git-stats) flags=(--author --help --repo --since --until -h) ;;
  json) flags=(--help --keys --path --summary -h) ;;
  links) flags=(--help --http --timeout -h) ;;
  backup) flags=(--apply --delete --dest --exclude --help --source -d -h -s) ;;
  search) flags=(--help --name -h) ;;
  log-inspect) flags=(--help --pattern -h) ;;
  csv) flags=(--columns --head --help -h) ;;
  cron) flags=(--add --apply --help --list --remove -h) ;;
  dotenv) flags=(--apply --decrypt --encrypt --file --help --output -h) ;;
  disk-health) flags=(--device --help --list --test-short -h) ;;
  weather) flags=(--concise --full --help --units -h) ;;
  tmux) flags=(--attach --help --kill --list --new -a -h -k -l -n) ;;
  font) flags=(--filter --glyphs --help --list -h) ;;
  toolbox) flags=(--help) ;;
  github) flags=(--help --issues --prs --runs --status -h) ;;
  hash) flags=(--help) ;;
  archive) flags=(--create --dest --extract --help --list -h) ;;
  snapshot) flags=(--help -h) ;;
  open-files) flags=(--help --port -h) ;;
  battery) flags=(--help) ;;
  release) flags=(--help --apply --tag) ;;
  license) flags=(--detect --generate --help --name -h) ;;
  todo) flags=(--add --done --help --list --search --tag -h) ;;
  update) flags=(--all --ascii --color --dry-run --help --interactive --list --log-file --no-clear --no-color --only --skip --unicode --verbose --yes -h -i -v -y) ;;
  qr) flags=(--email --enc --help --hidden --image --json --level --margin --no-color --org --out --phone --psk --size --text --title --vcard --wifi -h) ;;
  clipboard) flags=(--force --help --json --last --max --no-clip --quiet -h) ;;
  secret) flags=(--context --entropy-len --entropy-min --exclude --help --include --json --max-bytes --no-color --no-entropy --no-gitignore --path --quiet --reveal -h) ;;
  dns) flags=(--help --json --no-color --propagation --resolver --system --timeout --tries --type -h) ;;
  ipinfo) flags=(--geo --help --json --local --no-color --no-network --public --timeout --whois -h) ;;
  regex) flags=(--case-insensitive --color --extended --file --help --json --multiline --no-color --pattern --stdin --sub --text -c -f -h -i -m -p -s -t -x) ;;
  uuid) flags=(--alphabet --clip --count --help --json --len --no-color --quiet --sep --upper -h) ;;
  time) flags=(--count --format --help --json --no-color --tz -h) ;;
  bench) flags=(--concurrency --data --header --help --json --keep-alive --method --no-color --requests --timeout -H -c -d -h -m -n) ;;
  yaml) flags=(--help --indent --json --no-color --no-doc -h) ;;
  ytdl) flags=(--audio-format --audio-only --format --help --no-meta --no-thumb --output --playlist --subs -h) ;;
  pdf) flags=(--apply --help --json --no-color --output --pages -h) ;;
  image) flags=(--apply --format --height --help --json --no-color --out --percent --quality --recursive --size --width -h) ;;
  fwatch) flags=(--cmd --debounce --dir --help --ignore --initial --json --no-color --pattern --polling -c -d -h -i -p -r -s) ;;
  tunnel) flags=(--autossh --help --local --no-color -h) ;;
  hooks) flags=(--help --json --no-color -h) ;;
  installed) flags=(--all --category --commands --count --export --help --json --manager --no-color --packages -h) ;;
  setup) flags=(--bin-dir --help --install-dir --launcher-name --no-menu --no-path -h) ;;
  doctor) flags=(--fix --no-color --quick) ;;
  help) flags=() ;;
  version) flags=() ;;
  esac

  if [[ "${words[CURRENT]}" == -* && ${#flags[@]} -gt 0 ]]; then
    compadd -- "${flags[@]}"
  elif [[ -z "${words[CURRENT]}" && ${#flags[@]} -gt 0 ]]; then
    # Empty word after the command: offer flags up front, files as well.
    compadd -- "${flags[@]}"
    _files
  else
    _files
  fi
}

if (( ${+functions[compdef]} )); then
  # Register for the default launcher and direct ./main.sh runs.
  compdef _utility utility main.sh
  # setup.sh sets UK_COMPLETE_CMD when the launcher has a custom name.
  if [[ -n "${UK_COMPLETE_CMD:-}" ]]; then
    compdef _utility "$UK_COMPLETE_CMD"
  fi
elif [[ "${funcstack[1]:-}" == _utility ]]; then
  # Autoloaded from $fpath by compinit — act as the completion function.
  _utility "$@"
fi
# Sourced before compinit: nothing registered — run compinit first.

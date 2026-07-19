# bash completion for utility (UtilityKit)
# Auto-generated from UK_REGISTRY by scripts/gen_completions.sh — DO NOT EDIT.
# Install: source this file from ~/.bashrc

_utility() {
  local cur cmd
  cur="${COMP_WORDS[COMP_CWORD]}"
  cmd="${COMP_WORDS[1]:-}"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "apply rename cacheclean symlink disk env git scaffold dup proc port ssl api pass ssh shred media toc pomodoro cheat move docker network service git-stats json links backup search log-inspect csv cron dotenv disk-health weather tmux font toolbox github hash archive snapshot open-files battery release license todo update qr clipboard secret dns ipinfo regex uuid time bench yaml ytdl pdf image fwatch tunnel hooks installed setup doctor help version" -- "$cur"))
    return
  fi

  local flags=""
  case "$cmd" in
  apply) flags="--apply --backup-dir --dry-run --exclude --force --help --include-logs --include-runtime --interactive --log-file --max-preview --mirror --no-default-excludes --no-lock --yes -h -i -y" ;;
  rename) flags="--all --force --help --version -f -h -v" ;;
  cacheclean) flags="--debug --delete --fancy --force-root --help --no-color --no-fancy --older-than --quiet --version --yes -V -h -q -y" ;;
  symlink) flags="--apply --backup-dir --help --yes -h -y" ;;
  disk) flags="--count --help -h -n" ;;
  env) flags="--active --apply --compare --decrypt --dir --encrypt --example --help --profile --validate -h" ;;
  git) flags="--apply --clean-artifacts --delete-merged-local --delete-merged-remote --drop-stashes --gc --help --repo -h" ;;
  scaffold) flags="--dest --force --help --name --type -h" ;;
  dup) flags="--apply --delete --hardlink --help -h" ;;
  proc) flags="--help --pid --signal -h" ;;
  port) flags="--help --kill -h" ;;
  ssl) flags="--help --no-dns --no-tls --port -h" ;;
  api) flags="--body --body-file --expect --header --help --list --method --run --save --show --url -h" ;;
  pass) flags="--copy --help --length --mode --separator --words -h" ;;
  ssh) flags="--add --config --connect --copy-id --help -h" ;;
  shred) flags="--apply --help --passes -h" ;;
  media) flags="--apply --help --kind --output --quality --strip-exif --to -h" ;;
  toc) flags="--align-tables --apply --check-links --help -h" ;;
  pomodoro) flags="--break --cycles --help --no-bell --unit --work -h" ;;
  cheat) flags="--add --delete --file --help --list --search --show --tags --text -h" ;;
  move) flags="--exclude --flatten --help --interactive --method --output --target --version -e -f -h -i -m -o -t -v" ;;
  docker) flags="--all --apply --containers --help --images --volumes -h" ;;
  network) flags="--count --dns --help --no-public-ip --no-trace -h" ;;
  service) flags="--help --insecure --interval --profile --save -h" ;;
  git-stats) flags="--author --help --repo --since --until -h" ;;
  json) flags="--help --keys --path --summary -h" ;;
  links) flags="--help --http --timeout -h" ;;
  backup) flags="--apply --delete --dest --exclude --help --source -d -h -s" ;;
  search) flags="--help --name -h" ;;
  log-inspect) flags="--help --pattern -h" ;;
  csv) flags="--columns --head --help -h" ;;
  cron) flags="--add --apply --help --list --remove -h" ;;
  dotenv) flags="--apply --decrypt --encrypt --file --help --output -h" ;;
  disk-health) flags="--device --help --list --test-short -h" ;;
  weather) flags="--concise --full --help --units -h" ;;
  tmux) flags="--attach --help --kill --list --new -a -h -k -l -n" ;;
  font) flags="--filter --glyphs --help --list -h" ;;
  toolbox) flags="--help" ;;
  github) flags="--help --issues --prs --runs --status -h" ;;
  hash) flags="--help" ;;
  archive) flags="--create --dest --extract --help --list -h" ;;
  snapshot) flags="--help -h" ;;
  open-files) flags="--help --port -h" ;;
  battery) flags="--help" ;;
  release) flags="--help --apply --tag" ;;
  license) flags="--detect --generate --help --name -h" ;;
  todo) flags="--add --done --help --list --search --tag -h" ;;
  update) flags="--all --ascii --color --dry-run --help --interactive --list --log-file --no-clear --no-color --only --skip --unicode --verbose --yes -h -i -v -y" ;;
  qr) flags="--email --enc --help --hidden --image --json --level --margin --no-color --org --out --phone --psk --size --text --title --vcard --wifi -h" ;;
  clipboard) flags="--force --help --json --last --max --no-clip --quiet -h" ;;
  secret) flags="--context --entropy-len --entropy-min --exclude --help --include --json --max-bytes --no-color --no-entropy --no-gitignore --path --quiet --reveal -h" ;;
  dns) flags="--help --json --no-color --propagation --resolver --system --timeout --tries --type -h" ;;
  ipinfo) flags="--geo --help --json --local --no-color --no-network --public --timeout --whois -h" ;;
  regex) flags="--case-insensitive --color --extended --file --help --json --multiline --no-color --pattern --stdin --sub --text -c -f -h -i -m -p -s -t -x" ;;
  uuid) flags="--alphabet --clip --count --help --json --len --no-color --quiet --sep --upper -h" ;;
  time) flags="--count --format --help --json --no-color --tz -h" ;;
  bench) flags="--concurrency --data --header --help --json --keep-alive --method --no-color --requests --timeout -H -c -d -h -m -n" ;;
  yaml) flags="--help --indent --json --no-color --no-doc -h" ;;
  ytdl) flags="--audio-format --audio-only --format --help --no-meta --no-thumb --output --playlist --subs -h" ;;
  pdf) flags="--apply --help --json --no-color --output --pages -h" ;;
  image) flags="--apply --format --height --help --json --no-color --out --percent --quality --recursive --size --width -h" ;;
  fwatch) flags="--cmd --debounce --dir --help --ignore --initial --json --no-color --pattern --polling -c -d -h -i -p -r -s" ;;
  tunnel) flags="--autossh --help --local --no-color -h" ;;
  hooks) flags="--help --json --no-color -h" ;;
  installed) flags="--all --category --commands --count --export --help --json --manager --no-color --packages -h" ;;
  setup) flags="--bin-dir --help --install-dir --launcher-name --no-menu --no-path -h" ;;
  doctor) flags="--fix --no-color --quick" ;;
  help) flags="" ;;
  version) flags="" ;;
  esac

  # Empty word after the command offers flags too (not only after "-"),
  # so `utility <cmd> <TAB>` shows the available options up front.
  if [[ ( "$cur" == -* || -z "$cur" ) && -n "$flags" ]]; then
    COMPREPLY=($(compgen -W "$flags" -- "$cur"))
  fi
}

# Register for the default launcher and direct ./main.sh runs.
complete -o default -F _utility utility main.sh
# setup.sh sets UK_COMPLETE_CMD when the launcher has a custom name.
if [[ -n "${UK_COMPLETE_CMD:-}" ]]; then
  complete -o default -F _utility "$UK_COMPLETE_CMD"
fi

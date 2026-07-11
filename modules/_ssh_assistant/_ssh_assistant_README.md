# _ssh_assistant

Parse `~/.ssh/config` to list named hosts, connect to them quickly by number, or push your public key to a remote host using `ssh-copy-id`.

---

## Features

- **Host listing** — reads `~/.ssh/config` and displays all named hosts with their connection command
- **Quick connect** — pick a host by number from the list instead of typing the full alias
- **Key deployment** — runs `ssh-copy-id` to push your public key to any host
- **Git host awareness** — explains intentional auth-only disconnects from GitHub, GitLab, and Bitbucket
- **Custom config support** — point the tool at any SSH config file with `--config`
- **Interactive mode** — running without arguments lists hosts and prompts for a selection

---

## Usage

```bash
# Interactive mode — list hosts and pick one to connect
bash _ssh_assistant/_ssh_assistant.sh

# Connect directly to a named host
bash _ssh_assistant/_ssh_assistant.sh --connect myserver

# Push your public key to a host
bash _ssh_assistant/_ssh_assistant.sh --copy-id user@example.com

# Use a custom SSH config file
bash _ssh_assistant/_ssh_assistant.sh --config ~/.ssh/work_config

# Combine custom config with direct connect
bash _ssh_assistant/_ssh_assistant.sh --config ~/.ssh/work_config --connect staging
```

---

## Options

| Option | Description |
|---|---|
| `--connect HOST` | Connect directly to the named SSH host alias |
| `--copy-id HOST` | Run `ssh-copy-id` to deploy your public key to HOST |
| `--config FILE` | Use FILE as the SSH config instead of `~/.ssh/config` |
| `-h, --help` | Show usage |

---

## SSH config format

The tool reads `Host` entries from your SSH config file. Wildcard entries like `Host *` are ignored — only named hosts are listed:

```sshconfig
Host myserver
  HostName 192.168.1.10
  User deploy
  IdentityFile ~/.ssh/id_ed25519

Host staging
  HostName staging.example.com
  User ubuntu
  Port 2222

Host github
  HostName github.com
  User git
  IdentityFile ~/.ssh/github_key
```

Running the tool against this config produces:

```
  Named hosts found in ~/.ssh/config:

   1)  myserver    (ssh myserver)
   2)  staging     (ssh staging)
   3)  github      (ssh github)
```

---

## Git hosting services

When connecting to GitHub, GitLab, or Bitbucket via SSH, the remote end closes the connection immediately after a successful authentication handshake. This is expected behavior — those services do not grant interactive shell access. The tool detects these hosts and explains the disconnect so it does not look like a failure.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success or user exited the menu |
| `1` | Invalid host selection, `ssh-copy-id` not installed, or unknown option |

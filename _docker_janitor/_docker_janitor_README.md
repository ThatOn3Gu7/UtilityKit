# _docker_janitor

Preview and prune stopped containers, dangling images, and orphaned volumes from a local Docker installation. Shows a disk usage summary before any action is taken.

---

## Features

- **Container pruning** — removes exited and stopped containers
- **Image pruning** — removes dangling untagged image layers
- **Volume pruning** — removes volumes no longer attached to any container
- **Disk usage summary** — displays `docker system df` output before prompting
- **Safe by default** — nothing is deleted until you explicitly confirm with `--apply`
- **Interactive mode** — running without arguments shows counts and prompts for each category

---

## Usage

```bash
# Interactive mode — show counts and prompt for each category
bash _docker_janitor/_docker_janitor.sh

# Preview what would be pruned (no changes made)
bash _docker_janitor/_docker_janitor.sh --containers --images

# Prune stopped containers only
bash _docker_janitor/_docker_janitor.sh --containers --apply

# Prune dangling images only
bash _docker_janitor/_docker_janitor.sh --images --apply

# Prune everything at once
bash _docker_janitor/_docker_janitor.sh --all --apply
```

---

## Options

| Option | Description |
|---|---|
| `--containers` | Select stopped containers for pruning |
| `--images` | Select dangling images for pruning |
| `--volumes` | Select dangling volumes for pruning |
| `--all` | Select all three categories at once |
| `--apply` | Execute the selected prune operations |
| `-h, --help` | Show usage |

---

## What each category removes

| Category | What is removed | What is kept |
|---|---|---|
| Containers | Exited and stopped containers | Running containers, images, volumes |
| Images | Untagged dangling image layers | Named and tagged images |
| Volumes | Volumes with no container reference | Volumes attached to any container |

---

## Preview output

Before any prompts the tool always displays current counts and disk usage:

```
  Stopped containers   3   (exited and no longer running)
  Dangling images      7   (untagged layers with no active reference)
  Dangling volumes     2   (volumes no longer attached to any container)

  Disk usage summary:
  TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
  Images          12        5         2.1GB     890MB (42%)
  Containers      3         0         0B        0B
  Local Volumes   4         2         512MB     210MB (41%)
```

---

## Notes

- Volume pruning is the most destructive option — data stored inside orphaned volumes is permanently lost
- This tool is not useful inside Termux since Docker is generally unavailable on Android
- The tool verifies that the Docker daemon is reachable before doing anything

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Docker not found or daemon not reachable |

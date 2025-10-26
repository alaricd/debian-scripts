# Repository Guidelines

## Project Structure & Module Organization
Core automation lives at the repo root. `autoupdate-and-reboot.sh` is the primary entrypoint and now handles logging, locking, retry, autoremove ordering, and reboot policy on its own. Supporting scripts (`autoupdate-and-shutdown.sh`, `remove-old-kernels.sh`, etc.) remain in the root for backwards compatibility. Systemd units reside under `systemd/`, GitHub Actions workflows under `.github/workflows/`, and bats specs under `test/`. Keep new scripts executable, add succinct header comments, and document any required capabilities.

## Build, Test, and Development Commands
Prefer `make` targets:
- `make install` / `make uninstall` deploy or remove `/usr/local/sbin/autoupdate-and-reboot.sh` plus the service & timer.
- `sudo ./install-autoupdate.sh` provides a standalone installer for production hosts without build tooling.
- `make lint` runs `shellcheck` and `shfmt -d .` across the tree.
- `make test` executes the bats suite (`test/autoupdate.bats`) with mocked apt interactions.
When hacking locally, export `LOGFILE`/`LOCKFILE` to temporary paths to avoid writing to `/var/`.

## Coding Style & Naming Conventions
Author scripts in Bash, enforce `#!/usr/bin/env bash` and `set -Eeuo pipefail` (also set `IFS=$'\n\t'` for new work). Use two-space indentation, lowercase-with-hyphen filenames, and `$()` command substitutions. Guard external commands with `command -v` when optional, wrap expansions in quotes, and log through the shared `log()` helper in `autoupdate-and-reboot.sh` when extending functionality.

## Testing Guidelines
Bats specs mock `apt-get`, `needrestart`, and reboot primitives—add new fixtures there when behaviour changes. Avoid touching the real system in tests; rely on env overrides (`LOGFILE`, `LOCKFILE`, `NO_REBOOT`, etc.) and stubbed PATH entries. CI requires a clean `make lint` and `make test`, so run both before opening a PR.

## Commit & Pull Request Guidelines
Stay consistent with the short, imperative commit style already in history (`add needrestart`, `fix reboot loop`). In PR descriptions, summarise behavioural changes, note any new timers/services, call out privileged operations, and include sample log excerpts (especially the final `status uname=… pending=… reboot_required=…` line). Flag any reboot/shutdown side effects prominently and link downstream rollout instructions when relevant.

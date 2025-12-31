# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Bash scripts for automating Debian/Ubuntu/Kali system maintenance, including package updates, cleanup, and automated shutdown/reboot flows.

## Architecture

- **Primary entrypoint**: `autoupdate-and-reboot.sh` orchestrates the full update flow, logging, locking, and reboot policy.
- **Sourceable library**: `autoupdate.sh` implements the apt update/upgrade flow and exports `run_autoupdate()`.
- **Orchestration helpers**: `autoupdate-and-shutdown.sh` and `cleanshutdown` wrap the main flow with shutdown handling.
- **Utility scripts**: `remove-old-kernels.sh`, `remove-old-snaps.sh`, `remove-all-old-packages.sh`, `check-requirements.sh`, `check-if-already-updating.sh`.
- **Tests**: Bats specs in `test/`, legacy bash tests in `tests/`.

### autoupdate-and-reboot.sh Workflow

1. Initializes logging to `/var/log/autoupdate.log` and syslog, and takes a non-blocking lock at `/var/lock/autoupdate.lock`.
2. Runs maintenance in this order:
   - `remove-old-kernels.sh`
   - `remove-old-snaps.sh`
   - `run_autoupdate` from `autoupdate.sh`
   - `remove-all-old-packages.sh`
3. Determines reboot requirement when `/var/run/reboot-required` exists, `REBOOT_FORCE=1`, or needrestart reports failures.
4. Skips reboot when `NO_REBOOT=1`, inside a container (`systemd-detect-virt`), or when `who` reports active sessions, unless reboot is forced.
5. Passing any argument forces a reboot and bypasses safety checks.
5. Emits the final status line: `status uname=… pending=… reboot_required=…`.

### autoupdate.sh

- Sourceable library that defines `run_autoupdate()` and a fallback logger `log_default`.
- Steps:
  - `apt-get update`
  - `apt-get dist-upgrade -s` to compute `PENDING_UPGRADES`
  - `apt-get dist-upgrade`
- `needrestart -r a` when available; failures mark a reboot requirement but do not abort the run
  - `apt-get autoremove --purge`

### Orchestration Scripts

- `autoupdate-and-shutdown.sh` runs `check-if-already-updating.sh`, then `autoupdate-and-reboot.sh` with `NO_REBOOT=1`, then `shutdown -h now`.
- `cleanshutdown` requires root unless `CLEANSHUTDOWN_ALLOW_NONROOT=1`, runs `sync`, `check-if-already-updating.sh`, the main update flow with `NO_REBOOT=1`, then runs BleachBit for the invoking user and root before shutdown.

### Utility Script Notes

- `check-if-already-updating.sh` exits early if `apt-get`/`dpkg` are running, then runs `dpkg --configure -a`.
- `remove-old-kernels.sh` finds the running kernel package (including unsigned variants), then purges only older kernel ABI packages.
- `remove-old-snaps.sh` refreshes snaps and removes disabled revisions if `snap` is installed.
- `remove-all-old-packages.sh` runs `apt-mark minimize-manual` and loops `apt-get autoremove --purge` until no more removals (or 10 iterations).
- `check-requirements.sh` installs required packages based on `/etc/os-release` and configures needrestart to auto-restart.

## Common Development Tasks

### Running Tests
```bash
make test
bats test/autoupdate.bats
bats test/cleanshutdown.bats
bats test/remove-old-kernels.bats

# Legacy tests (require sudo)
sudo ./tests/test_check_requirements.sh
sudo ./tests/test_cleanshutdown.sh
```

### Linting
```bash
make lint
```

### Installing/Uninstalling
```bash
make install
sudo ./install-autoupdate.sh
make uninstall
```

## Test Environment Overrides

- `LOGFILE`, `LOCKFILE`: redirect log/lock files away from `/var`.
- `REBOOT_REQUIRED_FILE`: override the reboot-required flag path (defaults to `/var/run/reboot-required`).
- `NO_REBOOT`, `REBOOT_FORCE`: control reboot behavior.
- `AUTOTEST_STATE_DIR`, `AUTOTEST_TTY_ACTIVE`, `AUTOTEST_NEEDRESTART_FAIL`, `AUTOTEST_SCENARIO`: bats stubs.
- `CLEANSHUTDOWN_ALLOW_NONROOT`: allow `cleanshutdown` to run without root in tests.

## Distribution Support

- **Kali**: installs `sed`, `needrestart`, `fwupd`; ensures `netcat-traditional` if `nc` is missing.
- **Ubuntu/Debian**: installs `netcat-openbsd`, `sed`, `needrestart`, `fwupd`.

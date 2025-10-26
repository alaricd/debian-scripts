# debian-scripts

Utilities to keep Debian, Ubuntu, and other apt-based systems patched, tidy, and rebooted only when needed.

## Autoupdate Workflow
- `autoupdate-and-reboot.sh` orchestrates `apt-get update`, `apt-get dist-upgrade`, optional `needrestart`, and `apt-get autoremove --purge` in that order.
- The script runs in strict Bash mode, guards against concurrent execution with `flock`, logs to `/var/log/autoupdate.log` *and* syslog, and refuses to reboot on partial failure.
- Reboots occur only when `/var/run/reboot-required` exists (or `REBOOT_FORCE=1`) and are skipped automatically for containers, active TTY sessions, or when `NO_REBOOT=1`.

## Installation
```sh
make install
```
or
```sh
sudo ./install-autoupdate.sh
```
Both options copy the script to `/usr/local/sbin/`, install `autoupdate.service` and `autoupdate.timer`, reload systemd units, enable the timer, and disable the conflicting `apt-daily-upgrade.timer`.

To remove everything:
```sh
make uninstall
```

## Runtime Behaviour
- `autoupdate.timer` schedules a run every three hours with a 30-minute randomized delay and persists missed runs across reboots.
- Each run emits a final status line (`status uname=… pending=… reboot_required=…`) for monitoring, and the script exits without rebooting if anything fails.
- Adjustable knobs:
  - `NO_REBOOT=1` prevents reboots entirely.
  - `REBOOT_FORCE=1` forces a reboot even if `/var/run/reboot-required` is absent (still skips for containers/TTYs).

## Development
- Lint scripts: `make lint` (requires `shellcheck` and `shfmt`).
- Run automated tests: `make test` (requires `bats`).
- Continuous integration via GitHub Actions runs both linting and tests on every push and pull request.

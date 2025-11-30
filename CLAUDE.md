# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a collection of bash scripts for automating Debian/Ubuntu system maintenance tasks. The scripts handle system updates, package cleanup, kernel management, and automated shutdown/reboot sequences.

## Architecture

The project follows a modular design where:

- **Main orchestration scripts**: `cleanshutdown`, `autoupdate-and-reboot.sh`, `autoupdate-and-shutdown.sh`
- **Core functionality scripts**: Individual scripts for specific tasks (update, cleanup, kernel management)
- **Utility scripts**: Helper scripts for prerequisites and status checking
- **Self-contained design**: Scripts use `SCRIPT_DIR` variable to reference companion scripts from the same location

### Script Dependencies and Flow

1. **cleanshutdown** (main orchestration script):
   - Uses `SCRIPT_DIR` to locate companion scripts in user directory
   - Delegates to `autoupdate-and-reboot.sh` with NO_REBOOT=1
   - Runs BleachBit cleanup (failures ignored with `|| true`)
   - Performs system shutdown

2. **Update sequence**: `check-if-already-updating.sh` → `remove-old-kernels.sh` → `remove-old-snaps.sh` (snap refresh + cleanup) → `autoupdate.sh` (apt-get update/dist-upgrade) → `remove-all-old-packages.sh` (final autoremove)

3. **Requirements management**: `check-requirements.sh` detects distribution (Kali/Ubuntu/Debian) and installs required packages with distribution-specific handling

### autoupdate.sh Architecture

- `autoupdate.sh` is a sourceable library that exports `run_autoupdate()` function
- Takes a logger function name as first parameter (defaults to `log_default`)
- Can be sourced by orchestration scripts or run standalone
- Exports `PENDING_UPGRADES` variable containing upgrade count from simulation
- Returns non-zero on failure to prevent reboots on partial failures

### Autoupdate-and-Reboot Workflow

- Uses `flock` to prevent concurrent execution
- Logs to both `/var/log/autoupdate.log` and syslog
- Runs in strict mode (`set -Eeuo pipefail`)
- **Execution order rationale**:
  1. Remove old kernels first to free `/boot` space (prevents apt-get failures when installing new kernels)
  2. Refresh and clean up snaps before apt updates (frees disk space and updates snap packages)
  3. Run apt-get update/dist-upgrade (main system updates)
  4. Final autoremove to clean up packages made obsolete by the upgrade
- Only reboots when `/var/run/reboot-required` exists or `REBOOT_FORCE=1`
- Automatically skips reboots for containers, active TTY sessions, or when `NO_REBOOT=1`
- Emits final status line with format: `status uname=… pending=… reboot_required=…`

## Common Development Tasks

### Running Tests
```bash
# Run all tests
make test

# Run specific test suite
bats test/autoupdate.bats
bats test/cleanshutdown.bats
bats test/remove-old-kernels.bats

# Tests in tests/ directory (legacy bash-based tests)
sudo ./tests/test_check_requirements.sh
sudo ./tests/test_cleanshutdown.sh
```

### Linting
```bash
# Lint all scripts
make lint

# Uses shellcheck for static analysis and shfmt for formatting
```

### Installing/Uninstalling
```bash
# Install systemd service and timer
make install

# Or use the install script directly
sudo ./install-autoupdate.sh

# Uninstall everything
make uninstall
```

## Key Design Patterns

1. **Path Independence**: Scripts use `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` to work from any installation location
2. **Distribution Awareness**: `check-requirements.sh` detects OS and handles package differences (Kali vs Ubuntu/Debian)
3. **Error Handling**: Critical operations use `set -e`, optional operations use `|| true`
4. **Service Management**: Automatic service restart using `needrestart -r a`
5. **Non-interactive Mode**: All scripts set `DEBIAN_FRONTEND=noninteractive`
6. **Sourceable Functions**: Core logic in `autoupdate.sh` can be sourced and called with custom logger

## Testing Strategy

- BATS tests in `test/` directory for main scripts (modern approach)
- Legacy bash tests in `tests/` directory
- Tests use stubs/mocks for system commands (`apt-get`, `reboot`, `needrestart`, etc.)
- Test environment variables:
  - `AUTOTEST_STATE_DIR`: Directory for test state files
  - `AUTOTEST_TTY_ACTIVE`: Simulate active TTY sessions
  - `AUTOTEST_NEEDRESTART_FAIL`: Force needrestart failures
- Tests validate both positive and negative cases, execution order, and strict mode

## Distribution Support

- **Kali Linux**: Special handling for netcat (checks `nc` command, installs `netcat-traditional` if needed)
- **Ubuntu/Debian**: Uses `netcat-openbsd` package
- **Package management**: Uses `needrestart` and standard apt tools

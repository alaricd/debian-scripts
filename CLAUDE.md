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
   - Executes maintenance sequence: check → cleanup → update
   - Runs BleachBit cleanup (failures ignored with `|| true`)
   - Performs system shutdown

2. **Update sequence**: `check-if-already-updating.sh` → `remove-old-kernels.sh` → `remove-all-old-packages.sh` → `remove-old-snaps.sh` → `autoupdate.sh`

3. **Requirements management**: `check-requirements.sh` detects distribution (Kali/Ubuntu/Debian) and installs required packages with distribution-specific handling

## Common Development Tasks

### Running Tests
```bash
# Run all tests
./tests/test_check_requirements.sh
./tests/test_cleanshutdown.sh

# Tests validate script behavior and ensure no regressions
```

### Testing Individual Scripts
```bash
# Check script syntax
bash -n script_name.sh

# Test requirement checking
sudo ./check-requirements.sh

# Test update process (dry run by examining script logic)
```

## Key Design Patterns

1. **Path Independence**: Scripts use `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` to work from any installation location
2. **Distribution Awareness**: `check-requirements.sh` detects OS and handles package differences (Kali vs Ubuntu/Debian)
3. **Error Handling**: Critical operations use `set -e`, optional operations use `|| true`
4. **Service Management**: Automatic service restart using `needrestart -r a`
5. **Non-interactive Mode**: All scripts set `DEBIAN_FRONTEND=noninteractive`

## Testing Strategy

- Tests are located in `tests/` directory
- Tests validate both positive and negative cases
- Focus on ensuring scripts reference correct paths and handle errors appropriately
- Test script names follow pattern `test_<script_name>.sh`

## Distribution Support

- **Kali Linux**: Special handling for netcat (checks `nc` command, installs `netcat-traditional` if needed)
- **Ubuntu/Debian**: Uses `netcat-openbsd` package
- **Package management**: Uses `needrestart` and standard apt tools
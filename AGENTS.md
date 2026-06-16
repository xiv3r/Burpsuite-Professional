# Repository Guidelines

This repository packages and installs Burp Suite Professional across Linux, macOS, Windows, and NixOS. It is a distribution/installer project, not a web application.

## Project Structure

- `install.sh` — Linux installer (`apt`/`wget`)
- `install_macos.sh` — macOS installer (`curl`/`jpackage`)
- `install.ps1` — Windows installer (PowerShell)
- `update.sh` — Linux updater
- `lib.sh` — Shared bash helpers (hash, version, download)
- `lib.ps1` — Shared PowerShell helpers
- `bootstrap.sh` — One-liner bootstrap that downloads `install.sh` + `lib.sh`
- `default.nix` / `flake.nix` / `flake.lock` — Nix/NixOS packaging
- `.github/workflows/burp-pro.yml` — CI release and test workflow
- `help.sh` — CLI helper that lists available scripts
- `tests/bats` — `bats` tests for bash scripts and `lib.sh`
- `tests/pester` — `Pester` tests for `lib.ps1`
- Binary assets: `loader.jar`, `launcher.jpg`, `burp_suite.icns`, `burp_suite.ico`

## Build, Test, and Development Commands

There is no build system. Verify scripts locally by reviewing, testing, and running them in a safe environment:

```bash
# Syntax check all bash scripts
bash -n install.sh update.sh install_macos.sh lib.sh bootstrap.sh help.sh

# Lint bash scripts
shellcheck install.sh update.sh install_macos.sh lib.sh bootstrap.sh help.sh

# Run bats tests (requires bats installed)
bats tests/bats/*.bats

# List available commands
./help.sh

# Inspect an installer before execution
cat install.sh
```

For PowerShell tests (requires Pester):

```powershell
Invoke-Pester -Path tests/pester
```

For Nix:

```bash
nix build .#burpsuitepro
```

## Coding Style and Naming Conventions

- Shell scripts use `#!/bin/bash` + `set -euo pipefail`.
- New shared bash helpers go in `lib.sh` and are sourced by installers using `$SCRIPT_DIR/lib.sh`.
- New shared PowerShell helpers go in `lib.ps1` and are dot-sourced using `Join-Path $PSScriptRoot 'lib.ps1'`.
- Quote all variable expansions, especially paths and URLs.
- Prefer absolute paths or `$BASH_SOURCE`/`$0` over `$(pwd)` in generated launchers.
- PowerShell variables use `PascalCase`; batch output is generated inline.
- Version numbers must be centralized. `VERSION`, `BURP_SHA256`, and `LOADER_SHA256` are the single sources of truth.

## Testing Guidelines

Automated tests live in `tests/`:

1. `bats tests/bats/*.bats` covers bash helpers and script entry points.
2. `Invoke-Pester -Path tests/pester` covers PowerShell helpers.
3. CI runs both suites plus a `nix build .#burpsuitepro` smoke test on every PR.

Manual verification checklist (for releases and installer changes):

1. Run each installer in a fresh VM or container.
2. Confirm the generated launcher can start from a different working directory.
3. Check that `loader.jar` is present and referenced correctly as a Java agent.
4. On macOS, verify a full JDK with `jpackage` is installed, not just a JRE.
5. Run `bash -n` and `shellcheck` on every modified `.sh` file before committing.

## Commit and Pull Request Guidelines

- Use descriptive commit messages in the format: `area: what changed` (for example, `install.sh: add set -euo pipefail`).
- One logical change per commit.
- Pull requests should explain which platform was tested and any known risks.
- Do not include downloaded JARs, license keys, or personal loader output in commits.

## Security and Agent-Specific Instructions

- Never commit `loader.jar` activation keys, logs, or credentials.
- Downloaded binaries must be checked against known hashes before release.
- Treat installer output paths and Java argument construction as high-risk for quoting and injection bugs.
- Update README.md when install instructions, filenames, or version numbers change.

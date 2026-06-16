# Repository Guidelines

This repository packages and installs Burp Suite Professional across Linux, macOS, Windows, and NixOS. It is a distribution/installer project, not a web application.

## Project Structure

- `install.sh` — Linux installer (`apt`/`wget`)
- `install_macos.sh` — macOS installer (`curl`/`jpackage`)
- `install.ps1` — Windows installer (PowerShell)
- `update.sh` — Linux updater
- `default.nix` / `flake.nix` / `flake.lock` — Nix/NixOS packaging
- `.github/workflows/burp-pro.yml` — CI release workflow
- `help.sh` — CLI helper that lists available scripts
- `VERSION`, `BURP_SHA256`, `LOADER_SHA256` — single sources of truth for Burp JAR and loader
- `JDK21_SHA256`, `JRE8_SHA256` — expected hashes for Oracle JDK/JRE installers on Windows
- Binary assets: `loader.jar`, `launcher.jpg`, `burp_suite.icns`, `burp_suite.ico`

## Build, Test, and Development Commands

There is no build system or test suite. Verify scripts locally by reviewing and running them in a safe environment:

```bash
# Syntax check all bash scripts
bash -n install.sh update.sh install_macos.sh help.sh

# Lint bash scripts
shellcheck install.sh update.sh install_macos.sh help.sh

# List available commands
./help.sh

# Inspect an installer before execution
cat install.sh
```

For Nix:

```bash
nix build .#burpsuitepro
```

## Coding Style and Naming Conventions

- Shell scripts use `#!/bin/bash` + `set -euo pipefail`.
- Use `set -euo pipefail` in new bash scripts for safer execution.
- Quote all variable expansions, especially paths and URLs.
- Prefer absolute paths or `$BASH_SOURCE`/`$0` over `$(pwd)` in generated launchers.
- PowerShell variables use `PascalCase`; batch output is generated inline.
- Version numbers and binary hashes must be centralized in their respective files at the repo root.

## Testing Guidelines

No automated tests exist. Manual verification checklist:

1. Run each installer in a fresh VM or container.
2. Confirm the generated launcher can start from a different working directory.
3. Check that `loader.jar` is present and referenced correctly as a Java agent.
4. On macOS, verify a full JDK with `jpackage` is installed, not just a JRE.
5. On Windows, confirm `JDK21_SHA256` and `JRE8_SHA256` match the actual Oracle installer bytes before updating them.

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

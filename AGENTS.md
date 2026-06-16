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
- Binary assets: `loader.jar`, `launcher.jpg`, `burp_suite.icns`, `burp_suite.ico`

## Build, Test, and Development Commands

There is no build system or test suite. Verify scripts locally by reviewing and running them in a safe environment:

```bash
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

- Shell scripts use `#!/bin/bash` except `install_macos.sh`, which currently lacks a shebang.
- Use `set -euo pipefail` in new bash scripts for safer execution.
- Quote all variable expansions, especially paths and URLs.
- Prefer absolute paths or `$BASH_SOURCE`/`$0` over `$(pwd)` in generated launchers.
- PowerShell variables use `PascalCase`; batch output is generated inline.
- Version numbers must be centralized. Currently `2025`, `2026`, and `2025.1.1` are used inconsistently across files.

## Testing Guidelines

No automated tests exist. Manual verification checklist:

1. Run each installer in a fresh VM or container.
2. Confirm the generated launcher can start from a different working directory.
3. Check that `loader.jar` is present and referenced correctly as a Java agent.
4. On macOS, verify a full JDK with `jpackage` is installed, not just a JRE.

## Commit and Pull Request Guidelines

Recent commit history is sparse (`Fix`, `docs: replace README.md...`). When contributing:

- Use descriptive commit messages in the format: `area: what changed` (for example, `install.sh: add set -euo pipefail`).
- One logical change per commit.
- Pull requests should explain which platform was tested and any known risks.
- Do not include downloaded JARs, license keys, or personal loader output in commits.

## Security and Agent-Specific Instructions

- Never commit `loader.jar` activation keys, logs, or credentials.
- Downloaded binaries must be checked against known hashes before release.
- Treat installer output paths and Java argument construction as high-risk for quoting and injection bugs.
- Update README.md when install instructions, filenames, or version numbers change.

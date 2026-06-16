# Burpsuite-Professional

Multi-platform installer and distribution for Burp Suite Professional. This repository provides shell, PowerShell, and Nix installers that download the pinned Burp JAR, attach the bundled `loader.jar` Java agent, and create platform-native launchers. It is not a web application.

## Files overview

| File | Description |
|------|-------------|
| `install.sh` | Linux installer. Installs dependencies, clones the repo into `$HOME/Burpsuite-Professional`, downloads the Burp JAR, verifies its SHA-256 hash, and installs a `burpsuitepro` system launcher. |
| `update.sh` | Linux updater. Refreshes the install directory, downloads the pinned Burp JAR, verifies the hash, and atomically replaces `/bin/burpsuitepro`. |
| `install_macos.sh` | macOS installer. Requires a full JDK with `jpackage`. Creates a `burp` command-line launcher and a `~/Applications/Burp Suite Professional.app` bundle. |
| `install.ps1` | Windows installer. Detects or downloads Oracle JDK 21 and JRE 8, downloads the Burp JAR, verifies the hash, and creates `Burp.bat` and `Burp-Suite-Pro.vbs`. |
| `default.nix` | Nix derivation for `burpsuitepro`, reading `VERSION` and `BURP_SHA256`. |
| `flake.nix` | Nix flake exposing the `burpsuitepro` package for supported systems. |
| `help.sh` | Prints available commands and a short activation guide. |
| `loader.jar` | Java agent / key loader bundled with the distribution. |
| `launcher.jpg`, `burp_suite.ico`, `burp_suite.icns` | Launcher and application icons. |
| `BURP_SHA256` | Expected SHA-256 hash of the downloaded Burp JAR. |
| `LOADER_SHA256` | Expected SHA-256 hash of the bundled `loader.jar`. |

## Versioning

`VERSION` and `BURP_SHA256` are the single sources of truth for the Burp Suite Professional JAR version and its SHA-256 hash.

- All installers (`install.sh`, `update.sh`, `install_macos.sh`, `install.ps1`) read the version from `VERSION` and verify the downloaded JAR against `BURP_SHA256`.
- The Nix derivation (`default.nix`) imports both files directly.
- The CI workflow (`.github/workflows/burp-pro.yml`) reads both values and verifies the release artifact before publishing.

If you need to update Burp Suite Professional, change both files together and verify the new hash before running any installer.

## Linux

Run the installer:

```bash
./install.sh
```

The script:

1. Updates packages and installs `git`, `wget`, and `openjdk-21-jre` via `apt` (requires `sudo`).
2. Clones or pulls the repo into `$HOME/Burpsuite-Professional`.
3. Downloads `burpsuite_pro_v${VERSION}.jar` from the GitHub release mirror.
4. Verifies the JAR against `BURP_SHA256`.
5. Writes a `burpsuitepro` launcher script and copies it to `/bin/burpsuitepro` (requires `sudo` unless already root).
6. Starts the key loader and Burp Suite Professional.

After installation, run Burp from anywhere with:

```bash
burpsuitepro
```

To update later, run `update.sh` from the install directory or re-run `install.sh`.

## macOS

Run the installer:

```bash
./install_macos.sh
```

Prerequisites:

- A full JDK that includes `jpackage` (e.g., `brew install openjdk@17`). A JRE-only installation is not sufficient.
- `git` and `curl` (usually installed with the JDK or via Homebrew).

The script:

1. Clones or pulls the repo into `$HOME/Burpsuite-Professional`.
2. Downloads `burpsuite_pro_v${VERSION}.jar` and verifies its SHA-256 hash.
3. Starts the key loader and Burp Suite Professional.
4. Creates a `burp` launcher in `$HOME/Burpsuite-Professional` that changes into the install directory before launching, so it works from any working directory.
5. Uses `jpackage` to build `~/Applications/Burp Suite Professional.app`.

After installation, run from the install directory:

```bash
~/Burpsuite-Professional/burp
```

Or open the app bundle from `~/Applications/Burp Suite Professional.app`.

## Windows

Open PowerShell and run:

```powershell
.\install.ps1
```

The script:

1. Checks the registry for Oracle JDK 21 and JRE 8; downloads and installs them if either is missing.
2. Downloads `burpsuite_pro_v${VERSION}.jar` from the GitHub release mirror.
3. Verifies the JAR against `BURP_SHA256`.
4. Creates `Burp.bat` in the current directory with the full Java invocation.
5. Creates `Burp-Suite-Pro.vbs` for background execution.
6. Starts the key loader and Burp Suite Professional.

After installation, double-click `Burp-Suite-Pro.vbs` or run `Burp.bat` from the directory where you ran `install.ps1`.

## Nix/NixOS

Build and run with:

```bash
nix build .#burpsuitepro
./result/bin/burpsuitepro
```

The flake supports `x86_64-linux`, `aarch64-linux`, `aarch64-darwin` and `x86_64-darwin`. Linux systems use an FHS environment (`buildFHSEnv`), while macOS uses a native `mkDerivation` wrapper. On Apple Silicon or other unsupported systems, you can also use `install_macos.sh`.

## Security notes

- Do not commit `loader.jar` activation keys, logs, or other generated artifacts.
- The Burp JAR hash in `BURP_SHA256` is verified by every installer and by CI before a release is published.
- The bundled `loader.jar` hash in `LOADER_SHA256` is also verified by every installer before execution.
- All downloaded binaries are pinned to the version in `VERSION` and the hash in `BURP_SHA256`; the installers fail if the hash does not match.
- Keep `VERSION`, `BURP_SHA256`, and `LOADER_SHA256` in sync and verify hashes from a trusted source before updating them.
- Oracle JDK 21 / JRE 8 installer downloads on Windows are not hash-verified by this project because Oracle does not publish stable, machine-readable hashes for those executables. Pre-install the JDK/JRE yourself if you do not want to trust Oracle's distribution channel.
## Attributions

- `loader.jar`: [h3110w0r1d-y/BurpLoaderKeygen](https://github.com/h3110w0r1d-y/BurpLoaderKeygen)
- Script foundation: [cyb3rzest/Burp-Suite-Pro](https://github.com/cyb3rzest/Burp-Suite-Pro)

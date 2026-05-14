# Security Notes

This repository contains scripts that download and execute Java archives. Treat every downloaded JAR as executable code.

Recommended practices:

- Prefer `./install_linux.sh` over piping remote scripts into a root shell.
- Review downloaded files before running them.
- Avoid running installer scripts as root unless a specific operation needs privilege escalation.
- Keep local work committed or backed up before using update features.
- Treat `loader.jar` as untrusted unless you built and verified it yourself.

Known risk areas:

- Java agents can modify application behavior at runtime.
- `-noverify` disables JVM bytecode verification and reduces runtime safety checks.
- Legacy Windows and macOS scripts have not received the same hardening pass as `install_linux.sh`.

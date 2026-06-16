# PLAN — Resolução de pendências

> Documento canônico de planejamento. Última execução concluída em 2026-06-16.
> Fork com a implementação: https://github.com/brainbloodbarrier/Burpsuite-Professional

## 0. Execução concluída — P0/P1/P2

| Item | Commit | Resultado |
|------|--------|-----------|
| P0.2 `update.sh` enxuto | `4c6f434` | Sem `apt` recorrente; só git pull + refresh JAR/loader + launcher atômico |
| P0.1 push | — | Fork criado e tudo empurrido |
| P1.1 `Launcher.jpg` duplicado | `6ab9f1b` | Removido capital L |
| P1.2 branch órfã | — | Deletada |
| P2.1 `AGENTS.md` | `141a8fb` | Commitado |
| P2.2 `help.sh` strict mode | `0412859` | `set -euo pipefail` + guarda `${1:-}` |

PR: https://github.com/xiv3r/Burpsuite-Professional/pull/134

## 1. Batch 1 — DRY hash checks (P2.3) — CONCLUÍDO

Arquivos novos: `lib.sh`, `lib.ps1`, `bootstrap.sh`.
Scripts portados: `install.sh`, `update.sh`, `install_macos.sh`, `install.ps1`.

PR: https://github.com/xiv3r/Burpsuite-Professional/pull/139
Issue no fork: https://github.com/brainbloodbarrier/Burpsuite-Professional/issues/1

## 2. Batch 2 — Hash-pin Oracle JDK/JRE (P3) — CONCLUÍDO

Arquivos novos: `JDK21_SHA256`, `JRE8_SHA256`.
`install.ps1` agora verifica SHA-256 dos instaladores Oracle antes de executá-los.

Hashes capturados em 2026-06-16:
- JDK 21: `cb2f25671cabbde70f8a46bdf67210313038efe275e26d00340d617ec62862a8`
- JRE 8: `419328f3a2325b1dc27f710abd73e232e9deac47915b4dba61a697b925b5b83d`

PR: https://github.com/xiv3r/Burpsuite-Professional/pull/140
Issue no fork: https://github.com/brainbloodbarrier/Burpsuite-Professional/issues/2

## 3. Batch 3 — Testes automatizados (P3) — CONCLUÍDO

Arquivos novos:
- `tests/bats/lib.bats`
- `tests/bats/help.bats`
- `tests/bats/update.bats`
- `tests/pester/lib.Tests.ps1`

CI: `.github/workflows/burp-pro.yml` ganhou job `test` com bats, Pester e `nix build`.

PR: https://github.com/xiv3r/Burpsuite-Professional/pull/141
Issue no fork: https://github.com/brainbloodbarrier/Burpsuite-Professional/issues/3

## 4. Batch 4 — Nix além do x86_64-linux (P3) — CONCLUÍDO

Arquivos novos: `darwin.nix`.
`flake.nix` agora suporta `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`, `x86_64-darwin`.
Linux continua usando `buildFHSEnv`; macOS usa `mkDerivation` com `makeWrapper`.

PR: https://github.com/xiv3r/Burpsuite-Professional/pull/142
Issue no fork: https://github.com/brainbloodbarrier/Burpsuite-Professional/issues/4

## 5. Labels criadas no fork

`refactor`, `hardening`, `future-work`, `nix`, `windows`, `testing`.

## 6. Serena memories

Memórias do projeto criadas em `/Users/fax/.serena/projects/sec-burp/memory/`:
- `mem:core`
- `mem:tech_stack`
- `mem:conventions`
- `mem:suggested_commands`
- `mem:task_completion`
- `mem:onboarding`

Valide com `serena memories check` no project root.

## 7. Próximos passos recomendados

1. Acompanhar/revisar os PRs #134, #139, #140, #141, #142 no upstream.
2. Responder aos comentários do Copilot (já solicitado review nos PRs novos).
3. Após merge do #134, eventualmente sincronizar `main` do fork com upstream.
4. Considerar proteger branches ou adicionar checks no fork.

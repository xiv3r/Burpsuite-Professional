# PLAN — Resolução de pendências

> Documento canônico de planejamento. Última execução concluída em 2026-06-16.
> PR com o ciclo P0/P1/P2 entregue: https://github.com/xiv3r/Burpsuite-Professional/pull/134
> PR com o Batch 1 (P2.3 DRY): https://github.com/xiv3r/Burpsuite-Professional/pull/135 (assim que criado)
> Fork com a implementação: https://github.com/brainbloodbarrier/Burpsuite-Professional

## 0. Execução concluída — P0/P1/P2

- Branch: `main` no fork `brainbloodbarrier/Burpsuite-Professional`.
- 10 commits à frente do upstream `origin/main` (`xiv3r/Burpsuite-Professional`).
- PR #134 aberto e com review do Copilot.

| Item | Commit | Resultado |
|------|--------|-----------|
| P0.2 `update.sh` enxuto | `4c6f434` | Sem `apt` recorrente; só git pull + refresh JAR/loader + launcher atômico |
| P0.1 push | — | Fork criado e tudo empurrado |
| P1.1 `Launcher.jpg` duplicado | `6ab9f1b` | Removido capital L |
| P1.2 branch órfã | — | Deletada |
| P2.1 `AGENTS.md` | `141a8fb` | Commitado |
| P2.2 `help.sh` strict mode | `0412859` | `set -euo pipefail` + guarda `${1:-}` |

## 1. Batch 1 — DRY hash checks (P2.3) — EM ANDAMENTO / CONCLUÍDO LOCAL

### Arquivos novos

- `lib.sh` — helpers bash: `read_value`, `read_version`, `hash_sha256`, `verify_sha256`, `download_with_hash`, `require_command`, `verify_loader`.
- `lib.ps1` — helpers PowerShell: `Read-NormalizedValue`, `Read-BurpVersion`, `Get-Sha256`, `Test-Sha256`, `Invoke-DownloadWithHash`, `Test-LoaderHash`.
- `bootstrap.sh` — one-liner bootstrap que baixa `install.sh` + `lib.sh` de uma ref/tag e executa.

### Scripts portados

- `install.sh` — usa `lib.sh`.
- `update.sh` — usa `lib.sh`.
- `install_macos.sh` — usa `lib.sh`.
- `install.ps1` — usa `lib.ps1`.

### Commits do Batch 1

| Commit | Descrição |
|--------|-----------|
| `969f05c` | `lib: add shared hash/version helpers for bash and powershell` |
| `eac744a` | `installers: source shared lib.* helpers to DRY hash checks` |
| `b9f835f` | `bootstrap: add one-liner helper that downloads install.sh + lib.sh` |
| `6b14f9f` | `docs: update AGENTS.md for lib.sh, lib.ps1 and bootstrap.sh` |

### Verificação local

- `bash -n install.sh update.sh install_macos.sh lib.sh bootstrap.sh help.sh` — todos passam.
- `shellcheck install.sh update.sh install_macos.sh lib.sh bootstrap.sh help.sh` — sem warnings.
- `lib.sh` smoke: `read_version` retorna `2026`, `verify_loader` passa, `verify_sha256` passa.
- `lib.ps1` não foi parseada localmente porque `pwsh` não está instalado nesta máquina — verificação fica para CI/VM Windows.

### Issues / PRs

- Issue no fork: https://github.com/brainbloodbarrier/Burpsuite-Professional/issues/1
- PR para upstream: **a ser criado** (ver §4).

## 2. Trabalho futuro — batches sequenciais

| Batch | Issue no fork | Título | Labels | Dependências |
|-------|---------------|--------|--------|--------------|
| **Batch 2** | #2 | Hash-pin Oracle JDK 21 / JRE 8 downloads in `install.ps1` | `windows`, `hardening`, `future-work` | Nenhuma |
| **Batch 3** | #3 | Add automated tests for installers | `testing`, `future-work` | Batch 1 (API estável) |
| **Batch 4** | #4 | Nix flake support beyond x86_64-linux | `nix`, `future-work` | Batch 1 recomendado |

Labels criadas no fork: `refactor`, `hardening`, `future-work`, `nix`, `windows`, `testing`.

## 3. Recomendação de sequência

1. **Merge PR #134** (P0/P1/P2).
2. **Abrir PR #135** (Batch 1 — DRY hash checks) e aguardar merge.
3. **Batch 2** em paralelo seguro com Batch 1 (toca arquivo diferente: `install.ps1` + hash files).
4. **Batch 3** após merge do Batch 1 (testes dependem da API de `lib.sh`/`lib.ps1`).
5. **Batch 4** após merge do Batch 1 (pode reaproveitar leitura de hashes).

## 4. Próxima ação imediata

Abrir PR #135 para o upstream com os 4 commits do Batch 1.

```bash
cd Burpsuite-Professional
gh pr create --repo xiv3r/Burpsuite-Professional \
  --base main \
  --head brainbloodbarrier:main \
  --title "refactor: DRY hash checks with lib.sh and lib.ps1" \
  --body-file .pr-batch1-body.md
```

## 5. Serena memories

Memórias do projeto criadas em `/Users/fax/.serena/projects/sec-burp/memory/`:
- `mem:core`
- `mem:tech_stack`
- `mem:conventions`
- `mem:suggested_commands`
- `mem:task_completion`
- `mem:onboarding`

Valide com `serena memories check` no project root.

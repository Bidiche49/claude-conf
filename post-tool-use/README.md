# post-tool-use

PostToolUse hook for Claude Code — automatic file manifest and test failure detection.

## Features

### File Manifest (Write/Edit)

Every `Write` or `Edit` operation is logged to a per-session manifest file:

```
.claude-sessions/manifests/{session_id}.txt
```

Format (one line per operation, append-only):

```
2026-03-21T14:32:00 WRITE src/cli.ts
2026-03-21T14:32:15 EDIT src/lib/validator.ts
2026-03-21T14:33:00 EDIT src/lib/validator.ts
```

The supervisor uses this manifest to cross-check worker reports — if the manifest lists files the worker didn't report (or vice versa), the divergence is flagged.

**Rotation:** only the 35 most recent manifest files are kept. Older ones are automatically deleted.

### Test Failure Detection (Bash)

When a `Bash` tool runs a test command (`test`, `pytest`, `jest`, `vitest`, `bun test`, `flutter test`, `cargo test`, `go test`, `rspec`, `phpunit`, `make test`) and the exit code is non-zero, the hook outputs:

```
[TEST-FAILURE] Tests failed (exit code: 1). Investigate before continuing.
```

This signal prompts the worker to investigate failures before moving on.

## Installation

```bash
bash install.sh
```

The installer:
1. Copies the hook to `~/.claude/hooks/post-tool-use.sh`
2. Creates `.claude-sessions/manifests/`
3. Adds a `PostToolUse` entry in `~/.claude/settings.json` (merge, not overwrite)

Requires: `jq`

## Disable

```bash
echo 'post-tool-use' >> ~/.claude-conf-disabled
```

---

# post-tool-use (FR)

Hook PostToolUse pour Claude Code — manifest automatique des fichiers et detection d'echecs de tests.

## Fonctionnalites

### Manifest fichiers (Write/Edit)

Chaque operation `Write` ou `Edit` est loguee dans un manifest par session :

```
.claude-sessions/manifests/{session_id}.txt
```

Format (une ligne par operation, append-only) :

```
2026-03-21T14:32:00 WRITE src/cli.ts
2026-03-21T14:32:15 EDIT src/lib/validator.ts
2026-03-21T14:33:00 EDIT src/lib/validator.ts
```

Le superviseur utilise ce manifest pour verifier les rapports des workers — si le manifest liste des fichiers non declares (ou inversement), la divergence est signalee.

**Rotation :** seuls les 35 manifests les plus recents sont conserves. Les plus anciens sont supprimes automatiquement.

### Detection echecs de tests (Bash)

Quand un outil `Bash` execute une commande de test (`test`, `pytest`, `jest`, `vitest`, `bun test`, `flutter test`, `cargo test`, `go test`, `rspec`, `phpunit`, `make test`) et que le code de sortie est non-zero, le hook affiche :

```
[TEST-FAILURE] Tests failed (exit code: 1). Investigate before continuing.
```

Ce signal pousse le worker a investiguer avant de continuer.

## Installation

```bash
bash install.sh
```

L'installeur :
1. Copie le hook vers `~/.claude/hooks/post-tool-use.sh`
2. Cree `.claude-sessions/manifests/`
3. Ajoute une entree `PostToolUse` dans `~/.claude/settings.json` (merge, pas ecrasement)

Necessite : `jq`

## Desactiver

```bash
echo 'post-tool-use' >> ~/.claude-conf-disabled
```

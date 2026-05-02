# post-tool-use

Hooks for Claude Code — file manifest, test failure detection, and worker session-id injection.

## Features

### File Manifest (Write/Edit) — `PostToolUse`

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

### Worker session-id injection — `SessionStart`

When a worker session starts (i.e. launched by the supervisor's launch script with `CC_WORKER_TICKET` exported), the SessionStart hook injects the worker's `session_id` and manifest path into the conversation as `additionalContext`:

```
[WORKER SESSION CONTEXT]
Ticket: BUG-042
Session ID: f6d1e037-81db-4de3-b52b-d57c17dcb972
Your manifest path: .claude-sessions/manifests/f6d1e037-81db-4de3-b52b-d57c17dcb972.txt
```

The worker uses this exact path in the `Manifest:` field of its report — no more `ls -t` discovery, which races with parallel workers and the supervisor's own writes.

The hook is a silent pass-through for any session that did NOT set `CC_WORKER_TICKET` (normal sessions, supervisor sessions, sessions in unrelated projects).

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
1. Copies the hooks to `~/.claude/hooks/post-tool-use.sh` and `~/.claude/hooks/post-tool-use-session-inject.sh`
2. Creates `.claude-sessions/manifests/`
3. Adds `PostToolUse` and `SessionStart` entries in `~/.claude/settings.json` (merge, not overwrite)

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

### Injection session-id worker — `SessionStart`

Quand une session worker demarre (lancee par le launch script du superviseur avec `CC_WORKER_TICKET` exporte), le hook SessionStart injecte le `session_id` et le path du manifest dans la conversation via `additionalContext`. Le worker utilise ce path exact dans son rapport — fini `ls -t` qui rentre en course avec les workers paralleles et avec les ecritures du superviseur lui-meme.

Le hook est un pass-through silencieux pour toute session qui n'a PAS `CC_WORKER_TICKET` (sessions normales, superviseur, sessions dans d'autres projets).

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

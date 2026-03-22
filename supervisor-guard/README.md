# supervisor-guard

**EN** | [FR](#fr)

## What it does

`supervisor-guard` is a Claude Code `PreToolUse` hook that enforces the supervisor's "no source code writing" rule mechanically.

When supervisor mode is active (marker file exists), all `Write` and `Edit` tool calls are checked against a whitelist. Only these paths are allowed:

- `BACKLOG/**` — ticket files
- `.claude-sessions/**` — handoff, manifests, prompts, scope files
- `**/INDEX.md` — backlog index

Everything else is blocked with a clear message telling the supervisor to generate a worker prompt instead.

## How it works

1. The supervisor creates a marker file at startup:
   ```
   .claude-sessions/supervisor-active/{session_id}
   ```

2. The hook checks every `Write`/`Edit` call:
   - No session_id → pass-through
   - No marker file → pass-through (normal mode, workers unaffected)
   - Marker exists → check whitelist → allow or block

3. The supervisor removes the marker at the end of session.

## Installation

```bash
bash supervisor-guard/install.sh
```

This will:
- Copy the hook to `~/.claude/hooks/supervisor-guard.sh`
- Add `PreToolUse` entries (Write + Edit) to `~/.claude/settings.json`
- Create `.claude-sessions/supervisor-active/` directory

## Disable

```bash
echo 'supervisor-guard' >> ~/.claude-conf-disabled
```

Or remove the hook entries from `~/.claude/settings.json`.

---

<a id="fr"></a>

## FR

### Ce que ca fait

`supervisor-guard` est un hook `PreToolUse` pour Claude Code qui applique mecaniquement la regle "le supervisor ne touche jamais au code source".

Quand le mode supervisor est actif (fichier marqueur present), tous les appels `Write` et `Edit` sont verifies contre une whitelist. Seuls ces chemins sont autorises :

- `BACKLOG/**` — fichiers de tickets
- `.claude-sessions/**` — handoff, manifests, prompts, fichiers de scope
- `**/INDEX.md` — index du backlog

Tout le reste est bloque avec un message clair demandant de generer un prompt worker a la place.

### Comment ca marche

1. Le supervisor cree un fichier marqueur au demarrage :
   ```
   .claude-sessions/supervisor-active/{session_id}
   ```

2. Le hook verifie chaque appel `Write`/`Edit` :
   - Pas de session_id → pass-through
   - Pas de fichier marqueur → pass-through (mode normal, workers non affectes)
   - Marqueur present → verification whitelist → autorise ou bloque

3. Le supervisor supprime le marqueur en fin de session.

### Installation

```bash
bash supervisor-guard/install.sh
```

### Desactiver

```bash
echo 'supervisor-guard' >> ~/.claude-conf-disabled
```

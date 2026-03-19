# handoff-kit

**Automatic session persistence and context-aware handoff for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).**

<p>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/shell-bash%20%7C%20zsh-green?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License">
</p>

> Part of [claude-conf](https://github.com/Bidiche49/claude-conf) — install standalone or with the full toolkit.

---

## The Problem

Long conversations in Claude Code eventually hit the context window limit. When that happens, automatic compaction discards part of the history — along with the current train of thought. You lose progress, decisions, and the thread of complex multi-step work.

## The Solution

**handoff-kit** gives you full visibility and control over your context budget with four complementary mechanisms:

| Component | Purpose |
|-----------|---------|
| **Statusline** | Displays real-time context usage percentage in the Claude Code status bar |
| **Context monitor** | Warns at 65%, forces a save at 80% |
| **`/handoff` command** | Generates a structured continuation prompt for the next session |
| **PreCompact backup** | Automatically saves the full transcript before any compaction |

The result: you never lose work to compaction again. When context runs low, you get a clean, structured prompt that lets you resume exactly where you left off in a new session.

## Installation

### Via claude-conf (recommended)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh       # Select handoff-kit from the menu
```

### Standalone

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/handoff-kit
./install.sh
```

The install script:

- Copies hooks, command, and statusline into `~/.claude/`
- Merges configuration into `~/.claude/settings.json` (preserves existing settings)
- Installs dependencies (picocolors via Bun)
- Creates working directories

### CLAUDE.md configuration

For Claude to react to context alerts, add these instructions to your `CLAUDE.md` (project-level or global `~/.claude/CLAUDE.md`):

```markdown
## Handoff Rules

### Signal `[SYSTEM-HANDOFF-WARNING]` (context 65-80%)
- Inform the user that context is approaching its limit
- Recommend running /handoff
- Continue working normally

### Signal `[SYSTEM-HANDOFF-CRITICAL]` (context > 80%)
1. Do NOT respond to the current request
2. Immediately execute the /handoff command
3. No other action
```

## Usage

**Automatic** — The system monitors context usage in the background. At 65%, Claude warns you. At 80%, a save is forced.

**Manual** — Run `/handoff` at any time to generate a continuation prompt.

**Resuming** — Copy the generated prompt and paste it into a new Claude Code conversation.

## How It Works

### Context monitor (`hooks/context-monitor.sh`)

A [UserPromptSubmit](https://docs.anthropic.com/en/docs/claude-code/hooks) hook that runs on every message. It reads the current context percentage (written by the statusline) and injects warning or critical signals into the conversation when thresholds are crossed.

### PreCompact backup (`hooks/pre-compact-handoff.sh`)

A [PreCompact](https://docs.anthropic.com/en/docs/claude-code/hooks) hook that triggers automatically when Claude Code is about to compact the conversation. It saves the full transcript to both a global and project-local backup directory before any data is lost.

### `/handoff` command (`commands/handoff.md`)

A [slash command](https://docs.anthropic.com/en/docs/claude-code/slash-commands) that instructs Claude to analyze the current session, extract all relevant context (progress, decisions, files, blockers), and generate a concise continuation prompt optimized for starting a new session.

### Statusline (`statusline/`)

A TypeScript application (run via Bun) that displays real-time context usage in the Claude Code status bar. It also writes the current percentage to a file that the context monitor reads.

## Advanced Configuration

**Alert thresholds** — Edit `~/.claude/hooks/context-monitor.sh`:

```bash
WARN_THRESHOLD=65      # Informational warning
CRITICAL_THRESHOLD=80  # Forced handoff
```

**Statusline appearance** — Edit `~/.claude/scripts/statusline/statusline.config.json` to customize the display (progress bar style, displayed information, separators).

## Architecture

```
~/.claude/
├── hooks/
│   ├── context-monitor.sh            # UserPromptSubmit hook — threshold detection
│   └── pre-compact-handoff.sh        # PreCompact hook — automatic backup
├── commands/
│   └── handoff.md                    # /handoff slash command
├── scripts/
│   └── statusline/                   # Real-time statusline (TypeScript + Bun)
├── context-data/                     # Per-session context percentage
└── handoff-system/
    ├── sessions/                     # Backup files
    ├── pending/                      # Pending user questions
    └── handoff.log                   # Handoff event log
```

## Uninstall

```bash
rm ~/.claude/hooks/context-monitor.sh
rm ~/.claude/hooks/pre-compact-handoff.sh
rm ~/.claude/commands/handoff.md
rm -rf ~/.claude/scripts/statusline
rm -rf ~/.claude/handoff-system
rm -rf ~/.claude/context-data
```

Then remove the `UserPromptSubmit`, `PreCompact`, and `statusLine` entries from `~/.claude/settings.json`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Bun](https://bun.sh) — `curl -fsSL https://bun.sh/install | bash`
- [jq](https://jqlang.github.io/jq/) — `brew install jq` (macOS) or `sudo apt install jq` (Linux)

## License

[MIT](../LICENSE)

---

<a id="francais"></a>

# Francais

## Le probleme

Les conversations longues dans Claude Code finissent par atteindre la limite de contexte. Quand ca arrive, le compactage automatique supprime une partie de l'historique — et avec lui, le fil de la reflexion en cours. Vous perdez votre progression, vos decisions, et le fil d'un travail complexe en plusieurs etapes.

## La solution

**handoff-kit** vous donne une visibilite et un controle complets sur votre budget de contexte grace a quatre mecanismes complementaires :

| Composant | Role |
|-----------|------|
| **Statusline** | Affiche le pourcentage de contexte utilise en temps reel dans la barre de statut |
| **Moniteur de contexte** | Alerte a 65%, force la sauvegarde a 80% |
| **Commande `/handoff`** | Genere un prompt de continuation structure pour la session suivante |
| **Backup PreCompact** | Sauvegarde automatique du transcript complet avant tout compactage |

Resultat : vous ne perdez plus jamais de travail a cause du compactage. Quand le contexte s'epuise, vous obtenez un prompt propre et structure qui vous permet de reprendre exactement ou vous en etiez.

## Installation

### Via claude-conf (recommande)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh       # Selectionnez handoff-kit dans le menu
```

### Installation autonome

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/handoff-kit
./install.sh
```

Le script d'installation :

- Copie les hooks, la commande et la statusline dans `~/.claude/`
- Merge la configuration dans `~/.claude/settings.json` (sans ecraser l'existant)
- Installe les dependances (picocolors via Bun)
- Cree les repertoires de travail

### Configuration CLAUDE.md

Pour que Claude reagisse aux alertes de contexte, ajoutez ces instructions dans votre `CLAUDE.md` (projet ou global `~/.claude/CLAUDE.md`) :

```markdown
## Regles Handoff

### Signal `[SYSTEM-HANDOFF-WARNING]` (contexte 65-80%)
- Informe l'utilisateur que le contexte approche de sa limite
- Recommande d'executer /handoff
- Continue le travail normalement

### Signal `[SYSTEM-HANDOFF-CRITICAL]` (contexte > 80%)
1. Ne reponds PAS a la demande en cours
2. Execute immediatement la commande /handoff
3. Aucune autre action
```

## Utilisation

**Automatique** — Le systeme surveille le contexte en arriere-plan. A 65%, Claude vous previent. A 80%, la sauvegarde est forcee.

**Manuelle** — Executez `/handoff` a tout moment pour generer un prompt de continuation.

**Reprise** — Copiez le prompt genere et collez-le dans une nouvelle conversation Claude Code.

## Fonctionnement

### Moniteur de contexte (`hooks/context-monitor.sh`)

Un hook [UserPromptSubmit](https://docs.anthropic.com/en/docs/claude-code/hooks) qui s'execute a chaque message. Il lit le pourcentage de contexte actuel (ecrit par la statusline) et injecte des signaux d'avertissement ou critiques dans la conversation.

### Backup PreCompact (`hooks/pre-compact-handoff.sh`)

Un hook [PreCompact](https://docs.anthropic.com/en/docs/claude-code/hooks) qui se declenche automatiquement quand Claude Code s'apprete a compacter. Il sauvegarde le transcript complet dans un repertoire de backup global et local au projet.

### Commande `/handoff` (`commands/handoff.md`)

Une [commande slash](https://docs.anthropic.com/en/docs/claude-code/slash-commands) qui demande a Claude d'analyser la session, d'extraire tout le contexte pertinent (progression, decisions, fichiers, blocages) et de generer un prompt de continuation optimise.

### Statusline (`statusline/`)

Une application TypeScript (executee via Bun) qui affiche l'utilisation du contexte en temps reel. Elle ecrit aussi le pourcentage dans un fichier lu par le moniteur de contexte.

## Configuration avancee

**Seuils d'alerte** — Editer `~/.claude/hooks/context-monitor.sh` :

```bash
WARN_THRESHOLD=65      # Alerte informative
CRITICAL_THRESHOLD=80  # Handoff force
```

**Apparence de la statusline** — Editer `~/.claude/scripts/statusline/statusline.config.json` pour personnaliser l'affichage (style de barre de progression, informations affichees, separateurs).

## Architecture

```
~/.claude/
├── hooks/
│   ├── context-monitor.sh            # Hook UserPromptSubmit — detection du seuil
│   └── pre-compact-handoff.sh        # Hook PreCompact — backup automatique
├── commands/
│   └── handoff.md                    # Commande /handoff
├── scripts/
│   └── statusline/                   # Statusline temps reel (TypeScript + Bun)
├── context-data/                     # Pourcentage de contexte par session
└── handoff-system/
    ├── sessions/                     # Fichiers de sauvegarde
    ├── pending/                      # Questions utilisateur en attente
    └── handoff.log                   # Journal des handoffs
```

## Desinstallation

```bash
rm ~/.claude/hooks/context-monitor.sh
rm ~/.claude/hooks/pre-compact-handoff.sh
rm ~/.claude/commands/handoff.md
rm -rf ~/.claude/scripts/statusline
rm -rf ~/.claude/handoff-system
rm -rf ~/.claude/context-data
```

Retirez ensuite les entrees `UserPromptSubmit`, `PreCompact` et `statusLine` de `~/.claude/settings.json`.

## Prerequis

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Bun](https://bun.sh) — `curl -fsSL https://bun.sh/install | bash`
- [jq](https://jqlang.github.io/jq/) — `brew install jq` (macOS) ou `sudo apt install jq` (Linux)

## Licence

[MIT](../LICENSE)

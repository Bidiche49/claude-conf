# tab-titles

**Smart terminal tab titles for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions.**

<p>
  <img src="https://img.shields.io/badge/platform-macOS-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/shell-zsh-green?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License">
</p>

> Part of [claude-conf](https://github.com/Bidiche49/claude-conf) — install standalone or with the full toolkit.

---

## The Problem

You're deep in a project. You have five Claude Code tabs open — a supervisor session, two workers on different tickets, a quick debug session. You cmd-tab back to Terminal and... they all say `claude`. Good luck finding the right one.

## The Solution

**tab-titles** gives each session a distinct, readable tab title that updates in real time:

| Command | Tab Title | Use Case |
|---------|-----------|----------|
| `cc` | `⚡ CC · my-project` | Normal session |
| `ccs` | `🔴 SUP · my-project` | Supervisor mode |
| `ccw BUG-101` | `🟢 BUG-101 · my-project` | Worker on a ticket |
| `ccd` | `⚡ CC · my-project` | Skip-permissions mode |

The project name is detected automatically from your working directory.

Titles update **dynamically** during the session — type `/supervisor` in a `cc` session and the title switches to `🔴 SUP` without restarting.

<!-- TODO: Add screenshot -->
<!-- ![Demo](assets/demo.png) -->

## Installation

### Via claude-conf (recommended)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh       # Select tab-titles from the menu
```

### Standalone

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/tab-titles
bash install.sh
source ~/.zshrc
```

### One-time Terminal.app setup

Go to **Terminal > Settings > Profiles > Tab** and uncheck **"Active process name"**.

This prevents Terminal.app from overwriting custom tab titles with the running process name.

> **iTerm2 users:** Go to Preferences > Profiles > Terminal > uncheck "Terminal may set tab/window title".

## How It Works

Two components work together:

### 1. Shell functions (`.zshrc`)

The installer adds `cc`, `ccs`, `ccw`, and `ccd` functions to your `.zshrc`. Each one:

- Sets the initial tab title via the OSC 1 escape sequence
- Sets `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` to prevent Claude Code from overwriting it
- Launches `claude` with any extra arguments you pass through

### 2. Hook script (`tab-title.sh`)

A Claude Code [UserPromptSubmit hook](https://docs.anthropic.com/en/docs/claude-code/hooks) that runs on every message. It:

- Parses your prompt for mode indicators (`/supervisor`, ticket IDs like `BUG-101`)
- Updates the tab title dynamically without restarting the session
- Stores mode state in `/tmp/cc-tab-*` files (auto-cleaned on reboot)

## Configuration

### Manual hook setup

If the install script cannot auto-configure `settings.json`, add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tab-title.sh"
          }
        ]
      }
    ]
  }
}
```

If you already have `UserPromptSubmit` hooks, add a new entry to the existing array.

### Customization

**Change the icons** — Edit the shell functions in `.zshrc` and the `case` block in `hooks/tab-title.sh`:

```bash
# Use text tags instead of emojis
_cc_set_title "[CC] $(basename "$PWD")"    # instead of ⚡
_cc_set_title "[SUP] $(basename "$PWD")"   # instead of 🔴
```

**Add custom modes** — Edit `hooks/tab-title.sh` to detect new patterns:

```bash
# Detect a /review mode
if echo "$PROMPT" | grep -qi '/review'; then
    echo "REVIEW" > "$STATE_FILE"
fi

# Add to the case block:
REVIEW)
    TITLE="🔵 REVIEW · ${PROJECT}"
    ;;
```

**Change the ticket pattern** — By default, the hook detects `BUG-XXX`, `FEAT-XXX`, and `IMP-XXX`. Edit the grep pattern in `tab-title.sh` to match your format:

```bash
# JIRA-style tickets
TICKET_MATCH=$(echo "$PROMPT" | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

## Uninstall

```bash
# Remove the hook
rm ~/.claude/hooks/tab-title.sh

# Remove the UserPromptSubmit entry for tab-title.sh from ~/.claude/settings.json

# Remove shell functions from ~/.zshrc
# Delete lines between "# ── Claude Code Tab Titles" and "# ── End Claude Code Tab Titles"
```

## Requirements

- macOS with **Terminal.app** or **iTerm2**
- **zsh** (default on macOS)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- **jq** (`brew install jq`)

## License

[MIT](../LICENSE)

---

<a id="francais"></a>

# Francais

## Le probleme

Vous travaillez sur un projet. Cinq onglets Claude Code ouverts — un superviseur, deux workers sur des tickets differents, une session de debug rapide. Vous faites cmd-tab vers le Terminal et... ils affichent tous `claude`. Bonne chance pour retrouver le bon.

## La solution

**tab-titles** donne a chaque session un titre d'onglet distinct et lisible, mis a jour en temps reel :

| Commande | Titre de l'onglet | Usage |
|----------|-------------------|-------|
| `cc` | `⚡ CC · mon-projet` | Session normale |
| `ccs` | `🔴 SUP · mon-projet` | Mode superviseur |
| `ccw BUG-101` | `🟢 BUG-101 · mon-projet` | Worker sur un ticket |
| `ccd` | `⚡ CC · mon-projet` | Mode skip-permissions |

Le nom du projet est detecte automatiquement depuis votre repertoire de travail.

Les titres se mettent a jour **dynamiquement** — tapez `/supervisor` dans une session `cc` et le titre passe a `🔴 SUP` sans redemarrage.

## Installation

### Via claude-conf (recommande)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh       # Selectionnez tab-titles dans le menu
```

### Installation autonome

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/tab-titles
bash install.sh
source ~/.zshrc
```

### Configuration Terminal.app (une seule fois)

Allez dans **Terminal > Reglages > Profils > onglet Tab** et decochez **"Active process name"**.

> **Utilisateurs iTerm2 :** Preferences > Profiles > Terminal > decochez "Terminal may set tab/window title".

## Fonctionnement

Deux composants cooperent :

1. **Fonctions shell** (`.zshrc`) — `cc`, `ccs`, `ccw`, `ccd` definissent le titre initial et lancent Claude Code avec le flag qui empeche l'ecrasement du titre.

2. **Script hook** (`tab-title.sh`) — Un hook [UserPromptSubmit](https://docs.anthropic.com/en/docs/claude-code/hooks) qui detecte les changements de mode (`/supervisor`, tickets) et met a jour le titre dynamiquement.

## Personnalisation

- **Icones** : Modifiez les fonctions shell dans `.zshrc` et le bloc `case` dans `hooks/tab-title.sh`
- **Nouveaux modes** : Ajoutez des patterns de detection dans `tab-title.sh`
- **Format de tickets** : Modifiez le pattern grep pour correspondre a votre convention (JIRA, etc.)

## Desinstallation

```bash
rm ~/.claude/hooks/tab-title.sh
# Retirez l'entree UserPromptSubmit pour tab-title.sh de ~/.claude/settings.json
# Supprimez les fonctions entre les marqueurs dans ~/.zshrc
```

## Prerequis

- macOS avec **Terminal.app** ou **iTerm2**
- **zsh** (par defaut sur macOS)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- **jq** (`brew install jq`)

## Licence

[MIT](../LICENSE)

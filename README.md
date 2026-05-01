<p align="center">
  <h1 align="center">claude-conf</h1>
  <p align="center">A modular toolkit for supercharging your Claude Code workflow</p>
</p>

<p align="center">
  <a href="#modules">Modules</a> &bull;
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#requirements">Requirements</a> &bull;
  <a href="#contributing">Contributing</a> &bull;
  <a href="#francais">Francais</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/shell-zsh%20%7C%20bash-green?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License">
  <img src="https://img.shields.io/github/stars/Bidiche49/claude-conf?style=flat-square" alt="Stars">
</p>

---

## Why?

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is powerful out of the box — but power users quickly run into friction:

- **Too many terminal tabs** and no way to tell sessions apart
- **Context window fills up** and compaction silently discards your progress
- **No session continuity** when you need to pick up where you left off

**claude-conf** is a collection of independent, install-what-you-need modules that solve these problems through Claude Code's native [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands), and [statusline](https://docs.anthropic.com/en/docs/claude-code/statusline) systems.

## Modules

| Module | Description | Status |
|--------|-------------|--------|
| [**tab-titles**](tab-titles/) | Smart terminal tab titles that reflect session mode and project | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**handoff-kit**](handoff-kit/) | Context monitoring, automatic backups, and structured session handoff | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**supervisor**](supervisor/) | CTO mode — investigate, delegate to workers, validate, never write code | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**command-guard**](command-guard/) | PreToolUse hook that validates every shell command before execution | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**critical-thinking**](critical-thinking/) | Anti-complacency rules — sparring partner mode for Claude Code | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**pre-commit-gate**](pre-commit-gate/) | Reminder to run /check before committing — with universal stack detection | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**backlog-kit**](backlog-kit/) | Universal ticketing system with automatic ID protection | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**claude-md-kit**](claude-md-kit/) | Three slash commands to generate, clean up, and optimize CLAUDE.md | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |
| [**code-index**](code-index/) | Auto-indexed codebase navigation — 87-91% token saving, Dart native + TS/Python/Go/Rust via slash command | ![Ready](https://img.shields.io/badge/status-ready-brightgreen?style=flat-square) |

Each module works **standalone** or as part of this collection. Install only what you need.

## Quick Start

### Install everything

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh --all
```

### Pick and choose (interactive)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh
```

The interactive installer lists available modules and lets you select which ones to install.

### Install a single module

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/tab-titles
bash install.sh
```

## Module Overview

### tab-titles

Automatically sets your terminal tab title based on the type of Claude Code session you're running. Supervisor mode, worker tickets, normal sessions — each gets a distinct, readable title. Titles update dynamically as you switch modes within a session.

```
⚡ CC · my-project          Normal session
🔴 SUP · my-project         Supervisor mode
🟢 BUG-101 · my-project     Working on a ticket
```

[Full documentation >>>](tab-titles/)

### handoff-kit

Monitors your context window usage in real time. Warns you before compaction hits. Generates structured continuation prompts so you can seamlessly resume work in a new session without losing context or progress.

**Components:** statusline display, context monitor hook, pre-compaction backup hook, `/handoff` slash command.

[Full documentation >>>](handoff-kit/)

### supervisor

Turns Claude Code into a strict CTO that never writes code. It investigates problems, creates detailed tickets, generates scoped worker prompts for separate sessions, validates reports, and commits. The supervisor/worker split brings the rigor of a two-person review process to solo development.

**Components:** `/supervisor` slash command.

[Full documentation >>>](supervisor/)

### command-guard

A security layer that intercepts every Bash command before Claude Code executes it. Three-tier validation: **DENY** (hard block, even with `--dangerously-skip-permissions`), **ASK** (requires confirmation), **ALLOW** (pass through). Catches `rm -rf` in all its forms, flags dangerous commands like `sudo`, `chmod`, `kill`, and logs every security event.

**Components:** PreToolUse hook (TypeScript/Bun).

[Full documentation >>>](command-guard/)

### critical-thinking

Anti-complacency module for Claude Code. Turns Claude into a technical sparring partner that challenges ideas instead of validating by default. Features a 5-marker classification system (Solide / Discutable / Simplifie / Angle mort / Faux), 5 anti-complacency reflexes (stress-test, hold position, detect errors, iterate, self-diagnose), and a 3-validation rule that triggers active fault-finding after 3 consecutive approvals.

**Components:** rule injection into `~/.claude/CLAUDE.md`, optional CTO POSTURE patch for supervisor.

[Full documentation >>>](critical-thinking/)

### pre-commit-gate

Reminder to run `/check` before committing, with a universal validation command. The PreToolUse hook detects `git commit` and reminds you to run `/check` first (never blocks). The `/check` command auto-detects your project stack (Node, Flutter, Go, Rust, Python, Ruby, PHP, Swift, Make) and runs the full lint + build + tests pipeline.

**Components:** PreToolUse hook (Bash), `/check` slash command.

[Full documentation >>>](pre-commit-gate/)

### backlog-kit

Universal ticketing system for Claude Code with automatic ID protection. Manages three ticket types (bugs, features, improvements) with structured templates and priority/complexity conventions. The backlog-guard hook (PreToolUse Write) blocks duplicate ticket IDs across concurrent sessions. INDEX.md is auto-generated and never manually edited.

**Components:** backlog-guard hook, `/backlog-init`, `/backlog-bug`, `/backlog-feat`, `/backlog-imp`, `/backlog-status` slash commands.

[Full documentation >>>](backlog-kit/)

### claude-md-kit

Three slash commands for managing your project's CLAUDE.md. `/claude-md-init` generates a CLAUDE.md from scratch by analyzing your codebase. `/claude-md-cleanup` removes duplicates with global config and generic filler. `/claude-md-boost` rewrites the CLAUDE.md with expert prompt engineering and stack-specific conventions. All three commands analyze real code and ask for validation before writing.

**Components:** `/claude-md-init`, `/claude-md-cleanup`, `/claude-md-boost` slash commands.

[Full documentation >>>](claude-md-kit/)

### code-index

Auto-indexed codebase navigation. Generates per-directory markdown outlines with line numbers under `docs/.code-map/` so Claude Code can locate symbols and read targeted slices instead of full files. Measured token saving: **87-91%** on a real Flutter codebase. Dart/Flutter is supported natively (one-command setup, AOT-compiled hooks, ~0.2s per commit). Other stacks (TypeScript, Python, Go, Rust) bootstrap on first use via the `/code-index-bootstrap` slash command, which generates a stack-equivalent indexer using the **official AST parser** of the language and validates the output against a strict format contract (≥ 50% token saving enforced).

**Components:** per-project setup script, `tool/code_index.dart` indexer, 4 git hooks, `/code-index-bootstrap` slash command.

[Full documentation >>>](code-index/)

## Requirements

| Dependency | Required by | Install |
|------------|-------------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | All modules | `npm install -g @anthropic-ai/claude-code` |
| [jq](https://jqlang.github.io/jq/) | All modules | `brew install jq` |
| [Bun](https://bun.sh) | handoff-kit, command-guard | `curl -fsSL https://bun.sh/install \| bash` |
| zsh | tab-titles | Default on macOS |
| [shellcheck](https://www.shellcheck.net/) | Development (linting) | `brew install shellcheck` |

## Contributing

Contributions are welcome. If you have an idea for a new module or an improvement to an existing one:

1. Fork the repository
2. Create a feature branch (`git checkout -b my-module`)
3. Follow the existing module structure (own directory, own `README.md`, own `install.sh`)
4. Submit a pull request

### Development

This project is 100% shell scripts. [shellcheck](https://www.shellcheck.net/) is required for linting:

```bash
brew install shellcheck    # macOS
# apt install shellcheck   # Linux

shellcheck <module>/install.sh
```

### Module structure convention

```
module-name/
├── README.md       # Bilingual documentation (EN + FR)
├── install.sh      # Standalone installer
├── hooks/          # Claude Code hook scripts (if any)
├── commands/       # Slash commands (if any)
└── ...
```

## License

[MIT](LICENSE) - Copyright (c) 2025 Bidiche49

---

<a id="francais"></a>

# Francais

## Pourquoi ?

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) est puissant par defaut, mais les utilisateurs avances se heurtent rapidement a des frictions :

- **Trop d'onglets terminaux** sans moyen de les distinguer
- **La fenetre de contexte se remplit** et le compactage supprime silencieusement votre progression
- **Pas de continuite de session** quand vous devez reprendre ou vous en etiez

**claude-conf** est une collection de modules independants, a installer selon vos besoins, qui resolvent ces problemes via les systemes natifs de Claude Code : [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [commandes](https://docs.anthropic.com/en/docs/claude-code/slash-commands) et [statusline](https://docs.anthropic.com/en/docs/claude-code/statusline).

## Modules

| Module | Description | Statut |
|--------|-------------|--------|
| [**tab-titles**](tab-titles/) | Titres d'onglets intelligents qui refletent le mode de session et le projet | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**handoff-kit**](handoff-kit/) | Surveillance du contexte, sauvegardes automatiques et handoff structure | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**supervisor**](supervisor/) | Mode CTO — investiguer, deleguer aux workers, valider, jamais ecrire de code | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**command-guard**](command-guard/) | Hook PreToolUse qui valide chaque commande shell avant execution | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**critical-thinking**](critical-thinking/) | Regles anti-complaisance — mode sparring partner pour Claude Code | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**pre-commit-gate**](pre-commit-gate/) | Rappel de lancer /check avant de committer — detection de stack universelle | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**backlog-kit**](backlog-kit/) | Systeme de ticketing universel avec protection automatique des IDs | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**claude-md-kit**](claude-md-kit/) | Trois commandes pour generer, nettoyer et optimiser CLAUDE.md | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |
| [**code-index**](code-index/) | Navigation indexee auto — 87-91% de tokens economises, Dart natif + TS/Python/Go/Rust via slash command | ![Pret](https://img.shields.io/badge/statut-pret-brightgreen?style=flat-square) |

Chaque module fonctionne **de maniere autonome** ou au sein de cette collection. Installez uniquement ce dont vous avez besoin.

## Demarrage rapide

### Tout installer

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh --all
```

### Choisir les modules (interactif)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh
```

### Installer un seul module

```bash
cd claude-conf/tab-titles
bash install.sh
```

## Prerequis

| Dependance | Requis par | Installation |
|------------|------------|--------------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Tous les modules | `npm install -g @anthropic-ai/claude-code` |
| [jq](https://jqlang.github.io/jq/) | Tous les modules | `brew install jq` |
| [Bun](https://bun.sh) | handoff-kit, command-guard | `curl -fsSL https://bun.sh/install \| bash` |
| zsh | tab-titles | Par defaut sur macOS |
| [shellcheck](https://www.shellcheck.net/) | Developpement (linting) | `brew install shellcheck` |

## Presentation des modules

### critical-thinking

Module anti-complaisance pour Claude Code. Transforme Claude en sparring partner technique qui challenge les idees au lieu de valider par defaut. Systeme de classification en 5 marqueurs (Solide / Discutable / Simplifie / Angle mort / Faux), 5 reflexes anti-complaisance (stress-test, maintien de position, detection d'erreurs, iteration, auto-diagnostic), et la regle des 3 validations qui declenche une recherche active de failles apres 3 approbations consecutives.

**Composants :** injection de regles dans `~/.claude/CLAUDE.md`, patch optionnel du bloc CTO POSTURE dans supervisor.

[Documentation complete >>>](critical-thinking/)

### pre-commit-gate

Rappel de lancer `/check` avant de committer, avec une commande de validation universelle. Le hook PreToolUse detecte `git commit` et rappelle de lancer `/check` d'abord (sans jamais bloquer). La commande `/check` detecte automatiquement le stack du projet (Node, Flutter, Go, Rust, Python, Ruby, PHP, Swift, Make) et lance le pipeline complet lint + build + tests.

**Composants :** hook PreToolUse (Bash), commande `/check`.

[Documentation complete >>>](pre-commit-gate/)

### backlog-kit

Systeme de ticketing universel pour Claude Code avec protection automatique des IDs. Gere trois types de tickets (bugs, features, improvements) avec des templates structures et des conventions de priorite/complexite. Le hook backlog-guard (PreToolUse Write) bloque les IDs dupliques entre sessions concurrentes. INDEX.md est auto-genere et jamais edite manuellement.

**Composants :** hook backlog-guard, commandes `/backlog-init`, `/backlog-bug`, `/backlog-feat`, `/backlog-imp`, `/backlog-status`.

[Documentation complete >>>](backlog-kit/)

### claude-md-kit

Trois commandes slash pour gerer le CLAUDE.md de vos projets. `/claude-md-init` genere un CLAUDE.md from scratch en analysant le code. `/claude-md-cleanup` supprime les doublons avec la config globale et le contenu generique. `/claude-md-boost` reecrit le CLAUDE.md avec du prompt engineering expert et des conventions specifiques au stack. Les trois commandes analysent le vrai code et demandent validation avant d'ecrire.

**Composants :** commandes `/claude-md-init`, `/claude-md-cleanup`, `/claude-md-boost`.

[Documentation complete >>>](claude-md-kit/)

### code-index

Navigation indexee automatiquement de la codebase. Genere des outlines markdown par dossier sous `docs/.code-map/`, avec numeros de ligne, pour que Claude Code localise les symboles et lise des slices ciblees au lieu de fichiers entiers. Economie mesuree : **87-91%** de tokens sur une vraie codebase Flutter. Dart/Flutter supporte nativement (setup en une commande, hooks AOT-compiles, ~0.2s par commit). Autres stacks (TypeScript, Python, Go, Rust) bootstrap au premier usage via la slash command `/code-index-bootstrap`, qui genere un indexer equivalent en utilisant le **parser AST officiel** du langage et valide automatiquement le resultat (≥ 50% d'economie de tokens, garde-fou non negociable).

**Composants :** script de setup par projet, indexer `tool/code_index.dart`, 4 git hooks, slash command `/code-index-bootstrap`.

[Documentation complete >>>](code-index/)

## Contribuer

Les contributions sont les bienvenues. Forkez le depot, creez une branche, respectez la structure des modules existants, et soumettez une pull request.

## Licence

[MIT](LICENSE) - Copyright (c) 2025 Bidiche49

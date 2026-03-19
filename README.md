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

## Requirements

| Dependency | Required by | Install |
|------------|-------------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | All modules | `npm install -g @anthropic-ai/claude-code` |
| [jq](https://jqlang.github.io/jq/) | All modules | `brew install jq` |
| [Bun](https://bun.sh) | handoff-kit | `curl -fsSL https://bun.sh/install \| bash` |
| zsh | tab-titles | Default on macOS |

## Contributing

Contributions are welcome. If you have an idea for a new module or an improvement to an existing one:

1. Fork the repository
2. Create a feature branch (`git checkout -b my-module`)
3. Follow the existing module structure (own directory, own `README.md`, own `install.sh`)
4. Submit a pull request

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
| [Bun](https://bun.sh) | handoff-kit | `curl -fsSL https://bun.sh/install \| bash` |
| zsh | tab-titles | Par defaut sur macOS |

## Contribuer

Les contributions sont les bienvenues. Forkez le depot, creez une branche, respectez la structure des modules existants, et soumettez une pull request.

## Licence

[MIT](LICENSE) - Copyright (c) 2025 Bidiche49

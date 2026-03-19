# supervisor

**CTO mode for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — investigate, delegate, never implement.**

<p>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/shell-bash%20%7C%20zsh-green?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License">
</p>

> Part of [claude-conf](https://github.com/Bidiche49/claude-conf) — install standalone or with the full toolkit.

---

## The Problem

You're writing code AND reviewing it. You're the architect AND the implementer. You're diagnosing a bug AND fixing it in the same breath.

That's not how senior engineering teams work.

When the same person investigates, plans, implements, and validates, shortcuts happen. Band-aid fixes slip through. Root causes go unexamined. The big picture gets lost in the details of implementation.

**What if you could split yourself in two?**

## The Solution

**supervisor** turns Claude Code into a strict CTO that **never writes a single line of code**. It investigates problems, creates detailed tickets, generates precise worker prompts, validates deliverables, and commits. Implementation happens in separate Claude Code sessions — the workers — each focused on a specific, scoped task.

The result: the rigor of a two-person review process, the speed of one developer.

## How It Works

```
     You describe a problem or feature
                  │
                  ▼
    ┌──────────────────────────┐
    │       SUPERVISOR         │
    │                          │
    │  1. Load project context │
    │  2. Deep investigation   │
    │  3. Root cause analysis  │
    │  4. Create tickets       │
    │  5. Execution plan       │
    │  6. Generate prompts     │
    └──────────┬───────────────┘
               │
       ┌───────┼───────┐
       ▼       ▼       ▼
   ┌───────┐ ┌───────┐ ┌───────┐
   │WORKER │ │WORKER │ │WORKER │     Separate Claude Code sessions
   │ A     │ │ B     │ │ C     │     Each has a scoped prompt
   └───┬───┘ └───┬───┘ └───┬───┘
       │       │       │
       ▼       ▼       ▼
    Reports come back to you
                  │
                  ▼
    ┌──────────────────────────┐
    │       SUPERVISOR         │
    │                          │
    │  7. Validate reports     │
    │  8. Review diffs         │
    │  9. Run quality checks   │
    │ 10. Commit & close       │
    └──────────────────────────┘
```

## What the Supervisor Does

| Responsibility | Details |
|----------------|---------|
| **Load context** | Reads CLAUDE.md, backlog, git history, latest handoff — builds full situational awareness |
| **Investigate** | Reads all relevant files, traces data flows, identifies root causes, detects related issues |
| **Create tickets** | Detailed BACKLOG tickets with root cause, approach, files, acceptance criteria |
| **Plan execution** | Dependency analysis, file conflict matrix, parallel wave scheduling |
| **Generate prompts** | Complete, actionable worker prompts with universal rules, stack-specific gates, and scoped context |
| **Validate reports** | Reviews diffs, runs checks, evaluates quality, catches regressions |
| **Commit** | Clean commits referencing tickets, after user approval |

## What the Supervisor NEVER Does

| Forbidden | Why |
|-----------|-----|
| Write or edit source code | Separation of concerns — the whole point |
| Commit without validation | The user always has final say |
| Skip investigation | No superficial diagnoses. Root cause or nothing |
| Generate vague prompts | Every prompt must be copy-paste ready and complete |
| Ignore worker-discovered problems | Every finding gets tracked as a ticket |
| Say "it's simple, I'll do it quick" | Delegate everything. Even 3 lines of code |

## Worker Prompt Anatomy

Every worker prompt the supervisor generates has four sections:

### 1. Universal Block

Rules that apply regardless of language or framework. No band-aid fixes. Single hypothesis debugging. Mandatory report at the end. No commits (the supervisor handles that). These rules enforce engineering discipline across every worker session.

### 2. Stack-Specific Block

Dynamically generated from your project's `CLAUDE.md`. The supervisor reads your project configuration and extracts the relevant quality gates, conventions, and tooling.

| If your project uses... | The block includes... |
|------------------------|----------------------|
| Flutter/Dart | `flutter analyze` = 0 issues, `flutter test`, AAA pattern, Riverpod conventions |
| TypeScript/Node | `eslint` + `tsc --noEmit`, test runner, import conventions |
| Python | `ruff check` + `mypy`, `pytest`, type hints |
| Go | `go vet` + `golangci-lint`, `go test ./...` |
| Rust | `cargo clippy`, `cargo test` |
| Any stack | Whatever CLAUDE.md specifies as the project's quality gates |

No CLAUDE.md? The supervisor asks you what your standards are before generating prompts.

### 3. Contextual Block

Task-specific instructions: which files to read first (in order), what approach to take, what pitfalls to avoid (identified during investigation), and the execution sequence.

### 4. Report Block

A mandatory structured report format that every worker must fill out: files modified, approach per ticket, linter/test results, review attention points, and problems discovered but not fixed.

## Multi-Ticket Execution Planning

When multiple tickets need work, the supervisor builds an execution plan before generating any prompt.

### Dependency Analysis

For each ticket: which files will be modified, which created, which tickets it depends on.

### Conflict Matrix

```
FILES MODIFIED:
  ticket A : src/auth.ts, src/middleware.ts
  ticket B : src/api.ts, src/routes.ts
  ticket C : src/middleware.ts, src/utils.ts

CONFLICTS:
  A and C : src/middleware.ts  ->  SEQUENTIAL mandatory
  A and B : no conflict        ->  PARALLEL possible
  B and C : no conflict        ->  PARALLEL possible
```

### Wave Scheduling

```
EXECUTION PLAN:

Wave 1 (parallel):
  Worker 1: TICKET-A — foundational middleware changes
  Worker 2: TICKET-B — independent API work

Wave 2 (after wave 1 validated + committed):
  Worker 3: TICKET-C — depends on A's middleware changes
```

Each parallel worker gets a **strict scope block** listing which files it owns and which files other workers are touching — preventing any scope overlap.

**Golden rule:** when in doubt, go sequential. Parallelism is only allowed when conflict risk is zero.

## Example Workflow

**1. Start the supervisor**

```
You: /supervisor
Claude: SUPERVISOR MODE ACTIVE
        Stack: TypeScript + React
        Pending tickets: 3
        Last activity: fix(auth): handle expired refresh tokens [BUG-042]

        Ready. What are we tackling?
```

**2. Describe the problem**

```
You: Users are getting logged out randomly after about 30 minutes
```

**3. Supervisor investigates** (reads auth files, token logic, session handling, middleware — asks questions if needed)

**4. Supervisor creates tickets and execution plan**

```
Claude: Root cause identified. The refresh token rotation has a race condition
        when multiple tabs are open. Created:
        - BUG-044: Fix refresh token race condition
        - IMP-089: Add token refresh mutex

        Execution plan: sequential (same files).
        Here's the worker prompt for BUG-044:
        [complete, copy-paste ready prompt]
```

**5. You open a new terminal tab, start Claude Code, paste the prompt**

**6. Worker implements the fix, produces a report**

**7. You paste the report back in the supervisor session**

**8. Supervisor validates** (reads modified files, runs checks, reviews diff)

```
Claude: Work validated. Changes are clean, tests pass, no regressions.
        Ready to commit. Proceed?

You: yes

Claude: Committed. Tickets moved to DONE.
        You can close the worker conversation.
        Generating prompt for IMP-089...
```

## Installation

### Via claude-conf (recommended)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh       # Select supervisor from the menu
```

### Standalone

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/supervisor
bash install.sh
```

The install script copies the `/supervisor` command to `~/.claude/commands/`. No hooks, no dependencies beyond Claude Code itself.

## Usage

In any Claude Code session:

```
/supervisor
```

That's it. Claude switches to CTO mode, loads your project context, and waits for instructions.

**Works with any stack.** The supervisor reads your `CLAUDE.md` and adapts. No configuration needed.

## Customization

### Backlog system

The supervisor expects a `BACKLOG/` directory with `INDEX.md` and `BUGS/`, `FEATURES/`, `IMPROVEMENTS/` subdirectories (each with `PENDING/` and `DONE/`). If your project uses a different ticketing structure, edit the BACKLOG references in `commands/supervisor.md`.

### Commit rules

The supervisor follows `git-commit-rules.md` in your `.claude/` directory. If you don't have one, it will use conventional commit format.

### Quality gates

Stack-specific rules are pulled from your `CLAUDE.md`. The more precise your CLAUDE.md is about linting, testing, and conventions, the more precise the worker prompts will be.

## Best Practices

| Practice | Why |
|----------|-----|
| **One problem per supervisor session** | Keeps context focused and avoids confusion |
| **Let the supervisor investigate before rushing** | Root cause analysis prevents wasted worker cycles |
| **Don't skip the report validation step** | The supervisor catches things you might miss after hours of coding |
| **Use with tab-titles** | Color-coded tabs make it trivial to navigate between supervisor and worker sessions |
| **Use with handoff-kit** | Long investigation sessions benefit from context monitoring |
| **Trust the execution plan** | If the supervisor says sequential, don't try to parallelize |

## Companion Modules

| Module | Benefit with supervisor |
|--------|----------------------|
| [**tab-titles**](../tab-titles/) | Supervisor tabs show `SUP`, worker tabs show the ticket ID. Instant visual distinction |
| [**handoff-kit**](../handoff-kit/) | Supervisor sessions can get long during deep investigation. Context monitoring keeps you safe |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

No other dependencies. The command is a single markdown file.

## License

[MIT](../LICENSE)

---

<a id="francais"></a>

# Francais

## Le probleme

Vous ecrivez du code ET vous le reviewez. Vous etes l'architecte ET l'implementeur. Vous diagnostiquez un bug ET vous le fixez dans la foulee.

Ce n'est pas comme ca que les equipes senior fonctionnent.

Quand la meme personne investigue, planifie, implemente et valide, les raccourcis s'accumulent. Les fix pansements passent entre les mailles. Les causes racines restent inexplorees. La vision d'ensemble se perd dans les details d'implementation.

**Et si vous pouviez vous dedoubler ?**

## La solution

**supervisor** transforme Claude Code en un CTO strict qui **n'ecrit jamais une seule ligne de code**. Il investigue les problemes, cree des tickets detailles, genere des prompts worker precis, valide les livrables et committe. L'implementation se fait dans des sessions Claude Code separees — les workers — chacune focalisee sur une tache specifique et scopee.

Le resultat : la rigueur d'un processus de review a deux, la vitesse d'un seul developpeur.

## Fonctionnement

```
     Vous decrivez un probleme ou une feature
                  |
                  v
    +------------------------------+
    |        SUPERVISEUR           |
    |                              |
    |  1. Charger le contexte      |
    |  2. Investigation profonde   |
    |  3. Analyse cause racine     |
    |  4. Creer les tickets        |
    |  5. Plan d'execution         |
    |  6. Generer les prompts      |
    +-------------+----------------+
                  |
       +----------+----------+
       v          v          v
   +--------+ +--------+ +--------+
   |WORKER  | |WORKER  | |WORKER  |   Sessions Claude Code separees
   |  A     | |  B     | |  C     |   Chacune a un prompt scope
   +----+---+ +----+---+ +----+---+
        |          |          |
        v          v          v
    Les rapports vous reviennent
                  |
                  v
    +------------------------------+
    |        SUPERVISEUR           |
    |                              |
    |  7. Valider les rapports     |
    |  8. Reviewer les diffs       |
    |  9. Lancer les checks        |
    | 10. Commit & cloture         |
    +------------------------------+
```

## Ce que le superviseur fait

| Responsabilite | Details |
|----------------|---------|
| **Charger le contexte** | Lit CLAUDE.md, backlog, historique git, dernier handoff — construit une vision complete |
| **Investiguer** | Lit tous les fichiers concernes, trace les flux de donnees, identifie les causes racines |
| **Creer des tickets** | Tickets BACKLOG detailles avec cause racine, approche, fichiers, criteres d'acceptation |
| **Planifier l'execution** | Analyse de dependances, matrice de conflits fichier, ordonnancement en vagues paralleles |
| **Generer des prompts** | Prompts worker complets et actionnables avec regles universelles, gates specifiques a la stack, contexte scope |
| **Valider les rapports** | Review des diffs, execution des checks, evaluation de la qualite, detection des regressions |
| **Committer** | Commits propres referencant les tickets, apres validation utilisateur |

## Ce que le superviseur ne fait JAMAIS

| Interdit | Pourquoi |
|----------|----------|
| Ecrire ou modifier du code source | Separation des responsabilites — c'est tout l'interet |
| Committer sans validation | L'utilisateur a toujours le dernier mot |
| Sauter l'investigation | Pas de diagnostic superficiel. Cause racine ou rien |
| Generer des prompts vagues | Chaque prompt doit etre pret a copier-coller et complet |
| Ignorer un probleme trouve par un worker | Chaque decouverte est trackee en ticket |
| Dire "c'est simple, je le fais vite" | Tout deleguer. Meme 3 lignes de code |

## Anatomie d'un prompt worker

Chaque prompt genere par le superviseur comporte quatre sections :

### 1. Bloc universel

Regles applicables quel que soit le langage ou le framework. Pas de fix pansement. Debug par hypothese unique. Rapport obligatoire a la fin. Pas de commits (le superviseur s'en charge). Ces regles imposent la discipline d'ingenierie dans chaque session worker.

### 2. Bloc specifique a la stack

Genere dynamiquement depuis le `CLAUDE.md` du projet. Le superviseur lit la configuration du projet et en extrait les quality gates, conventions et outils pertinents.

| Si votre projet utilise... | Le bloc inclut... |
|---------------------------|-------------------|
| Flutter/Dart | `flutter analyze` = 0 issues, `flutter test`, pattern AAA, conventions Riverpod |
| TypeScript/Node | `eslint` + `tsc --noEmit`, test runner, conventions d'import |
| Python | `ruff check` + `mypy`, `pytest`, type hints |
| Go | `go vet` + `golangci-lint`, `go test ./...` |
| Rust | `cargo clippy`, `cargo test` |
| Toute stack | Ce que CLAUDE.md specifie comme quality gates du projet |

Pas de CLAUDE.md ? Le superviseur vous demande vos standards avant de generer des prompts.

### 3. Bloc contextuel

Instructions specifiques a la tache : quels fichiers lire en premier (dans l'ordre), quelle approche adopter, quels pieges eviter (identifies pendant l'investigation), et la sequence d'execution.

### 4. Bloc rapport

Un format de rapport structure obligatoire que chaque worker doit remplir : fichiers modifies, approche par ticket, resultats linter/tests, points d'attention pour la review, et problemes decouverts mais non fixes.

## Planification multi-tickets

Quand plusieurs tickets doivent etre traites, le superviseur construit un plan d'execution avant de generer le moindre prompt.

### Analyse de dependances

Pour chaque ticket : quels fichiers seront modifies, lesquels crees, de quels tickets il depend.

### Matrice de conflits

```
FICHIERS MODIFIES :
  ticket A : src/auth.ts, src/middleware.ts
  ticket B : src/api.ts, src/routes.ts
  ticket C : src/middleware.ts, src/utils.ts

CONFLITS :
  A et C : src/middleware.ts  ->  SEQUENTIEL obligatoire
  A et B : aucun conflit      ->  PARALLELE possible
  B et C : aucun conflit      ->  PARALLELE possible
```

### Ordonnancement en vagues

```
PLAN D'EXECUTION :

Vague 1 (parallele) :
  Worker 1 : TICKET-A — changements fondamentaux middleware
  Worker 2 : TICKET-B — travail API independant

Vague 2 (apres validation + commit vague 1) :
  Worker 3 : TICKET-C — depend des changements middleware de A
```

Chaque worker parallele recoit un **bloc de scope strict** listant quels fichiers il possede et quels fichiers d'autres workers touchent — empechant tout debordement de scope.

**Regle d'or :** en cas de doute, sequentiel. Le parallelisme n'est autorise que si le risque de conflit est zero.

## Exemple de workflow

**1. Demarrer le superviseur**

```
Vous : /supervisor
Claude : MODE SUPERVISEUR ACTIF
         Stack : TypeScript + React
         Tickets pending : 3
         Derniere activite : fix(auth): gerer les refresh tokens expires [BUG-042]

         Pret. Qu'est-ce qu'on attaque ?
```

**2. Decrire le probleme**

```
Vous : Les utilisateurs se font deconnecter au bout de 30 minutes
```

**3. Le superviseur investigue** (lit les fichiers d'auth, la logique de tokens, la gestion de session, le middleware)

**4. Le superviseur cree les tickets et le plan d'execution**

**5. Vous ouvrez un nouvel onglet terminal, lancez Claude Code, collez le prompt**

**6. Le worker implemente le fix, produit un rapport**

**7. Vous collez le rapport dans la session superviseur**

**8. Le superviseur valide, committe, genere le prompt suivant**

## Installation

### Via claude-conf (recommande)

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf
bash install.sh       # Selectionnez supervisor dans le menu
```

### Installation autonome

```bash
git clone https://github.com/Bidiche49/claude-conf.git
cd claude-conf/supervisor
bash install.sh
```

Le script copie la commande `/supervisor` dans `~/.claude/commands/`. Pas de hooks, pas de dependances au-dela de Claude Code.

## Utilisation

Dans n'importe quelle session Claude Code :

```
/supervisor
```

C'est tout. Claude passe en mode CTO, charge le contexte de votre projet, et attend les instructions.

**Fonctionne avec toute stack.** Le superviseur lit votre `CLAUDE.md` et s'adapte. Aucune configuration necessaire.

## Personnalisation

### Systeme de backlog

Le superviseur attend un repertoire `BACKLOG/` avec `INDEX.md` et des sous-repertoires `BUGS/`, `FEATURES/`, `IMPROVEMENTS/` (chacun avec `PENDING/` et `DONE/`). Si votre projet utilise une structure differente, editez les references dans `commands/supervisor.md`.

### Regles de commit

Le superviseur suit `git-commit-rules.md` dans votre repertoire `.claude/`. Sans ce fichier, il utilise le format conventional commits.

### Quality gates

Les regles specifiques a la stack sont extraites de votre `CLAUDE.md`. Plus votre CLAUDE.md est precis sur le linting, les tests et les conventions, plus les prompts worker seront precis.

## Bonnes pratiques

| Pratique | Pourquoi |
|----------|----------|
| **Un probleme par session superviseur** | Garde le contexte focalise et evite la confusion |
| **Laisser le superviseur investiguer avant de foncer** | L'analyse de cause racine evite de gaspiller des cycles worker |
| **Ne pas sauter l'etape de validation du rapport** | Le superviseur detecte ce que vous pourriez rater apres des heures de code |
| **Utiliser avec tab-titles** | Les onglets colores rendent triviale la navigation entre superviseur et workers |
| **Utiliser avec handoff-kit** | Les longues sessions d'investigation beneficient du monitoring de contexte |
| **Faire confiance au plan d'execution** | Si le superviseur dit sequentiel, ne tentez pas de paralleliser |

## Modules complementaires

| Module | Benefice avec supervisor |
|--------|------------------------|
| [**tab-titles**](../tab-titles/) | Les onglets superviseur affichent `SUP`, les workers affichent l'ID du ticket. Distinction visuelle instantanee |
| [**handoff-kit**](../handoff-kit/) | Les sessions superviseur peuvent durer longtemps pendant l'investigation. Le monitoring de contexte vous protege |

## Prerequis

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

Aucune autre dependance. La commande est un seul fichier markdown.

## Licence

[MIT](../LICENSE)

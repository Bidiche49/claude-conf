# FEAT-004: Module backlog — systeme de ticketing universel

**Type:** Feature
**Statut:** Fait
**Priorite:** Haute
**Complexite:** M
**Tags:** module, ticketing, hooks
**Date creation:** 2026-03-21

---

## Description

Creer un module `backlog/` exportable qui installe un systeme de ticketing complet pour n'importe quel projet Claude Code. Remplace les ~80 lignes de regles backlog hardcodees dans le CLAUDE.md global par un snippet injectable + des commandes + un hook de protection.

Changement majeur : INDEX.md devient un cache genere (pas edite manuellement). Les IDs sont calcules par scan des fichiers. Un hook PreToolUse bloque les conflits d'ID.

## User Story

**En tant que** utilisateur de Claude Code
**Je veux** un systeme de ticketing qui s'installe en une commande, protege contre les conflits multi-sessions, et ne demande aucune maintenance manuelle
**Afin de** tracker bugs/features/improvements proprement sans me soucier des conflits d'ID ou de la synchronisation d'INDEX.md

## Livrable — Structure du module

```
backlog/
├── README.md
├── install.sh
├── claude-md/
│   └── backlog.md                  ← Snippet CLAUDE.md (conventions, workflow)
├── commands/
│   ├── backlog-init.md             ← Initialiser BACKLOG/ dans un projet
│   ├── backlog-bug.md              ← Creer un bug
│   ├── backlog-feat.md             ← Creer une feature
│   ├── backlog-imp.md              ← Creer une improvement
│   └── backlog-status.md           ← Regenerer INDEX.md + afficher stats
├── hooks/
│   └── backlog-guard.sh            ← PreToolUse Write: valide ID avant creation
└── templates/
    └── ticket.md                   ← Template de ticket
```

## Contenu du snippet CLAUDE.md (`claude-md/backlog.md`)

Snippet concis (~40 lignes) entre markers `<!-- backlog:start -->` / `<!-- backlog:end -->`. Contenu :

```markdown
## Systeme de ticketing (BACKLOG)

Utiliser ce systeme pour TOUTE demande necessitant du travail.

### Detection automatique

| Type | Prefixe | Declencheurs |
|------|---------|--------------|
| **Bug** | BUG-XXX | "ne marche pas", "crash", "erreur", "bug", "casse" |
| **Feature** | FEAT-XXX | "ajouter", "nouveau", "creer", "je veux" |
| **Improvement** | IMP-XXX | "ameliorer", "optimiser", "refactorer" |

### Structure

BACKLOG/ contient BUGS/, FEATURES/, IMPROVEMENTS/ avec PENDING/ et DONE/ dans chaque.
INDEX.md est un cache genere automatiquement — ne JAMAIS l'editer manuellement.

### Workflow

1. Verifier que BACKLOG/ existe (sinon `/backlog-init`)
2. Utiliser `/backlog-bug`, `/backlog-feat`, ou `/backlog-imp` pour creer un ticket
3. L'ID est calcule automatiquement par scan des fichiers existants
4. Le hook backlog-guard bloque les conflits d'ID
5. Pour fermer : deplacer le fichier vers DONE/, puis `/backlog-status` pour regenerer INDEX.md

### Conventions

| Priorite | Quand |
|----------|-------|
| Critique | Bloquant, prod down, securite |
| Haute | Important, impact utilisateur |
| Moyenne | Normal, planifiable |
| Basse | Nice-to-have, cosmetique |

| Complexite | Estimation |
|------------|------------|
| XS | < 1h | S | 1-4h | M | 1-2j | L | 3-5j | XL | > 1 semaine |

### Commandes

- `/backlog-init` — Initialiser BACKLOG/ dans un projet
- `/backlog-bug <desc>` — Creer un bug
- `/backlog-feat <desc>` — Creer une feature
- `/backlog-imp <desc>` — Creer une improvement
- `/backlog-status` — Regenerer INDEX.md et afficher les stats
```

## Template de ticket v2 (`templates/ticket.md`)

```markdown
# [TYPE]-XXX: Titre court

**Type:** Bug | Feature | Improvement
**Statut:** Fait | En cours | Bloque | Fait
**Priorite:** Critique | Haute | Moyenne | Basse
**Complexite:** XS | S | M | L | XL
**Tags:** [libres, separes par virgule]
**Depends on:** none
**Blocked by:** —
**Date creation:** YYYY-MM-DD

---

## Description
[Description claire]

## Fichiers concernes
- `path/to/file`

## Criteres d'acceptation
- [ ] Critere 1

## Tests de validation
- [ ] Test 1
```

Changements vs ancien template :
- `+` Champ `Depends on` pour les dependances entre tickets
- `+` Champ `Blocked by` pour les blocages externes
- `+` Statut `Bloque`
- `-` User Story (supprimee — utile parfois mais pas dans le template par defaut)
- `-` Analyse/Approche (le supervisor le remplit s'il veut)
- `-` Scope hardcode
- `-` Tags hardcodes (libres)

## Hook backlog-guard (`hooks/backlog-guard.sh`)

Hook PreToolUse sur Write. Comportement :

```
1. Lire l'input JSON (tool_input.file_path ou content)
2. Le path cible est dans BACKLOG/ ? Non → exit 0
3. Extraire le type et l'ID du nom de fichier (ex: BUG-005 depuis BACKLOG/BUGS/PENDING/BUG-005.md)
4. Scanner BACKLOG/{TYPE}/PENDING/ + BACKLOG/{TYPE}/DONE/ pour verifier que l'ID n'existe pas
5. Si conflit → print "BLOCKED: {ID} already exists. Next available: {TYPE}-{max+1}" + exit 2
6. Si OK → exit 0
```

Le hook ne touche PAS INDEX.md. Il valide seulement.

Dependencies : jq (pour parser l'input JSON du hook).

## Commandes — Comportement

### `/backlog-init`

Simplifie vs l'existant. Cree la structure :
```
BACKLOG/
├── INDEX.md (genere vide)
├── BUGS/{PENDING,DONE}/
├── FEATURES/{PENDING,DONE}/
├── IMPROVEMENTS/{PENDING,DONE}/
└── _templates/ticket.md
```

Pas de READY/, NON_AUTOMATABLE/, _system/ — c'est du scope `backlog-auto`, pas du scope ticketing de base.

### `/backlog-bug <desc>`, `/backlog-feat <desc>`, `/backlog-imp <desc>`

1. Verifier BACKLOG/ existe
2. Scanner les fichiers PENDING/ + DONE/ pour calculer le prochain ID (max + 1)
3. Creer le ticket dans PENDING/ avec le template rempli
4. Regenerer INDEX.md (appeler la logique de `/backlog-status`)
5. Afficher confirmation

**NE PAS lire INDEX.md pour l'ID.** Scanner les fichiers.

### `/backlog-status`

1. Scanner TOUS les fichiers dans BACKLOG/
2. Compter par type et statut (PENDING/DONE)
3. Extraire les metadonnees de chaque ticket (titre, priorite, complexite)
4. **Reecrire INDEX.md entierement** a partir des donnees scannees
5. Afficher le resume dans le terminal

INDEX.md genere :
```markdown
# BACKLOG — [Nom du projet]

## FEATURES

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| FEAT-001 | ... | Fait | Haute |

**Prochain ID : FEAT-002**

## BUGS
...

## IMPROVEMENTS
...
```

## install.sh — Comportement

1. Check deps (claude, jq)
2. Copier hook → `~/.claude/hooks/backlog-guard.sh` + chmod +x
3. Copier commandes (5 fichiers) → `~/.claude/commands/`
4. Copier template → `~/.claude/templates/backlog/ticket.md`
5. Configurer hook PreToolUse Write dans `~/.claude/settings.json` (meme pattern que command-guard mais matcher "Write" au lieu de "Bash")
6. Injecter snippet CLAUDE.md entre markers (meme pattern que critical-thinking)
7. Si ancien snippet backlog detecte dans CLAUDE.md (les ~80 lignes actuelles) → le supprimer proprement
8. Banner + resume

### Nettoyage de l'ancien snippet

Le CLAUDE.md global contient actuellement un bloc backlog de ~80 lignes (lignes 7-143 de ~/.claude/CLAUDE.md) qui commence par `## SYSTEME DE TICKETING UNIVERSEL (BACKLOG)` et finit avant `## REGLES GENERALES`. L'install.sh doit :
- Detecter ce bloc (chercher `## SYSTEME DE TICKETING UNIVERSEL`)
- Le supprimer
- Injecter le nouveau snippet entre markers a la place

Approche : utiliser sed pour supprimer de `## SYSTEME DE TICKETING UNIVERSEL` jusqu'a la ligne `---` qui precede `## REGLES GENERALES`. Puis injecter le nouveau snippet. Tester sur une copie d'abord.

## Criteres d'acceptation

- [ ] `bash install.sh` installe hook + commandes + snippet
- [ ] L'install est idempotente (relancer = update, pas duplication)
- [ ] L'ancien bloc backlog du CLAUDE.md est nettoye
- [ ] `/backlog-init` cree la structure BACKLOG/
- [ ] `/backlog-bug "desc"` cree un ticket avec un ID calcule par scan
- [ ] `/backlog-status` regenere INDEX.md entierement
- [ ] Le hook bloque la creation d'un ticket avec un ID deja pris
- [ ] Le hook laisse passer les tickets avec un ID libre
- [ ] Le hook ne se declenche pas sur des Write hors BACKLOG/
- [ ] Le template v2 contient les champs depends_on et blocked_by

## Fichiers concernes

### A creer
- `backlog/README.md`
- `backlog/install.sh`
- `backlog/claude-md/backlog.md`
- `backlog/commands/backlog-init.md`
- `backlog/commands/backlog-bug.md`
- `backlog/commands/backlog-feat.md`
- `backlog/commands/backlog-imp.md`
- `backlog/commands/backlog-status.md`
- `backlog/hooks/backlog-guard.sh`
- `backlog/templates/ticket.md`

### A ne PAS modifier
- `~/.claude/CLAUDE.md` (c'est install.sh qui le fera a l'execution)
- Les commands backlog existantes dans `~/.claude/commands/backlog/`

## Tests de validation

- [ ] Install sur un CLAUDE.md avec l'ancien bloc backlog → ancien supprime, nouveau injecte
- [ ] Install sur un CLAUDE.md sans bloc backlog → snippet ajoute
- [ ] Relancer install → UPDATED (pas de duplication)
- [ ] `/backlog-init` dans un dossier vide → structure creee
- [ ] `/backlog-bug "test"` → BUG-001 cree, INDEX.md regenere
- [ ] `/backlog-bug "test2"` → BUG-002 (pas BUG-001)
- [ ] Creer manuellement BUG-003.md, puis `/backlog-bug` → BUG-004 (pas BUG-003)
- [ ] Hook : tenter de Write BUG-001.md quand il existe → BLOCKED
- [ ] Hook : Write BUG-005.md quand il n'existe pas → OK
- [ ] `/backlog-status` → INDEX.md regenere avec tous les tickets presents

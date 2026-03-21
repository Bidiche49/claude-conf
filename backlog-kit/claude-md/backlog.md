<!-- backlog:start -->

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

<!-- backlog:end -->

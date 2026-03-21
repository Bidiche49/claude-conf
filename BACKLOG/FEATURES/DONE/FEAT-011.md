# FEAT-011: Module api-contract — gestion du contrat API pour projets split

**Type:** Feature
**Statut:** Fait
**Priorite:** Haute
**Complexite:** M
**Tags:** module, api, split-project
**Depends on:** none
**Blocked by:** —
**Date creation:** 2026-03-21

---

## Description

Creer un module `api-contract/` complet pour les projets split (front/back). Trois composants : un hook qui rappelle de mettre a jour le contrat quand un fichier API est modifie, une commande qui genere le contrat initial a partir du code, et une commande qui verifie la coherence contrat vs code.

## User Story

**En tant que** developpeur travaillant sur un projet split front/back
**Je veux** un systeme qui genere, maintient et verifie mon contrat API automatiquement
**Afin de** ne jamais avoir de desync entre mon backend et mon frontend

## Livrable — Structure du module

```
api-contract/
├── README.md
├── install.sh
├── hooks/
│   └── api-contract-reminder.sh    ← PostToolUse Edit|Write: rappel MAJ contrat
└── commands/
    ├── api-contract-init.md        ← Generer API_CONTRACT.md depuis le code
    └── api-contract-sync.md        ← Verifier coherence contrat vs code
```

## Hook : `api-contract-reminder.sh`

Hook PostToolUse sur Edit|Write. Base sur l'existant `~/.claude/hooks/api-contract-reminder.sh` avec ameliorations.

### Comportement

1. Parser l'input JSON : extraire `tool_name`, `tool_input.file_path`, `cwd`
2. Ne s'activer que sur Edit ou Write
3. Chercher `API_CONTRACT.md` dans le projet :
   - `$cwd/shared/API_CONTRACT.md`
   - `$cwd/../shared/API_CONTRACT.md`
   - `$cwd/API_CONTRACT.md`
   - Si non trouve → exit 0 silencieux (pas un projet avec contrat)
4. Detecter si le fichier modifie affecte le contrat API :

| Pattern fichier | Stack detectee |
|---|---|
| `*.controller.ts` | NestJS |
| `*.dto.ts` | NestJS |
| `Controller.php` | CakePHP/Laravel |
| `*Route*.php` | CakePHP/Laravel |
| `routes/*.ts` ou `router/*.ts` | Express/Fastify |
| `routes/*.py` ou `views*.py` | Django/FastAPI |
| `*_handler.go` ou `*_router.go` | Go |
| `routes/*.rs` | Rust/Actix/Axum |
| `*_controller.rb` | Rails |

5. Si match → afficher rappel : "[API-CONTRACT] Tu viens de modifier un fichier qui affecte le contrat API. Si le contrat a change, mets a jour [path] et ajoute une ligne au Changelog."
6. exit 0 toujours (rappel, jamais bloquant)

### Ameliorations vs l'existant
- Plus de stacks detectees (Python, Go, Rust, Ruby en plus de JS/PHP)
- Recherche du contrat dans plus d'emplacements
- Message plus actionnable (mentionne le Changelog)

## Commande 1 : `/api-contract-init`

```markdown
---
description: Generate API_CONTRACT.md by scanning existing routes and controllers
argument-hint: [shared|root — where to create the file]
---
```

### Comportement

1. **Detecter la stack backend** — scanner les fichiers de config (package.json avec NestJS/Express, composer.json, go.mod, etc.)
2. **Scanner les routes/controllers** :
   - NestJS : chercher les decorateurs `@Controller`, `@Get`, `@Post`, `@Put`, `@Delete`, `@Patch` dans les `.controller.ts`
   - Express/Fastify : chercher `router.get`, `router.post`, etc. dans les fichiers routes
   - CakePHP/Laravel : chercher les methodes publiques dans les Controllers
   - Django : chercher les `urlpatterns` et `ViewSet`
   - FastAPI : chercher les `@app.get`, `@router.post`, etc.
   - Go : chercher les `HandleFunc`, `mux.Handle`, etc.
   - Rails : chercher `routes.rb`
3. **Extraire pour chaque endpoint** : methode HTTP, path, params (body/query), response type si detectable
4. **Chercher les DTOs/schemas** : types TypeScript, dataclasses Python, structs Go, etc.
5. **Generer `API_CONTRACT.md`** avec ce format :

```markdown
# API Contract — [Nom du projet]

Source de verite pour la communication entre backend et frontend.

## Conventions globales
- Base URL: [detectee ou a remplir]
- Auth: [detectee ou a remplir]
- Format response: [detecte ou standard JSON]
- Format erreurs: [detecte ou a remplir]

## [Domaine 1 — groupe par controller/router]

### [METHOD] [path]

**Request:**
```[lang]
[body type / query params]
```

**Response:**
```[lang]
[response type]
```

**Auth:** [required/optional/none]
**Notes:** [si applicable]

---

## Changelog

| Date | Changement | Side |
|------|-----------|------|
| [today] | Initial generation from code | backend |
```

6. **Demander ou creer le fichier** : `shared/API_CONTRACT.md` (defaut pour les splits) ou racine
7. **Presenter** le contrat genere et attendre validation

**Regle cle** : le contrat doit etre genere a partir du VRAI code, pas invente. Si un endpoint n'a pas de type clairement defini, mettre `// TODO: define type` plutot que deviner.

## Commande 2 : `/api-contract-sync`

```markdown
---
description: Check if API_CONTRACT.md is in sync with the actual code
---
```

### Comportement

1. **Lire** `API_CONTRACT.md` (chercher dans shared/, racine, ../shared/)
2. **Scanner** les routes/controllers actuels (meme logique que init)
3. **Comparer** :
   - Endpoints dans le contrat mais plus dans le code → **REMOVED**
   - Endpoints dans le code mais pas dans le contrat → **MISSING**
   - Endpoints presents des deux cotes → verifier si les types/params correspondent → **CHANGED** si different
4. **Afficher le rapport** :

```
API CONTRACT SYNC
═════════════════
✓ 15 endpoints in sync
⚠ 3 issues found:

MISSING (in code, not in contract):
  POST /api/v2/sessions/:id/join — SessionController.join()

REMOVED (in contract, not in code):
  DELETE /api/v2/users/:id — was in UserController (file deleted?)

CHANGED (signatures differ):
  PUT /api/v2/sessions/:id — contract says {name: string}, code expects {name: string, maxPlayers: number}
```

5. **Proposer les corrections** mais NE PAS modifier le contrat automatiquement
6. Si tout est sync → "Contract in sync — [N] endpoints verified"

## install.sh — Comportement

1. Check deps (claude, jq)
2. Copier hook → `~/.claude/hooks/api-contract-reminder.sh` + chmod +x
3. Copier commandes (2 fichiers) → `~/.claude/commands/`
4. Configurer hook PostToolUse `Edit|Write` dans `~/.claude/settings.json` (merge jq, idempotent)
5. Banner + resume

Pattern settings.json : s'inspirer de `pre-commit-gate/install.sh` mais avec PostToolUse au lieu de PreToolUse, et matcher `Edit|Write` au lieu de `Bash`.

## Criteres d'acceptation

- [ ] `bash install.sh` installe hook + commandes
- [ ] Le hook se declenche quand un controller/route est modifie
- [ ] Le hook ne se declenche PAS sur des fichiers non-API
- [ ] Le hook exit 0 silencieux si pas de API_CONTRACT.md dans le projet
- [ ] `/api-contract-init` scanne les routes et genere un contrat
- [ ] `/api-contract-init` genere a partir du vrai code (pas de fabrication)
- [ ] `/api-contract-sync` detecte les endpoints missing/removed/changed
- [ ] `/api-contract-sync` ne modifie PAS le contrat automatiquement
- [ ] L'install est idempotente

## Fichiers concernes

### A creer
- `api-contract/README.md`
- `api-contract/install.sh`
- `api-contract/hooks/api-contract-reminder.sh`
- `api-contract/commands/api-contract-init.md`
- `api-contract/commands/api-contract-sync.md`

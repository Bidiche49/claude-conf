# FEAT-012: Module explore — exploration parallele structuree

**Type:** Feature
**Statut:** A faire
**Priorite:** Basse
**Complexite:** XS
**Tags:** module, exploration
**Depends on:** none
**Blocked by:** —
**Date creation:** 2026-03-21

---

## Description

Creer un module `explore/` qui installe la commande `/explore` — exploration parallele structuree avec agents codebase + docs + web. Force Claude a planifier avant d'explorer et a produire un rapport structure.

Base sur la commande locale existante `~/.claude/commands/explore.md`.

## Livrable

```
explore/
├── README.md
├── install.sh
└── commands/
    └── explore.md
```

Simple : 1 commande, 1 install.sh. Pas de hook.

## Criteres d'acceptation

- [ ] `/explore <topic>` lance une exploration parallele structuree
- [ ] Le rapport contient : fichiers cles, patterns, exemples, recommandations
- [ ] L'install est idempotente

## Fichiers concernes

- `explore/README.md` (creer)
- `explore/install.sh` (creer)
- `explore/commands/explore.md` (creer — base sur `~/.claude/commands/explore.md`)

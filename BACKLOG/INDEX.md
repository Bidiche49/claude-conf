# BACKLOG — claude-conf

## FEATURES

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| FEAT-001 | Module critical-thinking — anti-complaisance | Fait | Haute |
| FEAT-002 | Module pre-commit-gate — rappel /check + commande /check | Fait | Haute |
| FEAT-003 | Module oneshot — implementation rapide stack-agnostic | Fait | Basse |
| FEAT-004 | Module backlog-kit — systeme de ticketing universel | Fait | Haute |
| FEAT-005 | Module claude-md-kit — cleanup, boost, init pour CLAUDE.md projet | Fait | Haute |
| FEAT-006 | scope-enforcer — hook PreToolUse bloquer ecriture hors scope worker | Fait | Haute |
| FEAT-007 | PostToolUse hook — manifest fichiers modifies + detection tests fail | Fait | Haute |
| FEAT-008 | launch-worker — script lancement worker avec config cc/ccd | A faire | Haute |
| FEAT-009 | supervisor-guard — hook PreToolUse bloquer Write/Edit en mode supervisor | A faire | Haute |
| FEAT-010 | Module setup-project — bootstrap projet intelligent avec detection stack | Fait | Haute |

**Prochain ID suggere : FEAT-011**

## BUGS

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| BUG-001 | Tab-titles — worker sessions affichent SUP au lieu de WORK | Fait | Haute |
| BUG-002 | Tab-titles — titre fenetre ecrase par precmd + Terminal.app | Fait | Haute |
| BUG-003 | command-guard — "deny" au lieu de "block" dans HookOutput | Fait | Critique |
| BUG-004 | install.sh — footgun ((count++)) avec set -e | Fait | Haute |
| BUG-005 | tab-titles — couleurs par projet toujours blanches | Fait | Moyenne |
| BUG-006 | tab-titles — sed -i casse Linux | Fait | Moyenne |
| BUG-007 | command-guard — regex rm -rf ne matche pas fin de string | Fait | Haute |
| BUG-008 | handoff — PreCompact hook JSON (faux positif, JSON valide) | Fait | Moyenne |
| BUG-009 | tab-titles — precmd() ecrase les precmd existants (oh-my-zsh, p10k) | A faire | Moyenne |

**Prochain ID suggere : BUG-010**

## IMPROVEMENTS

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| IMP-001 | Integration critical-thinking dans CLI + portabilite Linux | Fait | Moyenne |
| IMP-002 | Supprimer step 3/4 (stagiaire) de install.sh | Fait | Basse |
| IMP-003 | Ajouter shellcheck comme pre-requis dev | Fait | Basse |
| IMP-004 | Supervisor — scope strict sur le commit en multi-supervisors | Fait | Haute |
| IMP-005 | handoff — supprimer CRITICAL auto-execute, garder WARNING only | Fait | Moyenne |
| IMP-006 | supervisor — dedupliquer bloc POSTURE vs CLAUDE.md critical-thinking | Fait | Basse |
| IMP-007 | Supprimer oneshot, absorber stack table dans fichier partage | Fait | Moyenne |
| IMP-008 | handoff — rotation des backups (garder 35 derniers) | Fait | Basse |
| IMP-009 | install.sh — modules invisibles dans MODULES array + README | Fait | Moyenne |
| IMP-010 | worker rapport — boy scout rule + section tests manquants | Fait | Moyenne |
| IMP-011 | command-guard — pre-bundle bun build pour eliminer cold start | A faire | Haute |
| IMP-012 | command-guard — wrapper shell pre-filter pour skip non-Bash | A faire | Haute |
| IMP-013 | command-guard — appendFile au lieu de read+write pour le log | A faire | Basse |
| IMP-014 | CLAUDE.md — reduire section backlog au strict minimum | A faire | Basse |
| IMP-015 | tab-titles — mise a jour du bloc .zshrc existant a la reinstall | A faire | Haute |
| IMP-016 | install.sh — ajouter tests automatises basiques | A faire | Basse |
| IMP-017 | tab-titles — ajouter tests automatises basiques | A faire | Basse |
| IMP-018 | handoff-kit — ajouter tests pre-compact-handoff.sh | A faire | Basse |
| IMP-019 | handoff-kit — ajouter tests context-monitor.sh | A faire | Basse |

| IMP-020 | README.md — sections Module Overview pour les 4 nouveaux modules | A faire | Basse |
| IMP-021 | scope-enforcer — ajouter tests automatises | A faire | Basse |

**Prochain ID suggere : IMP-022**

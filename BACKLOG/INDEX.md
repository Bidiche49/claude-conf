# BACKLOG — claude-conf

## FEATURES

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| FEAT-001 | Module critical-thinking — anti-complaisance | Fait | Haute |
| FEAT-002 | Module pre-commit-gate — rappel /check avant commit + commande /check generique | Fait | Haute |
| FEAT-003 | Module oneshot — implementation rapide stack-agnostic | Fait | Basse |
| FEAT-004 | Module backlog — systeme de ticketing universel | Fait | Haute |
| FEAT-005 | Module claude-md-kit — cleanup, boost, init pour CLAUDE.md projet | Fait | Haute |
| FEAT-006 | scope-enforcer — hook PreToolUse pour bloquer ecriture hors scope worker | Fait | Haute |
| FEAT-007 | PostToolUse hook — manifest fichiers modifies + detection tests fail | Fait | Haute |
| FEAT-008 | launch-worker — script de lancement worker avec config cc/ccd | Fait | Haute |
| FEAT-009 | supervisor-guard — hook PreToolUse pour bloquer Write/Edit en mode supervisor | Fait | Haute |
| FEAT-010 | Module setup-project — bootstrap projet intelligent avec detection stack | Fait | Haute |
| FEAT-011 | Module api-contract — gestion du contrat API pour projets split | Fait | Haute |
| FEAT-012 | Module explore — exploration parallele structuree | Fait | Basse |

**Prochain ID : FEAT-013**

## BUGS

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| BUG-001 | Tab-titles — worker sessions affichent SUP au lieu de WORK | Fait | Haute |
| BUG-002 | Tab-titles — titre fenetre ecrase par precmd + Terminal.app | Fait | Haute |
| BUG-003 | command-guard — "deny" au lieu de "block" dans HookOutput | Fait | Critique |
| BUG-004 | install.sh — footgun ((count++)) avec set -e | Fait | Haute |
| BUG-005 | tab-titles — couleurs par projet toujours blanches | Fait | Moyenne |
| BUG-006 | tab-titles — sed -i casse Linux | Fait | Moyenne |
| BUG-007 | command-guard — regex rm-rf ne matche pas fin de string | Fait | Haute |
| BUG-008 | handoff — PreCompact hook JSON invalide | Fait | Moyenne |
| BUG-009 | tab-titles — precmd() ecrase les precmd existants (oh-my-zsh, p10k) | Fait | Moyenne |
| BUG-010 | tab-titles — titre ecrase au demarrage de Claude Code | Fait | Haute |
| BUG-011 | supervisor-guard — activation fragile, depend d'un touch dans le prompt | Fait | Haute |
| BUG-012 | Tab-titles — titre d'onglet revient a "CC" au resume de conversation | Fait | Haute |

**Prochain ID : BUG-013**

## IMPROVEMENTS

| ID | Titre | Statut | Priorite |
|----|-------|--------|----------|
| IMP-001 | Integration critical-thinking dans CLI + portabilite Linux | Fait | Moyenne |
| IMP-002 | Supprimer step 3/4 (stagiaire) de critical-thinking/install.sh | Fait | Basse |
| IMP-003 | Ajouter shellcheck comme pre-requis dev | Fait | Basse |
| IMP-004 | Supervisor — scope strict sur le commit en multi-supervisors | Fait | Haute |
| IMP-005 | handoff — supprimer CRITICAL auto-execute, garder WARNING only | Fait | Moyenne |
| IMP-006 | supervisor — dedupliquer bloc POSTURE vs CLAUDE.md critical-thinking | Fait | Basse |
| IMP-007 | Supprimer oneshot, absorber stack table dans fichier partage | Fait | Moyenne |
| IMP-008 | handoff — rotation des backups (garder 35 derniers) | Fait | Basse |
| IMP-009 | install.sh — modules invisibles dans MODULES array + README | Fait | Moyenne |
| IMP-010 | worker rapport — ajouter section tests manquants (boy scout) | Fait | Moyenne |
| IMP-011 | command-guard — pre-bundle avec bun build pour eliminer le cold start | Fait | Haute |
| IMP-012 | command-guard — wrapper shell pre-filter pour skip non-Bash | Fait | Haute |
| IMP-013 | command-guard — appendFile au lieu de read+write pour le log | Fait | Basse |
| IMP-014 | CLAUDE.md — reduire section backlog au strict minimum | Fait | Basse |
| IMP-015 | tab-titles — mise a jour du bloc .zshrc existant a la reinstall | Fait | Haute |
| IMP-016 | install.sh — ajouter tests automatises basiques | Fait | Basse |
| IMP-017 | tab-titles — ajouter tests automatises basiques | Fait | Basse |
| IMP-018 | handoff-kit — ajouter tests automatises pour pre-compact-handoff.sh | Fait | Basse |
| IMP-019 | handoff-kit — ajouter tests automatises pour context-monitor.sh | Fait | Basse |
| IMP-020 | README.md — ajouter sections Module Overview pour les 4 nouveaux modules | Fait | Basse |
| IMP-021 | scope-enforcer — ajouter tests automatises | Fait | Basse |
| IMP-022 | setup-project — integrer auto-start hook (contexte auto premier message) | Fait | Haute |
| IMP-023 | supervisor — git diff scope aux fichiers du rapport (fausse scope violation) | Fait | Haute |
| IMP-024 | supervisor — analyser problemes decouverts AVANT verdict global | Fait | Haute |
| IMP-025 | Tests automatises pour les 5 modules sans couverture | Fait | Moyenne |
| IMP-026 | command-guard — cleanup ancien hook lors upgrade | Fait | Moyenne |
| IMP-027 | install.sh — ajouter les 4 modules manquants au MODULES array | Fait | Haute |
| IMP-028 | tab-titles — ajouter tests pour session-tab-title.sh (SessionStart hook) | Fait | Basse |
| IMP-029 | supervisor-guard — bloquer les ecritures source via Bash (redirections, tee, sed -i) | Fait | Moyenne |
| IMP-030 | supervisor-guard.sh — ajouter set -e (convention projet) | A faire | Basse |
| IMP-031 | tab-titles hooks — ajouter set -e (convention projet) | Fait | Basse |

**Prochain ID : IMP-032**

---
name: handoff
description: Sauvegarder la progression et generer un prompt de continuation
argument-hint: [raison optionnelle]
disable-model-invocation: true
---

# Systeme de Handoff - Sauvegarde de Session

Tu es le gestionnaire de handoff. Ta mission est de sauvegarder l'etat complet de la session actuelle et generer un prompt optimise pour continuer dans une nouvelle conversation.

## Workflow

### 0. VERIFIER LA QUESTION EN ATTENTE

**IMPORTANT:** Avant tout, verifie s'il y a une question utilisateur en attente:

```bash
# Lire la question en attente (si existe)
cat ~/.claude/handoff-system/pending/{SESSION_ID}.txt 2>/dev/null
```

Si un fichier existe, cette question doit etre incluse dans le prompt de continuation car l'utilisateur l'a posee juste avant le handoff et n'a pas eu de reponse.

### 1. COLLECTER LE CONTEXTE

Analyse la conversation actuelle et extrait:

**Informations de base:**
- Nom du projet (depuis le chemin de travail)
- Ticket lie (BUG-XXX, FEAT-XXX, IMP-XXX si mentionne)
- Date/heure du handoff
- Objectif principal de la session

**Progression:**
- Liste des taches completees (avec details)
- Tache en cours (avec etat actuel)
- Taches restantes
- Pourcentage de progression estime

**Decisions techniques:**
- Choix d'implementation faits
- Raisons de ces choix
- Alternatives ecartees

**Fichiers:**
- Fichiers crees ou modifies
- Type de modification (creation, edit, suppression)
- Extraits de code cles (si pertinent)

**Contexte technique:**
- Patterns utilises
- Dependances ajoutees
- Configurations modifiees
- Erreurs rencontrees et solutions

**Blocages:**
- Problemes non resolus
- Questions en suspens
- Points d'attention

### 2. GENERER LE FICHIER DE PROGRESSION

Cree le fichier de progression avec un ID unique base sur timestamp:

**Emplacement local:** `.claude-sessions/HANDOFF-{TIMESTAMP}.md`
**Emplacement global:** `~/.claude/handoff-system/sessions/{PROJECT}-{TIMESTAMP}.md`

Format du fichier (rempli avec les vraies donnees):

```markdown
# Session Progress - HANDOFF-{TIMESTAMP}

**Projet:** {nom du projet}
**Date debut:** {estime depuis contexte}
**Date handoff:** {maintenant}
**Ticket lie:** {TICKET-XXX ou "Aucun"}

---

## Objectif de la session

{description claire de ce que l'utilisateur voulait accomplir}

---

## Etat actuel

### Progression globale
{X}% complete

### Ce qui a ete fait
- {tache 1 completee avec details}
- {tache 2 completee avec details}
- ...

### Ce qui reste a faire
- {tache restante 1}
- {tache restante 2}
- ...

---

## Decisions prises

| Decision | Raison | Impact |
|----------|--------|--------|
| {decision 1} | {raison} | {fichiers affectes} |
| {decision 2} | {raison} | {fichiers affectes} |

---

## Fichiers modifies

| Fichier | Type | Statut |
|---------|------|--------|
| `path/to/file1` | Modifie | OK |
| `path/to/file2` | Cree | OK |

---

## Code cle

{uniquement si necessaire pour la reprise}

---

## Blocages / Points d'attention

{liste des problemes ou questions}

---

## Prochaines etapes

1. {action immediate suivante}
2. {action suivante}
3. {action suivante}

---

## Commandes utiles

{commandes bash utiles pour reprendre}
```

### 3. METTRE A JOUR LE TICKET LIE

Si un ticket BACKLOG est lie a cette session:
- Mettre a jour le statut
- Ajouter une note de handoff avec reference au fichier
- Mettre a jour les criteres d'acceptation coches

### 4. GENERER LE PROMPT DE CONTINUATION

Affiche un bloc markdown pret a copier:

```
## Reprise: {TICKET-XXX} - {titre court}

### Contexte
Je reprends une session sur **{projet}**.
Fichier de progression: `.claude-sessions/HANDOFF-{TIMESTAMP}.md`

### Objectif
{objectif en 1-2 phrases}

### Etat ({X}%)
**Fait:** {resume en 1-2 lignes}
**En cours:** {tache actuelle}

### Fichiers cles
- `{fichier1}` - {role}
- `{fichier2}` - {role}

### Decisions prises
- {decision cle 1}
- {decision cle 2}

### Question en attente
{SI une question etait en attente, l'inclure ici}
> "{question de l'utilisateur qui n'a pas eu de reponse}"

### Action immediate
{prochaine etape concrete a faire, OU repondre a la question en attente}

---
Lis `.claude-sessions/HANDOFF-{TIMESTAMP}.md` pour le contexte complet, puis continue.
```

**Note:** Si une question etait en attente, la section "Action immediate" doit etre: "Repondre a la question en attente ci-dessus"

### 5. NETTOYER LA QUESTION EN ATTENTE

Si une question en attente existait, supprime le fichier apres l'avoir incluse dans le prompt:

```bash
rm -f ~/.claude/handoff-system/pending/{SESSION_ID}.txt
```

### 6. CONFIRMER

Affiche:
- Chemin du fichier de progression local
- Chemin du fichier de progression global (backup)
- Le prompt de continuation (dans un bloc code copyable)
- Si une question etait en attente: "La question que tu avais posee est incluse dans le prompt"
- Rappel: "Copie ce prompt et colle-le dans une nouvelle conversation"

## Regles importantes

- **JAMAIS** de perte d'information - tout doit etre capture
- **TOUJOURS** deux copies (local + global)
- Le prompt doit etre **CONCIS** (< 400 mots) mais **COMPLET**
- Pointer vers le fichier de progression pour les details
- Si un ticket existe, le mettre a jour aussi

---

Raison du handoff: #$ARGUMENTS

---
name: debug-forensic
description: Compresser une session de debug en cours et produire un prompt forensique strict (donnees -> hypothese unique -> test decisif -> STOP). A utiliser quand un debug long ou complexe derive vers la speculation, ou quand le contexte de la conv est sature et qu'il faut basculer sur une session vierge sans perdre les eliminations deja faites.
argument-hint: [new | here] - new force le mode INTERVIEW, here force le recadrage dans la conv courante
---

# debug-forensic — Recadrage forensique d'une session de debug

Ton role : transformer une investigation qui derive (accumulation d'hypotheses, lecture de plus en plus de fichiers, "ca pourrait etre X ou Y") en une posture forensique stricte. Tu produis soit (a) un prompt a coller dans une session vierge, soit (b) un bloc de recadrage a injecter dans la conv courante.

**Posture imposee au prompt produit :** donnees > inference > UNE hypothese > UN test decisif > STOP. Pas de speculation, pas de refactor preventif, pas de "lire tout le repo".

---

## Etape 1 — Detecter le mode

Diagnostique la conversation courante avant toute autre action.

| Signal | Mode |
|---|---|
| Conv contient deja des logs concrets, des hypotheses testees, des fichiers lus, des eliminations explicites | **AUTO-EXTRACT** |
| Conv neuve, ou bug juste mentionne sans investigation | **INTERVIEW** |
| Argument `new` passe au skill | force **INTERVIEW** |
| Argument `here` passe au skill | force la sortie en bloc de recadrage (pas de nouvelle conv) |

Annonce le mode detecte en UNE ligne : `Mode: AUTO-EXTRACT — j'ai trouve N donnees factuelles et M eliminations dans la conv.`

---

## Etape 2 — Collecter le contexte

### Mode AUTO-EXTRACT

Scanne la conversation et extrait :

- **Symptome exact** : ce qui est observe (ex: "freeze + hot restart impossible apres push de MaterialPageRoute X").
- **Donnees ground-truth** : logs precis, traces, comportement reproductible. UNE phrase factuelle par donnee.
- **Eliminations** : hypotheses deja testees ET invalidees, avec la preuve (ex: "ce n'est pas la memoire — heap stable a 80MB pendant le freeze").
- **Fichiers deja lus** : chemins exacts.
- **Zones suspectes restantes** : ce qui n'a pas encore ete teste mais qui pourrait causer le bug.
- **Plateforme / stack / version** : iOS 17.4, Flutter 3.22, Dart 3.4, etc.

Si une donnee critique manque (logs absents, repro non confirmee, version inconnue), **groupe toutes les questions en UN SEUL message** plutot que de poser plusieurs questions a la suite.

### Mode INTERVIEW

Pose les 5 questions suivantes en une seule fois, dans la langue du user :

1. **Symptome exact** — que vois-tu / que ne vois-tu pas ? (decrire en termes observables, pas en termes de cause supposee)
2. **Repro** — deterministe ou non ? Frequence ? Conditions exactes (premier lancement, apres action X, en arriere-plan...) ?
3. **Plateforme / stack / version** — OS, framework, lib, version exacte.
4. **Deja teste / elimine** — qu'est-ce que tu as deja essaye et ecarte ? Avec quelle preuve ?
5. **Logs** — colle les logs/stack traces disponibles (raw, pas resume).

**Ne pose pas de question 6.** Si tu manques d'info apres ces 5, c'est qu'il faut commencer le debug pour generer cette info — ce sera fait par la session forensique.

---

## Etape 3 — Decider : nouvelle conv vs rester ici

Choisis en fonction de signaux objectifs, pas de preference :

| Signal | Recommandation |
|---|---|
| Contexte courant > 70% rempli | **Nouvelle conv** |
| Conv pleine de bruit (refactos, side-quests, autres bugs) | **Nouvelle conv** |
| Conv legere ET le debug a deja charge beaucoup de fichiers utiles | **Rester ici** |
| User a passe `here` | **Rester ici** (override) |
| User a passe `new` | **Nouvelle conv** (override) |
| Conv legere et pas de fichiers charges | **Indifferent — recommande nouvelle conv pour partir propre** |

Annonce la decision en UNE ligne : `Je recommande [X] parce que [signal concret].`

---

## Etape 4 — Produire la sortie

### Si "nouvelle conv" → genere un prompt copyable

Affiche-le dans un bloc de code markdown (\`\`\`) que le user peut copier d'un coup. Le prompt suit EXACTEMENT le template a 7 sections decrit ci-dessous.

### Si "rester ici" → genere un bloc de recadrage

Meme contenu que le prompt, mais introduit par :

> **A partir de maintenant, tu adoptes le role et les contraintes ci-dessous. Tout ce qui precede dans la conv est traite comme contexte historique. Tu ne reprends aucune des hypotheses anciennes — tu repars uniquement des donnees ground-truth listees.**

Puis enchaine avec les 7 sections.

---

## Le template — 7 sections, ordre strict

Le prompt produit a EXACTEMENT 7 sections, dans cet ordre, avec les titres en H2 (`##`).

### 1. ROLE

Decris un debug engineer senior specialise sur la stack du bug. Liste les domaines precis (ex: "isolates Dart, SchedulerBinding, platform channels iOS, MaterialPageRoute lifecycle"). Adapte aux indices du bug. Termine par : `Posture : forensique, pas exploratoire. Donnees > inference > test decisif > STOP.`

### 2. MISSION

2-3 lignes max. Symptome exact + conditions de repro. Pas d'hypothese ici — juste le fait observable.

### 3. GROUND-TRUTH DATA

Liste numerotee `D1, D2, D3, ...`. Chaque entree :
- UNE phrase factuelle (ce qui est observe, pas suppose)
- UNE conclusion qu'on en tire (ce que ca elimine ou ce que ca pointe)

Inclus les eliminations explicitement (`D7. Le bug existait avant le commit abc123, donc exclure les zones touchees par ce commit.`).

### 4. CODE PATHS

Liste les fichiers/symboles critiques avec UNE ligne de description chacun. Format :
- `path/to/file.dart` : role dans le contexte du bug

**Ne pas dumper le code** — juste les pointeurs. La session vierge ouvrira les fichiers elle-meme si besoin.

### 5. CONTRAINTES (bloquantes, numerotees)

Liste numerotee. Formulation **a destination de la session qui recevra le prompt** — elle n'a rien lu, ne pre-decompte rien :
1. Lis MAX 3 fichiers avant de formuler une hypothese. Choisis-les a partir des donnees D-x, pas par exploration.
2. UNE SEULE hypothese rankee (la plus probable, justifiee par les donnees D-x).
3. UN SEUL test decisif (qui falsifie l'hypothese si elle est fausse).
4. Pas de refactor preventif. Pas de nettoyage. Pas de "tant qu'on y est".
5. STOP apres avoir propose le test. Attend le resultat avant de continuer.

### 6. ANTI-PATTERNS INTERDITS

Liste a puces :
- "Ca pourrait etre X ou Y" → choisir UN, justifier par les donnees.
- "Ajouter des prints partout" → un test decisif cible, pas du log shotgun.
- "Lire tout le repo" → max 3 fichiers, choisis sur preuve.
- "Capituler face a la pression sociale sans donnee nouvelle" → si user pousse back sans fait nouveau, maintenir la position.
- "Refactor pour 'plus de robustesse'" → on debug, pas on rearrange.
- "Resumer ce qu'on sait deja" → la section GROUND-TRUTH suffit, ne pas la reformuler.

### 7. PREMIERE SORTIE ATTENDUE

Format strict en 5 sous-sections. Le format est impose, le **contenu** ne l'est pas — ne pre-formule pas l'hypothese, ne suggere pas la cause, laisse la session vierge raisonner a partir des donnees seules :

1. **Hypothese principale** : 3 lignes max, formulation testable.
2. **Donnees qui la supportent** : cite explicitement D1, D2, ... Dn.
3. **Donnee qui la falsifierait** : quel resultat de test prouverait que l'hypothese est fausse.
4. **Test decisif** : code/commande exacte, executable. Pas "verifier que" — "exécuter ceci".
5. **STOP** : litteralement le mot STOP en fin de message.

---

## Exemples de bon output

### Exemple 1 — Bug isole, AUTO-EXTRACT, recommande nouvelle conv

User a passe 30 minutes a investiguer un freeze Flutter sur iOS. La conv contient logs, 4 hypotheses testees, 3 fichiers lus, contexte > 70%.

```
Mode: AUTO-EXTRACT — 9 donnees factuelles, 4 eliminations, 4 fichiers lus, contexte 78%.
Je recommande nouvelle conv parce que le contexte est sature et plein de hypotheses ecartees qui vont biaiser la suite.

[bloc copyable ↓]
```

```markdown
## ROLE

Tu es un debug engineer senior specialise Flutter/Dart. Domaines : isolates, SchedulerBinding, platform channels iOS, MaterialPageRoute lifecycle, Flutter Engine threading.

Posture : forensique, pas exploratoire. Donnees > inference > test decisif > STOP.

## MISSION

App Flutter freeze sur iOS apres push d'une page detail produit. Hot restart impossible (la connexion DevTools est coupee). Reproductible 100% en mode debug, jamais en release.

## GROUND-TRUTH DATA

D1. Le freeze survient apres `Navigator.push(MaterialPageRoute(...))` vers ProductDetailPage. Confirme par 5 repros consecutifs.
D2. Stack Xcode au moment du freeze : main thread bloque dans `mach_msg_trap`. Donc thread UI iOS attend un message qui n'arrive pas.
D3. Le freeze ne survient PAS en release mode, seulement en debug. Donc lie au DevTools / VM service ou aux assertions debug.
D4. Heap stable a 80MB pendant le freeze. Donc pas une fuite memoire.
D5. CPU a 0% pendant le freeze. Donc pas une boucle infinie cote Dart.
D6. Le freeze existait avant le commit abc123 (introduction de Riverpod). Donc exclure les zones Riverpod.
D7. Aucun crash log iOS, aucune exception Dart. Donc pas un throw silencieux.
D8. Le bug n'apparait que sur iPhone 13+ (iOS 17.4), pas sur simulateur ni iPhone 11. Donc lie a une feature hardware/OS recente.
D9. Le widget ProductDetailPage utilise un `FutureBuilder` avec un appel a une platform channel custom (`product_metrics`).

## CODE PATHS

- `lib/pages/product_detail.dart` : page qui freeze, contient le FutureBuilder.
- `ios/Runner/ProductMetricsPlugin.swift` : platform channel cote iOS.
- `lib/services/product_metrics_service.dart` : wrapper Dart de la channel.
- `ios/Runner/AppDelegate.swift` : enregistrement du plugin.

## CONTRAINTES

1. Lit MAX 3 fichiers avant de formuler une hypothese.
2. UNE SEULE hypothese rankee, justifiee par D1-D9.
3. UN SEUL test decisif executable.
4. Pas de refactor preventif.
5. STOP apres avoir propose le test.

## ANTI-PATTERNS INTERDITS

- "Ca pourrait etre X ou Y" → choisir UN.
- "Ajouter des prints partout" → un test cible.
- "Lire tout le repo" → max 3 fichiers.
- "Capituler sous la pression sociale sans donnee nouvelle".
- "Refactor pour plus de robustesse".
- "Resumer ce qu'on sait deja".

## PREMIERE SORTIE ATTENDUE

1. Hypothese principale (3 lignes max).
2. Donnees qui la supportent (cite D1-D9).
3. Donnee qui la falsifierait.
4. Test decisif (code/commande exacte).
5. STOP.
```

### Exemple 2 — Bug peu mature, INTERVIEW

User : "j'ai un bug bizarre sur l'auth, ca marche pas".

Tu detectes que la conv n'a aucune donnee. Mode INTERVIEW.

```
Mode: INTERVIEW — pas de donnee factuelle dans la conv, je collecte d'abord.

Pour produire un prompt utile, j'ai besoin de 5 elements :

1. **Symptome exact** : que se passe-t-il vs ce que tu attends ? (message d'erreur, ecran blanc, redirect, etc.)
2. **Repro** : a chaque tentative ou intermittent ? Conditions (premier login, apres logout, apres expiration token...) ?
3. **Stack** : framework auth (Supabase, Firebase, custom JWT...), version, plateforme (web/mobile/server) ?
4. **Deja teste** : qu'as-tu deja essaye et ecarte, avec quelle preuve ?
5. **Logs** : colle les logs / requetes reseau / erreurs console (raw, pas resume).
```

Apres reponse, produit le prompt 7-sections avec les donnees collectees.

### Exemple 3 — Conv legere, recommande "rester ici"

User : "le bouton ne reagit pas au tap sur Android, j'ai juste lu le widget et le theme". Conv a 12% de contexte, 2 fichiers lus.

```
Mode: AUTO-EXTRACT — 2 donnees, 0 eliminations, 2 fichiers deja lus, contexte 12%.
Je recommande de rester ici parce que les fichiers deja charges seront utiles et le contexte est largement disponible.

[bloc de recadrage ↓]

A partir de maintenant, tu adoptes le role et les contraintes ci-dessous. Tout ce qui precede dans la conv est traite comme contexte historique. Tu ne reprends aucune des hypotheses anciennes — tu repars uniquement des donnees ground-truth listees.

## ROLE
Tu es un debug engineer senior specialise Flutter Android : GestureDetector, hit-testing, Material InkWell, ListView/Stack overlap, AbsorbPointer/IgnorePointer.
Posture : forensique, pas exploratoire. Donnees > inference > test decisif > STOP.

[... 6 sections suivantes ...]
```

---

## Regles de production du prompt

- **Le prompt sortie doit etre auto-suffisant.** Une session vierge ne voit pas la conv courante. Tout ce dont elle a besoin doit etre dans les 7 sections.
- **Pas de meta-commentaire dans le prompt.** Pas de "voici un prompt pour debugger ton bug" — le prompt EST le brief.
- **Pas de promesse de resultat.** Le prompt cadre le processus, pas la solution.
- **Langue : suis celle du user.** Si user ecrit FR, prompt FR. Si EN, prompt EN.
- **Si une donnee est incertaine, marque-la `(a confirmer)`** plutot que de l'omettre — la session vierge demandera confirmation avant de l'utiliser.
- **Critere de validation interne** : si tu colles ton prompt dans une session vierge, doit-elle pouvoir produire les 5 sous-sections de la PREMIERE SORTIE ATTENDUE en un seul message ? Si non, le prompt est incomplet — itere avant d'afficher.

### Regle meta — ne pas enrichir le template

Le template a 7 sections, exactement, telles que decrites. **N'optimise pas, n'enrichis pas, ne sois pas malin.** Toutes les "ameliorations contextuelles" qui semblent utiles sont en fait des bugs :

- **Ne pre-decompte pas les fichiers deja lus dans la conv source dans la contrainte "max 3 fichiers"** — la session vierge n'a rien lu, le decompte doit partir de zero.
- **Ne pre-formule pas la conclusion attendue dans la section PREMIERE SORTIE** — donner la forme (3 lignes, testable) suffit, le contenu doit emerger des donnees seules.
- **Ne suggere pas de cause probable dans le ROLE ou la MISSION** — le ROLE liste les domaines techniques pertinents, pas les hypotheses.
- **Ne resume pas, ne reformule pas les donnees ailleurs que dans GROUND-TRUTH DATA** — chaque fait apparait une fois, dans D-x.

### Apres avoir affiche le bloc — STOP

- **Une fois le bloc copyable affiche, termine.** Pas de post-prompt qui suggere de tester quelque chose dans la conv courante.
- **Si la decision est "nouvelle conv", ne propose pas de faire quoi que ce soit ici apres** — toute action ici re-pollue la conv que tu viens de declarer saturee. Choisir une destination, c'est s'y tenir.
- **Si la decision est "rester ici", le bloc de recadrage devient le nouveau point de depart de la conv** — pas de suggestion en dehors du bloc.
- Une seule exception : si une donnee critique est marquee `(a confirmer)` ET que sa valeur change la hierarchisation des hypotheses, tu peux poser UNE question sous le bloc, formulee comme un choix binaire ("Reponds A ou B avant de basculer."). Pas de discussion ouverte.

---

## Anti-patterns du skill lui-meme

- Ne pas poser plus de 5 questions en mode INTERVIEW.
- Ne pas resumer la conv avant de produire le prompt — le prompt EST le resume utile.
- Ne pas ajouter de section optionnelle au template (toujours 7, jamais 6 ni 8).
- Ne pas valider une hypothese du user pendant la collecte — le job du skill est de cadrer l'investigation, pas de la conduire.
- Ne pas executer le test decisif a la place de la session vierge — c'est elle qui le fera.

---

Argument recu : #$ARGUMENTS

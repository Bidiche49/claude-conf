# Fixture — Fausse conversation pour test du skill /debug-forensic

Cette fixture simule une conversation de debug deja avancee. Quand le skill est invoque
sur cette conv, il doit detecter le mode AUTO-EXTRACT (pas INTERVIEW) parce qu'elle
contient des donnees factuelles, des eliminations explicites et des fichiers deja lus.

Validation manuelle :
1. Coller le contenu ci-dessous dans une nouvelle session Claude Code.
2. Invoquer `/debug-forensic`.
3. Verifier que le skill :
   - Annonce `Mode: AUTO-EXTRACT` (pas INTERVIEW).
   - Liste les donnees D1..Dn extraites de la conv.
   - Recommande "nouvelle conv" (le contexte simule est sature).
   - Produit un prompt EXACTEMENT a 7 sections.
   - Le prompt produit, colle dans une session vierge, doit pouvoir generer en UN
     seul message les 5 sous-sections de la PREMIERE SORTIE ATTENDUE.

---

## Conv simulee — debug Flutter freeze iOS

User : "L'app freeze sur iOS 17 quand on push la page detail produit. Hot restart impossible. Reproductible 100% en debug."

Assistant : "OK. J'ai lu lib/pages/product_detail.dart et ios/Runner/AppDelegate.swift. Le freeze survient apres Navigator.push(MaterialPageRoute(...)).

Stack Xcode : main thread bloque dans mach_msg_trap. Pas de crash log iOS. Heap stable a 80MB. CPU a 0%."

User : "J'ai teste sans Riverpod, meme bug. Le bug existait avant le commit qui a introduit Riverpod (abc123). Donc on peut eliminer Riverpod."

Assistant : "OK, donc Riverpod elimine. J'ai aussi verifie que ce n'est pas une fuite memoire (heap stable 80MB) ni une boucle infinie (CPU 0%).

J'ai lu lib/services/product_metrics_service.dart. La page utilise un FutureBuilder avec un appel platform channel custom 'product_metrics'."

User : "Pas reproductible sur simulateur ni sur iPhone 11. Seulement iPhone 13+ avec iOS 17.4."

Assistant : "Donc lie a une feature hardware/OS recente. Hypothese : le platform channel deadlock sur certaines versions d'iOS.

Mais avant de creuser ca, je voudrais verifier si... [conv continue avec 4-5 hypotheses partielles non testees, refacto suggere, lecture d'autres fichiers...]"

User : "Le contexte est sature, j'ai 78%. Je veux remettre l'investigation au propre. /debug-forensic"

---

## Resultat attendu apres /debug-forensic

Le skill doit produire approximativement ceci (variations acceptables sur le wording) :

```
Mode: AUTO-EXTRACT — 9 donnees factuelles, 1 elimination explicite, 3 fichiers lus, contexte 78%.
Je recommande nouvelle conv parce que le contexte est sature et plusieurs hypotheses non testees vont biaiser la suite.

[bloc copyable ↓]
```

Puis un prompt en bloc \`\`\`markdown avec exactement les 7 sections :
1. ROLE (debug engineer Flutter/iOS)
2. MISSION (freeze iOS push detail produit)
3. GROUND-TRUTH DATA (D1..D9 minimum, dont l'elimination Riverpod et le bug pre-commit abc123)
4. CODE PATHS (3 fichiers minimum, dont product_detail.dart, AppDelegate.swift, product_metrics_service.dart)
5. CONTRAINTES (5 regles : max 3 fichiers, 1 hypothese, 1 test, pas de refactor, STOP)
6. ANTI-PATTERNS INTERDITS
7. PREMIERE SORTIE ATTENDUE (5 sous-sections incluant STOP)

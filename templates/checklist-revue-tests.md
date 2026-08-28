# Checklist — Revue des cas et procédures de test

> **Objectifs DO-178C couverts** : A-7.1 à A-7.4
> **Indépendance requise** : DAL A et B.

| Champ | Valeur |
|---|---|
| Campagne revue | |
| Version | |
| Auteur | |
| Relecteur(s) | |
| Date | |
| Verdict | ☐ accepté ☐ accepté sous réserve ☐ refusé |

---

## 1. Traçabilité

- [ ] Chaque cas de test est tracé à au moins une exigence : le troisième
      argument de `Testing.Start` porte au moins un identifiant.
- [ ] **[outil]** `trace_check.py --strict` ne signale aucun test orphelin.
- [ ] Chaque exigence est couverte par au moins un cas de test.
- [ ] Les exigences de **haut niveau** ont leurs propres tests, distincts des
      tests de bas niveau (A-6.1/A-6.2 contre A-6.3/A-6.4).

## 2. Conception des cas

- [ ] Les cas sont dérivés des **exigences**, pas du code.
- [ ] Les classes d'équivalence du domaine d'entrée sont identifiées et
      chacune est représentée.
- [ ] Les **valeurs limites** sont testées : borne exacte, juste avant, juste
      après.
- [ ] Les cas **nominaux** et les cas de **robustesse** sont tous deux présents
      (§6.4.2.1 et §6.4.2.2).
- [ ] Pour une machine à états : tous les états **et** toutes les transitions,
      y compris les transitions d'**annulation**.
- [ ] Les séquences réalistes sont couvertes (bruit, oscillation, rampe, panne
      intermittente).
- [ ] Si un flottant entre dans le système, les valeurs non finies (NaN, ±∞)
      sont testées. En virgule fixe, la question ne se pose pas — voir le
      module 01.

## 3. Qualité des vérifications

- [ ] Le résultat attendu est calculé **indépendamment** du code testé.
- [ ] Les tolérances sont explicites et justifiées ; en virgule fixe, le pas
      du type suffit et se cite.
- [ ] Le test vérifie l'**état complet**, pas seulement la valeur de retour.
- [ ] Les tests de robustesse vérifient aussi que les sorties **ne sont pas**
      modifiées en cas d'erreur.
- [ ] Chaque cas part d'un état initial connu ; aucun état ne fuit d'un cas à
      l'autre.

## 4. Couverture structurelle

- [ ] **[outil]** La couverture atteint le niveau exigé par le DAL :
      instructions au DAL C, décisions au DAL B, MC/DC au DAL A.
- [ ] Tout écart est **expliqué** : cas de test manquant, code inatteignable
      à retirer, ou code désactivé à justifier (§6.4.4.3).
- [ ] Aucun cas de test n'a été ajouté dans le seul but de faire monter un
      chiffre.

## 5. Analyse de mutation

- [ ] Pour chaque décision importante, une mutation a été essayée et au moins
      un test a échoué.
- [ ] Les mutations essayées sont enregistrées, avec le test qui les détecte.
- [ ] Toute mutation non détectée a donné lieu à un nouveau cas de test.

## 6. Procédure et résultats

- [ ] La procédure d'exécution est écrite et reproductible.
- [ ] L'environnement d'exécution est identifié (SECI).
- [ ] Les résultats sont archivés sous contrôle de configuration.
- [ ] Tout écart entre résultat attendu et obtenu est expliqué et tracé à une
      anomalie.

---

## Constats

| # | Cas de test | Constat | Sévérité | Action | Statut |
|---|---|---|---|---|---|
| 1 | | | maj / min / obs | | ouvert |

---

## Signatures

| Rôle | Nom | Date | Visa |
|---|---|---|---|
| Auteur | | | |
| Relecteur (indépendant) | | | |
| Assurance qualité | | | |

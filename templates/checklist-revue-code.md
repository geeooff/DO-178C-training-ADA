# Checklist — Revue de code source Ada / SPARK

> **Objectifs DO-178C couverts** : A-5.1 à A-5.6
> **Indépendance requise** : DAL A et B — le relecteur ne peut pas être l'auteur.
> **Durée conseillée** : 300 à 500 lignes par séance, pas plus.

| Champ | Valeur |
|---|---|
| Composant | |
| Fichiers revus | |
| Version / commit | |
| Auteur | |
| Relecteur(s) | |
| Date | |
| Verdict | ☐ accepté ☐ accepté sous réserve ☐ refusé |

---

> **Avant de commencer.** Une bonne partie de ce qui suit est déjà vérifiée par
> la chaîne d'outils : `verify.sh` doit être **vert** avant la séance. Une revue
> qui passe son temps sur ce qu'un compilateur attrape est une revue gâchée.
> Les cases marquées **[outil]** se cochent en lisant un rapport, pas le code.

---

## 1. Conformité aux exigences de bas niveau — A-5.1

- [ ] Chaque sous-programme non trivial porte une annotation `@satisfies LLR-…`.
- [ ] Le code fait **exactement** ce que dit l'exigence — ni moins, ni **plus**.
- [ ] Les valeurs numériques du code correspondent à celles de l'exigence
      (seuils, domaines, tolérances, unités).
- [ ] Le comportement **aux bornes** est conforme (`<` contre `<=`).
- [ ] Le comportement **hors domaine** est conforme à l'exigence de robustesse.
- [ ] La postcondition dit ce que le sous-programme **rend**, pas ce que fait
      son corps. Une `Post` qui paraphrase le code ne vaut rien.
- [ ] Aucun code n'est présent sans exigence correspondante.

## 2. Conformité à l'architecture — A-5.2

- [ ] Le composant n'appelle que les interfaces prévues par le SDD.
- [ ] **[outil]** Les `Global` et `Depends` correspondent à la matrice de
      couplage du SDD ; `gnatprove` les a vérifiés contre le corps.
- [ ] Un paquetage à état déclare un `Abstract_State` et le raffine.
- [ ] La coquille d'état ne contient **aucune décision** (règle R-31).

## 3. Vérifiabilité — A-5.3

- [ ] Chaque décision est atteignable par un jeu d'entrées réaliste.
- [ ] **[outil]** Aucune branche inatteignable : le rapport `gnatcov` ne
      montre ni `-` ni `!` inexpliqué.
- [ ] Une garde redondante avec une précondition ou un `Type_Invariant` a été
      **retirée**, pas contournée par un test impossible.
- [ ] Les décisions à plusieurs conditions sont écrites en `if` plutôt qu'en
      expression rendue directement, pour que le rapport se lise ligne à ligne.

## 4. Conformité au standard de codage — A-5.4

- [ ] **[outil]** Compilation à **zéro avertissement** sous `-gnatwa -gnatwe`.
- [ ] **[outil]** `gnatformat --check --charset=utf-8` ne signale rien.
- [ ] Aucun nombre magique ; toute constante est nommée et tracée à sa source.
- [ ] Types de domaine explicite (`subtype Litres is Natural range 0 .. …`),
      jamais `Integer` ni `Natural` nus dans une spécification publique.
- [ ] Grandeurs physiques distinctes = **types dérivés** distincts.
- [ ] `Small` explicite sur tout type à virgule fixe.
- [ ] Pas de récursion.
- [ ] Aucune allocation dynamique ; `No_Allocators` s'applique.
- [ ] Aucune exception ; `No_Exception_Handlers` s'applique.
- [ ] Aucun `Ada.Text_IO`, aucune chaîne de longueur variable.
- [ ] Boucles à bornes statiques ; tout `while` porte un `Loop_Variant`.
- [ ] Toute déviation porte une justification écrite — un `pragma Annotate`
      nu, sans raison, est un refus.

## 5. Traçabilité — A-5.5

- [ ] **[outil]** `trace_check.py --strict` ne signale aucun défaut.
- [ ] Aucune exigence référencée n'est inconnue.
- [ ] Aucun test orphelin.
- [ ] Les cas de test cités par le SRD et le SDD existent réellement.

## 6. Exactitude et cohérence — A-5.6

- [ ] **[outil]** `gnatprove --checks-as-errors=on` : **toutes** les
      vérifications sont déchargées ou **justifiées avec leur raison**.
- [ ] **Débordement** : chaque opération arithmétique est bornée par son type
      ou par un contrat, pas par un commentaire.
- [ ] **Division** : le diviseur nul est exclu par le type ou par la
      précondition.
- [ ] **Conversions** : toute conversion entre types dérivés est explicite et
      son facteur est nommé.
- [ ] **Virgule fixe** : le `Small` est explicite, et l'arrondi est spécifié.
- [ ] **Tableaux** : tout indice venu de l'extérieur est validé avant usage.
- [ ] **Pile** : `-fstack-usage` ne montre aucune trame `dynamic` dans les
      unités embarquées.
- [ ] **Initialisation** : `Initializes` est tenu ; aucun `out` non affecté
      sur un chemin.
- [ ] **Suppression de vérification** : tout `pragma Suppress` cite
      l'obligation `gnatprove` qui le justifie.

## 7. Lisibilité et maintenance

- [ ] Les noms disent l'intention, pas l'implémentation.
- [ ] Identifiants en anglais, commentaires en français.
- [ ] Les commentaires expliquent le **pourquoi** — objectif DO-178C,
      accident, arbitrage — jamais seulement le **quoi**.
- [ ] Aucun code commenté laissé en place.
- [ ] Aucun `TODO` / `FIXME` sans référence à une anomalie ouverte.

---

## Constats

| # | Fichier:ligne | Catégorie | Constat | Sévérité | Action | Statut |
|---|---|---|---|---|---|---|
| 1 | | | | maj / min / obs | | ouvert |
| 2 | | | | | | |

**Sévérité** — *majeur* : non-conformité à un objectif, bloque l'acceptation ;
*mineur* : à corriger avant baseline ; *observation* : amélioration suggérée.

---

## Signatures

| Rôle | Nom | Date | Visa |
|---|---|---|---|
| Auteur | | | |
| Relecteur (indépendant) | | | |
| Assurance qualité | | | |

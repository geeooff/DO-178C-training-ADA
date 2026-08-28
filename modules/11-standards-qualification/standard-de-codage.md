# Standard de codage Ada / SPARK

> **Document** : *Software Code Standards*, DO-178C §11.8
> **Objectif visé** : A-5.2 — *le code source est conforme au standard*
> **Version** : 1.0
> **Statut de configuration** : CC2

---

## Comment lire ce document

Chaque règle porte, en plus de son énoncé, **la façon dont elle est vérifiée**.
C'est la colonne la plus importante : une règle qu'aucun outil ne vérifie
repose sur la vigilance humaine, et la vigilance humaine ne passe pas un audit.

| Mécanisme | Ce que ça veut dire |
|---|---|
| **compilateur** | violée = erreur de compilation, ici et en CI |
| **preuve** | violée = obligation non déchargée par `gnatprove` |
| **outil** | vérifiée par un script du dépôt |
| **revue** | vérifiée par un humain, et **seulement** par lui |

L'objectif d'un bon standard n'est pas d'avoir beaucoup de règles : c'est
d'avoir le moins possible de règles en **revue**.

---

## 1. Langage et normes

### R-01 — Le code est écrit en Ada 2022

- **Vérification** : compilateur (`-gnat2022` dans `shared.gpr`)
- **Pourquoi** : les aspects `Pre`, `Post`, `Contract_Cases`, les agrégats
  `[…]` et `'Image` sur tout type en dépendent.

### R-02 — Le code destiné au vol est en `SPARK_Mode => On`

- **Vérification** : preuve. Une unité en `SPARK_Mode => Off` est ignorée par
  `gnatprove`, et le rapport le dit unité par unité.
- **Exceptions autorisées** : le harnais de test `common/src/testing.ads`, les
  programmes de démonstration `main.adb`. Chaque exclusion est **écrite dans
  le fichier**, jamais implicite.

### R-03 — Aucun avertissement de compilation n'est toléré

- **Vérification** : compilateur (`-gnatwa -gnatwe`)
- **Pourquoi** : un avertissement toléré est un avertissement qu'on cesse de
  lire. Le seul seuil tenable est zéro.

---

## 2. Types et données

### R-10 — Toute grandeur physique a son propre type

- **Vérification** : compilateur (l'absence de conversion implicite)
- **Énoncé** : litres, kilogrammes, degrés, comptes bruts sont des **types
  dérivés distincts**, pas des `Integer` ni des sous-types les uns des autres.
- **Pourquoi** : Mars Climate Orbiter. Voir module 01 §1.2.

### R-11 — Toute variable a un domaine borné par son type

- **Vérification** : compilateur et preuve
- **Énoncé** : `Integer` et `Natural` nus sont interdits dans les
  spécifications publiques du code de vol. On déclare
  `subtype Litres is Natural range 0 .. 10_000;`.

### R-12 — Pas de flottant sans justification écrite

- **Vérification** : revue
- **Énoncé** : la virgule fixe est le défaut. Tout usage du flottant est
  accompagné, dans le fichier, de la justification de précision exigée par
  A-5.6.

### R-13 — Le `Small` d'un type à virgule fixe est explicite

- **Vérification** : revue
- **Pourquoi** : sans clause `Small`, GNAT prend la puissance de deux
  inférieure, et `0.804` devient `0,8037109375`. Voir module 01 §1.4.

---

## 3. Contrats

### R-20 — Tout sous-programme public a une postcondition

- **Vérification** : revue, puis preuve
- **Énoncé** : la postcondition dit ce que le sous-programme **rend**, pas ce
  que fait son corps. Une postcondition qui paraphrase le corps ne vaut rien.

### R-21 — Pas de programmation défensive redondante avec une précondition

- **Vérification** : preuve, et couverture structurelle
- **Énoncé** : si `Pre => X <= 10` existe, le corps ne re-teste pas `X`.
- **Pourquoi** : le test redondant est du code qu'aucune exigence ne justifie,
  et la couverture MC/DC finit par le révéler. Voir module 08 §1.5, où c'est
  arrivé pour de vrai.

### R-22 — `'Old` nomme une entité

- **Vérification** : compilateur (RM 6.1.1(27))
- **Énoncé** : écrire `Level (T'Old)`, jamais `Level (T)'Old`.

### R-23 — Toute boucle non bornée porte un `Loop_Variant`

- **Vérification** : preuve
- **Énoncé** : un `while` sans variant est un défaut. Un `for` sur un intervalle
  statique n'en a pas besoin.

---

## 4. Flot et état

### R-30 — Tout paquetage à état déclare un `Abstract_State`

- **Vérification** : preuve
- **Énoncé** : et chaque sous-programme déclare son `Global` et son `Depends`.
- **Pourquoi** : c'est ce qui produit l'artefact de couplage données/contrôle
  exigé par A-7.8, sans tableau à tenir à la main.

### R-31 — La coquille d'état ne contient aucune décision

- **Vérification** : revue
- **Énoncé** : un paquetage porteur d'`Abstract_State` se limite à mémoriser
  et à déléguer. Toute logique va dans un paquetage sans état.
- **Pourquoi** : deux raisons. Une décision sans état se teste exhaustivement.
  Et `gnatcov` ne sait pas instrumenter un paquetage à état abstrait — voir
  module 04 §1.7.

### R-32 — Une fonction pure le déclare

- **Vérification** : preuve (`Global => null`)

---

## 5. Erreurs et exécution

### R-40 — Aucune exception dans le code de vol

- **Vérification** : compilateur, par
  `pragma Restrictions (No_Exception_Handlers, No_Exception_Propagation)`
- **Énoncé** : un échec est une valeur de retour. Voir module 06.

### R-41 — Aucune allocation dynamique

- **Vérification** : compilateur, par
  `pragma Restrictions (No_Allocators)` et
  `No_Dependence => Ada.Unchecked_Deallocation`

### R-42 — Pas de `Ada.Text_IO` ni de chaîne de longueur variable

- **Vérification** : revue, et analyse de pile
- **Pourquoi** : `X'Image` produit une chaîne de longueur calculée à
  l'exécution, qui vit sur la pile secondaire. `scripts/stack-usage.sh` le
  rend visible : c'est la seule source de trames non statiques du dépôt.

### R-43 — Aucune récursion

- **Vérification** : revue
- **Pourquoi** : la profondeur de pile cesse d'être calculable.

---

## 6. Suppression de vérifications

### R-50 — `pragma Suppress` exige une preuve

- **Vérification** : revue **et** preuve
- **Énoncé** : toute suppression de vérification est accompagnée, dans le même
  fichier, de la référence à l'obligation `gnatprove` qui la justifie.
- **Pourquoi** : supprimer une vérification qui *aurait* échoué rend
  l'exécution *erroneous* (RM 11.5). C'est le mécanisme d'Ariane 501.

### R-51 — Toute justification `pragma Annotate` porte une raison écrite

- **Vérification** : outil (le rapport `gnatprove` les liste)
- **Énoncé** : `False_Positive` quand l'outil se trompe, `Intentional` quand
  on accepte le risque. Les deux exigent une phrase qui explique, pas un
  « faux positif ».

---

## 7. Forme

### R-60 — Style GNAT standard

- **Vérification** : compilateur (`-gnatyy`), et `gnatformat --check`
- **Énoncé** : 79 colonnes, indentation de 3, deux espaces après `--`,
  `Mixed_Case_With_Underscores`.

### R-61 — Identifiants en anglais, commentaires en français

- **Vérification** : revue
- **Pourquoi** : le code doit ressembler à ce qui se lit chez les donneurs
  d'ordre ; le support de formation reste lisible par son auteur.

### R-62 — Les commentaires expliquent le *pourquoi*

- **Vérification** : revue
- **Énoncé** : un commentaire qui paraphrase le code est du bruit. Un
  commentaire qui cite l'objectif DO-178C, l'accident ou l'arbitrage est une
  donnée de vie.

### R-63 — Pas de caractère hors Latin-1 dans un littéral de chaîne

- **Vérification** : compilateur et `gnatprove`
- **Pourquoi** : `String` est un tableau de `Character`. Le tiret cadratin
  passe en commentaire, pas dans une chaîne affichée.

---

## 8. Bilan des mécanismes

| Mécanisme | Nombre de règles |
|---|---|
| compilateur | 11 |
| preuve | 7 |
| outil | 2 |
| **revue seule** | **8** |

Huit règles en revue seule, sur vingt-huit. C'est le chiffre à faire baisser,
et c'est aussi celui qu'un auditeur regardera : il dit combien du standard
repose sur la discipline plutôt que sur la mécanique.

Sur un projet réel avec GNAT Pro, **GNATcheck** transformerait plusieurs de ces
règles en vérifications automatiques — R-43 (récursion), R-42 (dépendances
interdites), R-11 (types nus) ont toutes une règle LKQL correspondante. Ce
dépôt ne peut pas s'en servir : GNATcheck n'est pas distribué librement.
C'est une limite assumée, pas un oubli.

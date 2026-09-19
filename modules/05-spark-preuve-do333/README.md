# Module 05 — SPARK : preuve et DO-333

> **Durée estimée** : 2 journées
> **Prérequis** : modules 00 à 04

---

C'est le module qui justifie d'apprendre Ada plutôt qu'autre chose. Tout le
reste — types, contrats, analyse de flot — se retrouve, sous une forme ou une
autre, ailleurs. **La preuve créditée en remplacement d'objectifs de test, non.**

---

## Objectifs pédagogiques

1. Comprendre ce que fait `gnatprove` : obligations de vérification, Why3,
   prouveurs SMT.
2. Distinguer **AoRTE** (absence d'erreur à l'exécution) et **propriétés
   fonctionnelles**, et savoir que la première est le vrai palier industriel.
3. Écrire un `Loop_Invariant` et un `Loop_Variant`, et savoir lequel démontre
   quoi.
4. Savoir ce que la **DO-333** permet de créditer, et surtout ce qu'elle ne
   permet **pas**.
5. Savoir répondre à « et si le prouveur se trompe ? ».

---

## 1. Le cours

### 1.1 Ce que fait `gnatprove`

Trois étapes, visibles dans sa sortie :

```
Phase 1 of 3: generation of data representation information ...
Phase 2 of 3: generation of Global contracts ...
Phase 3 of 3: flow analysis and proof ...
Success: all checks proved (28 checks).
```

En phase 3, chaque vérification que le compilateur aurait insérée (§module 02)
et chaque contrat deviennent une **obligation de vérification** — une formule
logique dont la validité implique la correction. Ces formules partent vers
**Why3**, qui les traduit pour des prouveurs SMT — ici **CVC5**. Si tous les
prouveurs échouent sur une formule, la vérification reste *non prouvée*.

Ce n'est pas de l'analyse statique au sens de `clang-tidy` : il n'y a ni
heuristique, ni faux positifs de style. Une obligation est déchargée ou elle
ne l'est pas.

### 1.2 Deux paliers, très différents en coût

| Palier | Ce qu'on démontre | Effort typique |
|---|---|---|
| **AoRTE** | aucun `Constraint_Error`, aucune division par zéro, aucun accès hors bornes | faible à modéré |
| **Propriétés fonctionnelles** | le sous-programme fait ce que dit sa postcondition | élevé, très variable |

En industrie, **AoRTE est le palier qui se vend**. Il suffit à justifier
`pragma Suppress` (module 02), il élimine toute une classe d'anomalies, et il
s'obtient souvent sans écrire un seul contrat fonctionnel — les types
contraints du module 01 font déjà l'essentiel du travail.

Les propriétés fonctionnelles se réservent aux composants où elles paient :
un vote de capteurs, une machine à états de mode, une conversion d'unités.
C'est-à-dire là où une erreur ne se verrait pas au test.

### 1.3 La spécification est le vrai travail

Voici le contrat du vote médian de ce module :

```ada
function Mid_Value (A, B, C : Litres) return Litres
with
  Post =>
    (Mid_Value'Result = A or else Mid_Value'Result = B
     or else Mid_Value'Result = C)
    and then Count_At_Most  (A, B, C, Mid_Value'Result) >= 2
    and then Count_At_Least (A, B, C, Mid_Value'Result) >= 2;
```

Trois lignes qui **définissent** la médiane : le résultat est l'une des trois
entrées, au moins deux entrées lui sont inférieures ou égales, au moins deux
lui sont supérieures ou égales. Un capteur bloqué haut ou bas ne peut pas
être retenu.

Remarquez ce que la postcondition **ne fait pas** : elle ne décrit pas le
corps. Écrire `Post => Mid_Value'Result = (if A <= B and then B <= C then B
else ...)` serait une paraphrase du code, prouvée trivialement, et sans
valeur. Une postcondition utile est écrite **avant** le corps, à partir de
l'exigence.

> C'est aussi ce qui rend l'exercice difficile et intéressant : formaliser
> « la médiane » demande de savoir ce qu'est une médiane. Beaucoup d'exigences
> de bas niveau ne résistent pas à cet examen — et c'est un bénéfice, pas un
> obstacle.

### 1.4 Invariants et variants de boucle

Une boucle est le point où le prouveur perd la mémoire : il ne sait rien d'un
tour à l'autre, sauf ce qu'on lui dit.

```ada
for I in Values'Range loop
   if Values (I) < Low_Level_Threshold then
      Index := I; Found := True; return;
   end if;

   pragma Loop_Invariant
     (for all K in Values'First .. I => Values (K) >= Low_Level_Threshold);
end loop;
```

L'invariant dit : *tout ce qui a déjà été examiné est au-dessus du seuil*.
C'est lui qui permet de démontrer la postcondition du cas « rien trouvé »,
laquelle porte sur **tous** les éléments. Un test ne vérifierait ce « pour
tout » que sur les tableaux qu'on a écrits ; ici il est démontré.

Le **variant** est une autre affaire :

```ada
while Remaining > 0 loop
   pragma Loop_Invariant (Remaining <= Target);
   pragma Loop_Invariant (Count <= Target - Remaining);
   pragma Loop_Variant (Decreases => Remaining);
   ...
```

L'invariant borne le résultat ; le variant démontre la **terminaison**, qui
est une propriété distincte qu'aucun invariant n'implique. Sur un `for` borné,
la terminaison est acquise ; sur un `while`, elle ne l'est pas. En DAL A/B,
une boucle dont la terminaison n'est pas démontrée est un défaut.

### 1.5 Ce que la DO-333 permet de créditer

La **DO-333** (*Formal Methods Supplement to DO-178C*) ne remplace pas la
DO-178C : elle explique comment une méthode formelle peut satisfaire certains
de ses objectifs à la place d'une revue ou d'un test.

| Objectif DO-178C | Crédit possible par la preuve | Commentaire |
|---|---|---|
| A-5.1 — code conforme aux LLR | **oui** | postconditions prouvées |
| A-5.4 — code conforme au standard | non | c'est de l'analyse statique |
| A-5.6 — code *accurate and consistent* | **oui, largement** | AoRTE couvre la classe entière |
| A-6.2 / A-6.4 — tests de robustesse | **partiellement** | la preuve traite tout le domaine |
| A-7.4 — couverture des LLR | **oui, sous conditions** | FM.6.7.1 : il faut vérifier la *complétude* des propriétés |
| A-7.8 — couplage données/contrôle | **oui** | par l'analyse de flot (module 04) |

Trois exigences que la DO-333 pose en échange, et qu'il faut savoir citer :

1. **Le périmètre est déclaré.** Ce qui est prouvé, ce qui ne l'est pas, et
   pourquoi. Une unité en `SPARK_Mode => Off` doit être justifiée.
2. **Les hypothèses sont explicites.** La preuve suppose un compilateur
   correct, un environnement d'exécution correct, et des contrats d'interface
   tenus par le code non prouvé.
3. **La méthode formelle est elle-même vérifiée** (FM.6.7). Une preuve
   obtenue avec un prouveur non maîtrisé n'est pas un argument.

### 1.6 Ce que la preuve ne remplace **jamais**

C'est la question de piège en entretien, et la bonne réponse est nette :

> **Les tests sur l'exécutable intégré restent obligatoires.**

La DO-333 est explicite : la preuve porte sur le **code source** et sur un
modèle sémantique de ce code. Elle ne dit rien de :

- la **chaîne de compilation** — le code objet est-il fidèle au source ?
- l'**intégration matérielle** — la cible, ses temps d'accès, ses interruptions ;
- l'**adéquation aux exigences de haut niveau** — une postcondition peut être
  parfaitement prouvée et parfaitement fausse vis-à-vis du besoin ;
- les **propriétés qu'on n'a pas écrites**. Une preuve ne dit rien de ce
  qu'on ne lui a pas demandé.

D'où la campagne de test de ce module, qui pourrait sembler redondante après
28 obligations déchargées. Elle ne l'est pas : elle exerce le **binaire**,
pas le modèle. C'est le seul endroit du dépôt où l'on vérifie que ce qui a été
prouvé est aussi ce qui s'exécute.

### 1.7 Ce que la preuve n'a pas vu, mesuré sur ce module

Ce n'est pas un raisonnement : c'est un chiffre obtenu sur ce code-ci.

`gnatprove` déchargeait **28 obligations sur 28** — la médiane est démontrée
pour toutes les entrées possibles. La première campagne de test, écrite avec
huit cas nominaux et de robustesse, donnait pourtant :

```
100% statement coverage (20 out of 20)
100% decision coverage (5 out of 5)
 55% MC/DC coverage (6 out of 11)
```

Cinq effets de condition indépendants sur onze n'étaient **jamais exercés**,
sur du code intégralement prouvé. La raison est dans le corps :

```ada
if (A <= B and then B <= C) or else (C <= B and then B <= A) then
```

Quatre conditions par décision, deux décisions. Il a fallu ajouter les **six
permutations** de trois valeurs distinctes pour atteindre 11/11.

La leçon est celle que la DO-178C encode dans ses tableaux : la preuve
répond à « le code fait-il ce qui est spécifié ? », la couverture
structurelle répond à « le code contient-il autre chose que ce que les tests
ont exercé ? ». Ce sont deux questions différentes, et la seconde reste
posée même quand la première a une réponse parfaite. C'est aussi pourquoi la
DO-333 ne permet pas de créditer la couverture structurelle (A-7.5 à A-7.7)
sans démontrer par ailleurs la **complétude** des propriétés (FM.6.7.1).

### 1.8 « Et si le prouveur se trompe ? »

Réponse honnête et structurée :

- **Le prouveur ne se trompe pas dans le sens dangereux.** Un prouveur SMT
  qui échoue rend « non prouvé » ; un défaut se traduit donc en obligation
  non déchargée, pas en fausse garantie. Le risque résiduel est un bogue de
  *soundness* dans Why3 ou dans le générateur d'obligations.
- **On réduit ce risque en croisant les prouveurs.** `gnatprove` peut lancer
  CVC5, Z3 et Alt-Ergo ; deux prouveurs indépendants qui déchargent la même
  obligation constituent un argument plus fort qu'un seul.
- **Et surtout, on l'assume dans le plan.** C'est exactement l'objet de
  FM.6.7 et de la qualification d'outil (DO-330) : dire quel outil produit
  quel argument, et à quel niveau de confiance. Un outil de **vérification**
  qui échoue laisse passer un défaut ; un outil de **développement** qui
  échoue en introduit un. Les niveaux de qualification exigés diffèrent en
  conséquence.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod05-voting.ads`](src/mod05-voting.ads) | Trois spécifications formelles, dont la médiane |
| [`src/mod05-voting.adb`](src/mod05-voting.adb) | Invariant quantifié et variant de terminaison |
| [`src/main.adb`](src/main.adb) | Ce que la preuve garantit, sur trois exemples |
| [`tests/test_voting.adb`](tests/test_voting.adb) | Neuf cas — et la question de leur utilité |

Résultat : **28 obligations déchargées par CVC5**, zéro avertissement,
100 % MC/DC (11 obligations sur 11), après ajout des six permutations.

---

## 3. Exercices

1. Retirer le `pragma Loop_Invariant` de `Find_First_Low` et relancer la
   preuve. Quelle obligation tombe, et quel est le message exact ?
2. Retirer le `pragma Loop_Variant` de `Refuel_Steps`. Que dit `gnatprove`,
   et pourquoi n'est-ce **pas** la même erreur qu'à l'exercice 1 ?
3. Affaiblir la postcondition de `Mid_Value` en supprimant la condition
   `Count_At_Least ... >= 2`. La preuve passe-t-elle toujours ? Écrire un
   corps **faux** qui satisfait la postcondition affaiblie. Conclusion sur la
   valeur d'une spécification incomplète.
4. Passer `--level=0` puis `--level=4` et comparer les temps. Où est le point
   d'équilibre pour ce module ?
5. Rédiger, en une page, le paragraphe « périmètre et hypothèses de la preuve »
   qu'exigerait la DO-333 pour ce dépôt : quelles unités sont prouvées,
   lesquelles ne le sont pas, et pourquoi.

---

## 4. Pour l'entretien

> **« La preuve remplace les tests ? »**
> Elle remplace certains **objectifs** de vérification, selon la DO-333, et
> pas les tests sur l'exécutable intégré. Une postcondition prouvée vaut pour
> tout le domaine d'entrée, ce qu'aucune campagne ne peut faire. Mais elle
> porte sur le source, pas sur le binaire ni sur la cible — donc les tests
> d'intégration restent, et l'adéquation aux exigences de haut niveau aussi.

> **« Vous prouvez tout ? »**
> Non. On vise l'AoRTE partout, parce que c'est peu cher et que ça élimine
> une classe entière d'anomalies, et les propriétés fonctionnelles seulement
> là où une erreur ne se verrait pas au test : vote de capteurs, machines à
> états, conversions d'unités. Le périmètre est déclaré, c'est une exigence
> de la DO-333.

> **« Un invariant et un variant, quelle différence ? »**
> L'invariant dit ce qui reste vrai à chaque tour et sert à prouver la
> postcondition ; le variant dit ce qui décroît strictement et sert à prouver
> la terminaison. Sur un `while`, aucun invariant n'implique la terminaison —
> il faut le variant, et en DAL A/B son absence est un défaut.

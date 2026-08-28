# Module 08 — Orienté objet et DO-332

> **Durée estimée** : 1 journée
> **Prérequis** : modules 00 à 07

---

La **DO-332** (*Object-Oriented Technology and Related Techniques Supplement*)
ne dit pas « l'objet est interdit ». Elle dit : *si vous héritez, prouvez que
la substitution est valide ; si vous appelez de façon dispatchante, couvrez
chaque cible ; et n'allouez pas dynamiquement.*

Ada 2022 répond aux deux premiers points **dans le langage**. C'est le seul
module du dépôt où l'écart avec C++ et C# est plus grand que celui avec le
processus.

---

## Objectifs pédagogiques

1. Écrire un type étiqueté, une extension, et un appel dispatchant.
2. Utiliser `Pre'Class` et `Post'Class`, et savoir dans quel sens chacun se
   renforce ou s'affaiblit.
3. Comprendre que la **substitution de Liskov devient une obligation de
   preuve**, pas un conseil de conception.
4. Connaître les trois exigences propres à la DO-332 : cohérence locale de
   type, couverture des appels dispatchants, gestion mémoire.
5. Savoir **justifier** une vérification non prouvée, et voir la
   justification apparaître dans la donnée de vie.

---

## 1. Le cours

### 1.1 Le vocabulaire, en trois lignes

| Ada | C# | C++ |
|---|---|---|
| `type T is tagged record …` | `class T` | `class T { virtual … };` |
| `type U is new T with record …` | `class U : T` | `class U : public T` |
| `T'Class` | `T` (référence) | `T&` / `T*` |
| `overriding function F …` | `override` | `override` |

Deux différences qui comptent :

- **`overriding` est obligatoire** si l'on veut le vérifier — et ce dépôt le
  veut. Une redéfinition qui ne redéfinit rien est une erreur de compilation,
  pas un bogue silencieux.
- **Le dispatching est explicite au niveau du type** : `Instrument` est un
  type ordinaire (appel statique), `Instrument'Class` est le type
  « n'importe quelle extension » (appel dispatchant). En C#, tout est
  potentiellement dispatchant sans que la signature le dise.

### 1.2 `Post'Class` : Liskov devient une obligation de preuve

C'est le cœur du module.

```ada
function To_Litres (Self : Instrument; Raw : Raw_Count) return Litres
is abstract
with Post'Class => To_Litres'Result <= Full_Scale;
```

Toute redéfinition doit satisfaire cette postcondition. Elle peut la
**renforcer** — dire *plus* — jamais l'affaiblir :

```ada
overriding function To_Litres
  (Self : Ultrasonic; Raw : Raw_Count) return Litres
is (Self.Dead_Zone + Raw * 9)
with
  Post =>
    To_Litres'Result <= Full_Scale
    and then To_Litres'Result >= Self.Dead_Zone;
```

`Pre'Class` fonctionne **à l'envers** : une dérivée peut **affaiblir** la
précondition, jamais la renforcer. Un appelant qui respecte le contrat de la
racine doit être accepté par toutes les dérivées — sinon la substitution est
fausse.

| | Racine | Dérivée autorisée à |
|---|---|---|
| `Pre'Class` | ce que l'appelant doit garantir | **affaiblir** (accepter plus) |
| `Post'Class` | ce que l'appelé rend | **renforcer** (promettre plus) |

Ce n'est pas une convention de bonne conduite : `gnatprove` refuse le contraire.

> **Piège vérifié.** Écrire seulement `Post => Result >= Self.Dead_Zone` sur
> la redéfinition produit `postcondition might be weaker than class-wide
> postcondition` : la postcondition spécifique doit **impliquer** celle de
> classe, donc la répéter ou la contenir. La conjonction explicite est la
> forme correcte, et elle se lit mieux.

**Ce que cela vaut en certification.** La DO-332 §OO.6.7 exige la vérification
de la *cohérence locale de type* (*Local Type Consistency*) — c'est-à-dire
exactement Liskov. Deux façons de la satisfaire :

1. **Par le test** : rejouer, pour chaque extension, la campagne de la racine.
   Coût multiplié par le nombre d'extensions.
2. **Par la preuve** : `Pre'Class` / `Post'Class` déchargés par `gnatprove`.
   Coût : écrire les contrats une fois.

La seconde n'est possible qu'avec un langage qui porte les contrats de
classe. C'est un argument de vente d'Ada qu'un ingénieur de certification
reconnaît immédiatement.

### 1.3 Couverture des appels dispatchants

La DO-332 §OO.6.4.4.2 demande que **chaque site d'appel dispatchant soit
exercé pour chaque cible possible**. Ce n'est pas la couverture MC/DC : c'est
une exigence de couverture supplémentaire, propre à l'objet.

Ce module a un site — `Reading` — et deux cibles. D'où deux cas de test
nommés explicitement :

```
Instruments.dispatch_to_capacitive  [LLR-M08-003]
Instruments.dispatch_to_ultrasonic  [LLR-M08-003]
```

Leur absence serait un **défaut de couverture**, pas un manque de zèle. Et
l'on voit tout de suite le coût réel de l'héritage en avionique : chaque
nouvelle extension multiplie les obligations de couverture sur **tous** les
sites d'appel dispatchants du programme. C'est la vraie raison pour laquelle
les projets DAL A limitent la profondeur d'héritage — pas une méfiance de
principe.

### 1.4 Mémoire : le point où l'objet coince

Une collection hétérogène — un tableau de sondes de types différents —
demande en général de l'allocation dynamique, que le module 07 interdit.
Trois réponses, toutes utilisées :

1. **Passer par paramètre** `Instrument'Class`, comme ici : le dispatching
   fonctionne, rien n'est alloué. Suffisant quand la structure du système est
   figée à la compilation, ce qui est le cas usuel en avionique.
2. **Enregistrement à discriminant** (*variant record*) : un seul type qui
   contient toutes les variantes, taille maximale connue.
3. **Réservoir statique d'objets** pré-alloués à l'élaboration.

Ce dépôt fait le 1. C'est le plus simple, et c'est celui qui reste vrai sous
`No_Allocators`.

### 1.5 Ce que la mesure a trouvé, et que la preuve n'avait pas vu

`Is_Plausible` de `Ultrasonic` s'écrivait d'abord ainsi :

```ada
is (Value >= Self.Dead_Zone and then Value <= Full_Scale)
```

Onze obligations déchargées, zéro avertissement — et **MC/DC à 1 sur 2**.

La seconde condition ne peut jamais valoir `False` : la `Pre'Class` héritée
exige déjà `Value <= Full_Scale`. C'était donc du **code inatteignable**, créé
par une garde redondante avec le contrat.

Deux réactions possibles, et une seule est bonne :

- écrire un cas de test avec `Value = 11_000` — impossible, il violerait la
  précondition, et de toute façon on ne teste pas pour faire monter un
  chiffre ;
- **retirer la condition**, ce qui est fait.

C'est très exactement ce que la DO-178C §6.4.4.3 attend de l'analyse de
couverture structurelle : elle ne sert pas à valider le code, elle sert à
**trouver ce que les exigences ne justifient pas**. Ici, une garde que le
contrat rendait inutile.

### 1.6 Justifier une vérification non prouvée

`gnatprove` refuse de démontrer qu'un appel **dispatchant** termine : il
faudrait raisonner sur toutes les redéfinitions présentes et futures, y
compris celles d'une extension écrite ailleurs.

```
medium: implicit aspect Always_Terminates on "Reading" could be incorrect,
        dispatching call to "To_Litres" might be nonterminating
```

Avec `--checks-as-errors=on`, cela fait échouer la vérification. La réponse
n'est pas de baisser le seuil, c'est de **justifier** :

```ada
pragma Annotate
  (GNATprove, False_Positive,
   "implicit aspect Always_Terminates",
   "les deux redefinitions de To_Litres sont des expression functions "
   & "sans boucle ni recursion, donc terminantes par construction ; …");
```

Et voici ce que produit le rapport :

```
Justified check messages:
  mod08-instruments.adb:7:7: justified that implicit aspect
  Always_Terminates on "Reading" could be incorrect …
  (marked as: false positive, reason: "les deux redefinitions …")
```

L'annotation **n'efface pas** la vérification : elle la déplace dans une
colonne « Justified » du rapport, avec sa raison. En DO-178C, c'est
exactement ce qu'on attend d'une déviation — écrite, argumentée, et visible
dans la donnée de vie plutôt que dans la mémoire d'un relecteur.

> À utiliser avec parcimonie et à relire en revue : une justification est un
> report de charge de preuve sur l'humain, pas une disparition de la charge.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod08-instruments.ads`](src/mod08-instruments.ads) | Racine abstraite, `Pre'Class`, `Post'Class`, deux extensions |
| [`src/mod08-instruments.adb`](src/mod08-instruments.adb) | L'appel dispatchant et sa justification |
| [`src/main.adb`](src/main.adb) | Un site d'appel, deux cibles |
| [`tests/test_instruments.adb`](tests/test_instruments.adb) | Six cas, dont les deux cibles de dispatch |

Résultat : **11 obligations déchargées, 1 justifiée**, zéro avertissement,
100 % de couverture après retrait de la garde inatteignable du §1.5.

---

## 3. Exercices

1. Ajouter une extension `Radar` dont `To_Litres` peut rendre 11 000 L.
   Que dit `gnatprove`, et sur quelle ligne ? Rapprocher le message de la
   notion de cohérence locale de type.
2. Renforcer la `Pre'Class` d'une dérivée (exiger `Value <= 5_000`). Que se
   passe-t-il, et pourquoi est-ce le contraire du cas précédent ?
3. Supprimer le cas `dispatch_to_ultrasonic`. La couverture MC/DC bouge-t-elle ?
   Qu'est-ce que cela dit de la nature de l'exigence OO.6.4.4.2 ?
4. Retirer le `pragma Annotate` et relancer `verify.sh prove`. Puis le
   remettre en `Intentional` au lieu de `False_Positive` : quelle différence
   dans le rapport, et laquelle des deux est honnête ici ?
5. Écrire la collection hétérogène de la §1.4 avec un enregistrement à
   discriminant, et comparer le nombre de cibles de dispatch à couvrir.

---

## 4. Pour l'entretien

> **« L'objet est-il autorisé en DO-178C ? »**
> Oui, encadré par la DO-332. Trois exigences propres : la cohérence locale
> de type — c'est-à-dire Liskov — la couverture de chaque site d'appel
> dispatchant pour chaque cible, et pas d'allocation dynamique. En Ada 2022,
> la première se démontre avec `Pre'Class` et `Post'Class` au lieu de se
> re-tester extension par extension.

> **« Pourquoi limiter l'héritage sur un projet DAL A ? »**
> Pas par méfiance : par coût de couverture. Chaque extension multiplie les
> obligations sur tous les sites d'appel dispatchants du programme. Deux
> extensions et un site, c'est deux cas ; dix extensions et quarante sites,
> c'est quatre cents.

> **« Que faites-vous d'une vérification que le prouveur ne décharge pas ? »**
> Je la justifie explicitement, avec `pragma Annotate`, en écrivant la raison
> dans le code. Elle apparaît alors dans la colonne « Justified » du rapport
> `gnatprove`, avec son argument, et elle se relit en revue. Ce qu'il ne faut
> pas faire, c'est baisser le seuil de vérification pour la faire disparaître.

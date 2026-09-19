# Module 02 — Vérifications à l'exécution

> **Durée estimée** : 1 journée
> **Prérequis** : modules 00 et 01

---

Ce module traite d'un sujet que le dépôt frère en C++ **ne pouvait pas
traiter** : le compilateur Ada ajoute du code que personne n'a écrit, ce code
coûte du temps et de la place, on a le droit de l'enlever — et l'enlever a un
prix en certification.

---

## Objectifs pédagogiques

1. Savoir quelles vérifications GNAT insère, et à quel endroit.
2. **Voir** ce code ajouté, et comprendre pourquoi la DO-178C l'appelle du
   *code objet sans équivalent source*.
3. Mesurer ce qu'il coûte, en octets, plutôt que d'en discuter.
4. Savoir les supprimer — `pragma Suppress`, `-gnatp` — et savoir ce que la
   suppression oblige à démontrer en échange.
5. Comprendre l'objectif **A-7.9** (couverture du code objet, DAL A) et
   pourquoi il n'existe qu'à ce niveau.

---

## 1. Le cours

### 1.1 Ce que le compilateur ajoute

Ada exige que toute violation de contrainte soit **détectée**. Le compilateur
insère donc, là où il ne peut pas prouver le contraire :

| Vérification | Déclenchée par | Exception |
|---|---|---|
| **Range check** | affectation, conversion, passage de paramètre | `Constraint_Error` |
| **Index check** | accès à un tableau | `Constraint_Error` |
| **Overflow check** | arithmétique sur les entiers | `Constraint_Error` |
| **Division check** | `/`, `mod`, `rem` | `Constraint_Error` |
| **Length check** | affectation de tableau, agrégat | `Constraint_Error` |
| **Discriminant check** | accès à un composant variant | `Constraint_Error` |
| **Access check** | déréférencement | `Constraint_Error` |
| **Tag check** | conversion descendante | `Constraint_Error` |

En C#, l'équivalent existe pour les tableaux (`IndexOutOfRangeException`) et
rien de plus : l'arithmétique déborde silencieusement à moins d'un bloc
`checked`. En C++, il n'y a rien du tout, et le débordement signé est un
comportement indéfini.

### 1.2 Le voir

`-gnatG` demande à GNAT d'imprimer le source **après expansion**. Voici ce
que devient la boucle de `Total`, qui tient en une ligne dans le source :

```
L_1 : for i in 1 .. 4 loop
   R1b : constant integer := sum + tanks (i);
   [constraint_error when
     not (R1b in 0 .. 40000)
     "range check failed"]
   sum := R1b;
```

Et voici `Read_Tank`, qui vaut la peine d'être regardé deux fois :

```
begin
   if index in 1 .. 4 then
      [constraint_error when
        not (integer(index) in 1 .. 4)
        "index check failed"]
      value := tanks (index);
```

Le compilateur teste `index in 1 .. 4`, puis insère un contrôle qui vérifie…
que `index` est dans `1 .. 4`. Ce contrôle **ne peut pas se déclencher**.
Il est là parce que la phase d'expansion ne raisonne pas sur le `if`
englobant.

Ce n'est pas une bêtise du compilateur : c'est le prix d'une insertion
systématique. Et c'est exactement ce qui rend le sujet intéressant — le code
mort dont on parle ici a été mis là par l'outil, pas par le développeur.

Pour le reproduire :

```bash
./scripts/checks-cost.sh
```

### 1.3 Le mesurer

Le même paquetage, compilé deux fois, sur `x86_64` avec GNAT 16.1.0 en `-O0` :

| Construction | `.text` |
|---|---|
| Avec vérifications | **1005 octets** |
| Sans (`-gnatp`) | **889 octets** |
| Surcoût | **116 octets, soit 13 %** |

Treize pour cent sur un paquetage de quarante lignes. Sur une cible où la
mémoire programme se compte en dizaines de kilo-octets et où le budget de
temps est figé par la boucle de commande, ce n'est pas un détail — mais ce
n'est pas non plus l'argument massue qu'on entend parfois. **Mesurer d'abord.**

### 1.4 Le comportement, avec et sans

Le même programme, sans changer une ligne de source :

```
== Débordement : avec contrôles, ou sans ==
Constraint_Error levée : les contrôles sont ACTIFS.
```

```
== Débordement : avec contrôles, ou sans ==
Aucune exception. Integer'Last + 1 =-2147483648
Les contrôles sont SUPPRIMÉS : le résultat est faux et le
programme continue comme si de rien n'était.
```

Voilà l'échange, en clair. Avec les contrôles, un défaut devient une
exception : bruyante, localisée, et — en DAL A/B — **inacceptable telle
quelle**, parce qu'une exception non traitée dans un calculateur de vol n'est
pas un comportement spécifié (module 06). Sans les contrôles, le défaut
devient une valeur fausse qui se propage sans bruit jusqu'à l'affichage
pilote.

Aucune des deux options n'est bonne. La bonne option est la troisième :
**démontrer que le défaut ne peut pas se produire**, et alors seulement
enlever le contrôle.

### 1.5 Les supprimer, et ce que ça oblige

Trois façons, de la plus fine à la plus brutale :

```ada
pragma Suppress (Index_Check, On => Tanks);   --  une entité
pragma Suppress (Overflow_Check);             --  une unité
--  et -gnatp en ligne de commande             --  tout le programme
```

La norme est explicite : supprimer une vérification alors qu'elle *aurait*
échoué rend l'exécution **erronée** (*erroneous execution*, RM 11.5). Le
programme n'a plus de sémantique définie. Ce n'est pas « ça déborde », c'est
« tout est permis », exactement comme un comportement indéfini en C++.

Donc, en DO-178C :

- si les contrôles sont **actifs**, il faut traiter les exceptions — ou
  démontrer qu'elles ne surviennent pas ;
- si les contrôles sont **supprimés**, il faut démontrer qu'ils n'auraient pas
  échoué.

Dans les deux cas, **il faut démontrer**. La différence est que la seconde
option ne laisse aucun filet. C'est la raison d'être de SPARK, et le sujet des
modules 04 et 05 : `gnatprove` démontre l'absence d'erreur à l'exécution
(AoRTE), ce qui transforme `pragma Suppress` d'un pari en une optimisation
justifiée.

### 1.6 La couverture du code objet — objectif A-7.9

Le tableau A-7 de la DO-178C demande, **au DAL A seulement** (objectif 9),
que la couverture soit démontrée sur le **code objet** lorsque le compilateur
génère du code sans équivalent dans le source.

C'est précisément notre cas. Les `[constraint_error when …]` ci-dessus
n'existent nulle part dans les fichiers `.adb`. Une couverture MC/DC mesurée
au niveau du source peut donc être à 100 % alors que des branches du code
objet n'ont jamais été exercées.

Trois réponses possibles, toutes utilisées en projet réel :

1. **Supprimer les vérifications** et prouver qu'elles étaient inutiles. Le
   code objet redevient équivalent au source ; l'objectif A-7.9 tombe.
2. **Mesurer sur le code objet.** GNATcoverage sait analyser des traces
   d'exécution binaire, pas seulement instrumenter le source.
3. **Analyser** unité par unité et justifier chaque écart. Coûteux, mais
   c'est ce que font les projets qui ne peuvent pas supprimer les contrôles.

Ce dépôt ne fait ni 2 ni 3 : il **cite** l'objectif et montre l'artefact qui
le déclenche. Le traiter demanderait une cible réelle.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod02-fuel_gauge.ads`](src/mod02-fuel_gauge.ads) | Trois sous-programmes, chacun choisi pour la vérification qu'il provoque |
| [`src/mod02-fuel_gauge.adb`](src/mod02-fuel_gauge.adb) | Les corps, dont la boucle à invariant |
| [`src/main.adb`](src/main.adb) | Le même exécutable, deux comportements |
| [`tests/test_fuel_gauge.adb`](tests/test_fuel_gauge.adb) | Sept cas, dont deux de robustesse |
| [`../../scripts/checks-cost.sh`](../../scripts/checks-cost.sh) | La mesure, rejouable |

Un détail du corps mérite attention :

```ada
for I in Tank_Index loop
   Sum := Sum + Tanks (I);
   pragma Loop_Invariant (Sum <= I * Litres'Last);
end loop;
```

Sans cet invariant, `gnatprove` ne sait rien de `Sum` d'un tour de boucle à
l'autre, et la vérification de débordement reste **non prouvée** — donc non
supprimable. Trois mots de contrat achètent le droit d'enlever du code objet.
C'est le cœur du marché que propose SPARK.

---

## 3. Exercices

1. Retirer le `pragma Loop_Invariant` et relancer `./scripts/verify.sh prove`.
   Lire le message : que dit exactement `gnatprove`, et sur quelle ligne ?
2. Ajouter `pragma Suppress (Overflow_Check);` dans le corps de `Total`, puis
   relancer la preuve. `gnatprove` change-t-il d'avis ? Pourquoi ?
3. Mesurer le surcoût sur `-O2` au lieu de `-O0`. L'écart de 13 % tient-il ?
4. Écrire un sous-programme dont la vérification de plage **ne peut pas** être
   prouvée, et observer ce que `--checks-as-errors=on` en fait dans la CI.

---

## 4. Pour l'entretien

> **« Les vérifications Ada, on les garde ou on les enlève ? »**
> On les enlève quand on a prouvé qu'elles ne peuvent pas se déclencher, et
> pas avant. Les supprimer sans preuve rend l'exécution *erroneous* au sens
> de la norme — on retombe exactement sur le comportement indéfini du C. Avec
> SPARK, la preuve d'absence d'erreur à l'exécution rend la suppression
> défendable devant l'autorité.

> **« Qu'est-ce que le code objet sans équivalent source ? »**
> Du code généré par le compilateur qui ne correspond à aucune instruction
> écrite : contrôles de plage, contrôles d'indice, initialisations
> implicites. Il déclenche l'objectif A-7.9 au DAL A, parce qu'une couverture
> mesurée sur le source ne dit rien de ces branches-là. `-gnatG` permet de le
> voir sans deviner.

> **« Vous avez un chiffre ? »**
> 13 % de `.text` en plus sur le paquetage de ce module, GNAT 16.1 en `-O0`,
> mesuré par `scripts/checks-cost.sh`. Le chiffre compte moins que la méthode :
> il se rejoue d'une commande.

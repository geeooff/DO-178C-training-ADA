# Module 01 — Types et contraintes

> **Durée estimée** : 1 journée
> **Prérequis** : module 00

---

## Objectifs pédagogiques

1. Cesser de choisir un type entier, et commencer à déclarer des **bornes**.
2. Distinguer **sous-type** et **type distinct**, et savoir lequel empêche quel
   accident.
3. Savoir quand le débordement est **défini** (types modulaires) et quand il
   lève `Constraint_Error`.
4. Utiliser la **virgule fixe** plutôt que le flottant, et savoir dire
   pourquoi devant un ingénieur de certification.
5. Traiter une énumération comme un type, pas comme un entier déguisé.
6. Rattacher tout cela à l'objectif **A-5.6** de la DO-178C — *accuracy and
   consistency*.

---

## 1. Le cours

### 1.1 La bonne question n'est pas « quel type ? » mais « quelles bornes ? »

En C#, on écrit `int` et on ajoute des gardes :

```csharp
public void SetFuel(int litres)
{
    if (litres < 0 || litres > 10_000)
        throw new ArgumentOutOfRangeException(nameof(litres));
    _litres = litres;
}
```

La contrainte est vraie **dans cette méthode**. Elle est à réécrire dans la
suivante, et l'oubli ne se voit pas — ni à la compilation, ni à la relecture,
ni au test tant que personne ne pense au cas.

En Ada, la contrainte est **dans le type** :

```ada
subtype Litres is Natural range 0 .. 10_000;
```

À partir de là, toute affectation, tout passage de paramètre, toute conversion
vers `Litres` est vérifiée. Pas parce que le programmeur y a pensé : parce que
c'est le langage.

C'est un **déplacement de la charge de preuve**. En C#, il faut démontrer que
chaque point d'entrée valide. En Ada, il faut démontrer qu'aucune vérification
ne peut échouer — et le module 05 montre qu'un outil sait le faire à votre
place.

> **Écart C# à retenir** : `int` en C# est un choix de représentation.
> `Litres` en Ada est un choix de **domaine**. Ce n'est pas la même
> conversation.

### 1.2 Sous-type ou type distinct : la distinction que C# n'a pas

C# a `int`, et éventuellement un `struct` enveloppant. Ada a **deux**
mécanismes, et les confondre est l'erreur de débutant la plus coûteuse.

| | Déclaration | Compatible avec le type de base ? | À quoi ça sert |
|---|---|---|---|
| **Sous-type** | `subtype Celsius is Integer range -60 .. 90;` | **Oui**, sans conversion | Restreindre un domaine |
| **Type distinct** | `type Litres is delta 0.25 range 0.0 .. 1_024.0;` | **Non** | Empêcher un mélange |

Un `Celsius` **est** un `Integer`. Il s'additionne avec un `Integer` sans
cérémonie ; seule la plage est vérifiée à l'affectation.

> **Vocabulaire.** Ada réserve le mot *dérivé* à la forme
> `type Kilograms is new Litres;` (RM 3.4), qui crée un type distinct à partir
> d'un autre. Une déclaration `type Litres is delta …` crée un type *nouveau*
> de toutes pièces. Les deux formes donnent un type **distinct** — c'est cette
> propriété qui compte ici, et c'est le mot employé dans la suite.

Un `Litres` **n'est pas** un `Kilograms`, même s'ils ont exactement la même
représentation en mémoire. `Volume + Masse` ne compile pas. Pour passer de
l'un à l'autre il faut écrire la conversion, donc nommer le facteur, donc le
relire en revue.

> **L'accident** : Mars Climate Orbiter, 23 septembre 1999. Le logiciel sol
> produisait des impulsions en **livres-force-seconde**, le logiciel de bord
> les lisait en **newtons-seconde**. Facteur 4,45. La sonde est entrée trop
> bas dans l'atmosphère martienne et a été détruite. 327,6 M$.
>
> Les deux logiciels étaient corrects. C'est l'**interface** qui ne l'était
> pas — et aucun des deux compilateurs n'avait de quoi s'en apercevoir, parce
> que les deux grandeurs étaient des `double`. Avec deux types
> distincts, l'affectation ne compile pas.

### 1.3 Types modulaires : le débordement défini

Trois langages, trois comportements pour « 4095 + 1 sur 12 bits » :

| Langage | Écriture | Que se passe-t-il |
|---|---|---|
| C# | `unchecked((short)(x + 1))` | boucle, **si** on pense à `unchecked` |
| C++ | `int` qui déborde | **comportement indéfini** — le compilateur a tous les droits |
| Ada | `type Raw_Count is mod 2**12;` | boucle, **par définition du type** |

Le point important n'est pas que ça boucle. C'est que **le type le dit**. Un
lecteur qui voit `mod 2**12` sait, sans commentaire, que le bouclage est voulu
et que la largeur est de 12 bits. Un lecteur qui voit `int` ne sait rien.

Et sur un entier **non** modulaire, Ada ne déborde pas silencieusement : il
lève `Constraint_Error`. Là où le C++ offre un comportement indéfini — donc un
programme qui peut faire n'importe quoi, y compris continuer — Ada offre un
arrêt net et localisé. Le module 06 explique pourquoi cet arrêt net est
lui-même un problème en DAL A, et ce qu'on met à la place.

### 1.4 Virgule fixe : ce que l'embarqué utilise vraiment

```ada
type Litres is delta 0.25 range 0.0 .. 1_024.0;
```

Un type à virgule fixe est **un entier mis à l'échelle**. `Litres` est stocké
comme un entier ; le `0.25` dit seulement combien vaut une unité. Il n'y a ni
exposant, ni valeur dénormalisée, ni `NaN`, ni arrondi dépendant du mode de la
FPU.

Pourquoi cela compte en certification :

- **Déterminisme.** Le même calcul donne le même bit sur deux exécutions et
  sur deux cibles. Avec du flottant, le résultat peut dépendre de l'ordre des
  opérations et de la largeur des registres intermédiaires.
- **Précision démontrable.** L'objectif A-5.6 demande de montrer que le code
  est *accurate and consistent*, ce qui inclut la propagation des erreurs
  d'arrondi. Sur un pas fixe de 0,25, l'erreur maximale vaut 0,25. Sur du
  flottant, la démonstration est un travail à part entière.
- **Coût.** Beaucoup de cibles avioniques n'ont pas d'unité flottante, ou
  l'interdisent parce que son comportement d'exception est difficile à
  maîtriser.

La DO-178C **n'interdit pas** le flottant. Elle demande de justifier la
précision. La virgule fixe rend cette justification triviale ; c'est tout
l'argument.

Attention au piège de `Small` : par défaut, GNAT prend pour pas de
représentation la puissance de deux immédiatement inférieure au `delta`
demandé. Avec `delta 0.001`, le pas réel vaut `2**-10 = 0,0009765625`, et la
constante `0.804` devient `0,8037109375`. Le module déclare donc
explicitement :

```ada
type Density_Kg_Per_L is delta 0.001 range 0.0 .. 2.0
  with Small => 0.001;
```

### 1.5 Énumérations : pas un entier déguisé

En C#, une énumération **est** un entier :

```csharp
var id = (SensorId)200;   // compile, et produit une valeur invalide
```

Ada n'a aucune conversion implicite entre entier et énumération. Pour
fabriquer une valeur à partir d'un entier, il faut écrire `Sensor_Id'Val (N)`,
qui lève `Constraint_Error` hors domaine. Le contrôle n'est plus une bonne
pratique : c'est le chemin par défaut.

Conséquence sur une trame reçue d'un bus, où l'octet peut valoir n'importe
quoi : le décodage ne peut pas « juste convertir ». Il doit décider, et
**dire** ce qu'il a décidé. D'où la signature du module :

```ada
procedure Decode_Sensor_Id
  (Octet : Natural; Id : out Sensor_Id; Valid : out Boolean);
```

Le drapeau `Valid` n'est pas de la politesse : sans lui, un identifiant faux
serait indiscernable d'un identifiant vrai, et la panne capteur deviendrait
une donnée valide. C'est exactement le genre de chemin que la DO-178C appelle
*abnormal input* et que le §6.4.2.2 demande de tester.

### 1.6 Les attributs : écrire une borne une fois, la relire partout

`Celsius'First`, `Raw_Count'Modulus`, `Litres'Delta`, `Sensor_Id'Pos` — les
attributs interrogent le type. Ils évitent la recopie, qui est la source
principale de divergence entre le code et sa spécification.

```ada
if Raw < Celsius'First then          --  et non : if Raw < -60 then
```

La seconde forme est juste aujourd'hui. Elle devient fausse le jour où
quelqu'un élargit la plage — et rien ne le signalera.

`'Image` mérite une mention : il produit la représentation textuelle de
n'importe quelle valeur, y compris d'une énumération, sans table de
correspondance à maintenir. Le `name_of()` que le dépôt frère en C++ doit
écrire à la main n'existe pas ici.

### 1.7 Ce que la DO-178C en retire

| Objectif | Ce que le module apporte |
|---|---|
| **A-5.6** — le code est *accurate and consistent* | Bornes dans le type, pas dans les commentaires ; pas d'arrondi flottant à justifier |
| **A-3.2 / A-4.2** — exigences *accurate and consistent* | Un type distinct rend une confusion d'unité impossible à écrire |
| **A-5.1** — le code est conforme aux exigences de bas niveau | Les aspects `Post` disent ce que les LLR demandent |
| **§6.4.2.2** — cas de robustesse | `Decode_Sensor_Id` et `Clamp_Temperature` ont chacun leur cas hors domaine |

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod01-sensors.ads`](src/mod01-sensors.ads) | Les cinq familles de types, et les contrats |
| [`src/mod01-sensors.adb`](src/mod01-sensors.adb) | Les corps, tous prouvés |
| [`src/main.adb`](src/main.adb) | Démonstration : ce que les types disent d'eux-mêmes |
| [`tests/test_sensors.adb`](tests/test_sensors.adb) | La campagne, nominale et robustesse |

Le paquetage est en `SPARK_Mode => On` : les quatre sous-programmes sont
**prouvés sans erreur à l'exécution**, et les deux procédures ont leur
postcondition démontrée. Le module 05 explique ce que cela veut dire ; ici, il
suffit de constater que `./scripts/verify.sh prove` le dit.

---

## 3. La campagne de test

Dix cas, dix-neuf vérifications. La répartition n'est pas le fruit du hasard :
le §6.4.2 demande **deux familles** de cas, et les compter séparément est une
bonne façon de voir qu'on n'a pas oublié la seconde.

| Famille | Cas | Ce qu'ils cherchent |
|---|---|---|
| Nominale | `to_litres_nominal`, `decode_sensor_id_nominal`, `clamp_temperature_nominal` | que le domaine normal marche |
| Bornes | `modular_type_wraps_to_zero`, `to_litres_full_scale` | que la borne exacte ne bascule pas du mauvais côté |
| Robustesse | `decode_sensor_id_robustness_out_of_domain`, `clamp_temperature_robustness_below_range`, `clamp_temperature_robustness_above_range`, `subtype_conversion_out_of_range_raises` | que l'entrée impossible est refusée, pas convertie |

Le dernier cas mérite un mot : il vérifie qu'une conversion `Integer` vers
`Celsius` hors domaine **lève bien** `Constraint_Error`. Autrement dit, il
teste que le langage fait son travail. C'est légitime ici parce que le module
enseigne ce comportement ; sur un vrai programme on ne teste pas le
compilateur, on le **qualifie** — sujet du module 11.

---

## 4. Exercices

1. Ajouter un type `Pressure_PSI` et un type `Pressure_Bar`, tous deux en
   virgule fixe. Écrire la conversion, puis essayer de les additionner
   directement : lire le message du compilateur.
2. Remplacer `subtype Celsius is Integer range -60 .. 90;` par
   `type Celsius is range -60 .. 90;` et recompiler. Combien d'erreurs ?
   Qu'est-ce que cela dit du choix entre sous-type et type distinct ?
3. Retirer `with Small => 0.001` de `Density_Kg_Per_L`, relancer la campagne
   et expliquer le résultat de `to_kilograms_applies_density`.
4. Écrire un cas de robustesse pour `To_Litres` qui montre qu'aucune valeur de
   `Raw_Count` ne sort de la plage de `Litres`. Puis constater que `gnatprove`
   l'a déjà démontré pour **toutes** les valeurs, et réfléchir à ce que le test
   apporte encore.

---

## 5. Pour l'entretien

> **« Pourquoi de la virgule fixe et pas du flottant ? »**
> Déterminisme et précision démontrable. Un type à virgule fixe est un entier
> mis à l'échelle : même résultat sur deux exécutions, erreur d'arrondi bornée
> par le `delta`, pas de `NaN` ni de mode d'arrondi à documenter. La DO-178C
> n'interdit pas le flottant, elle demande de justifier la précision (A-5.6) —
> et cette justification coûte beaucoup moins cher en virgule fixe.

> **« Sous-type ou type distinct ? »**
> Sous-type quand on restreint un domaine et qu'on veut rester compatible.
> Type distinct quand on veut qu'un mélange soit une **erreur de compilation** :
> des litres et des kilogrammes, des pieds et des mètres. Mars Climate Orbiter
> est l'argument.

> **« Ada vérifie les bornes à l'exécution, ça ne coûte pas cher en temps
> réel ? »**
> Si, et c'est le sujet du module 02. On peut les supprimer par
> `pragma Suppress`, mais il faut alors **prouver** qu'elles ne pouvaient pas
> se déclencher — ce que SPARK sait faire. On échange du temps processeur
> contre de l'effort de preuve, et la DO-178C accepte l'échange.

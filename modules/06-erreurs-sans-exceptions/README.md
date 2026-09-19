# Module 06 — Erreurs sans exceptions

> **Durée estimée** : 1 journée
> **Prérequis** : modules 00 à 05

---

Ada **a** des exceptions, et de bonnes. On les interdit quand même en DAL A/B.
Ce module explique pourquoi, montre ce qu'on met à la place, et fait la
démonstration par la construction : le même code compile sous un profil où
aucune exception ne peut être levée ni traitée.

---

## Objectifs pédagogiques

1. Savoir énoncer les quatre raisons d'interdire les exceptions en avionique
   critique — sans réciter « c'est interdit ».
2. Écrire une discipline de **statut de retour** qui rende le chemin d'erreur
   ordinaire, donc testable et mesurable.
3. Connaître `pragma Restrictions (No_Exception_Handlers,
   No_Exception_Propagation)` et ce que leur activation révèle.
4. Savoir raconter **Ariane 5 Vol 501** correctement, et en tirer la bonne
   leçon — qui n'est pas celle qu'on entend d'habitude.

---

## 1. Le cours

### 1.1 Pourquoi interdire ce qu'Ada fait bien

En C#, une exception est le mécanisme normal de signalement d'erreur. En C++,
la question ne se pose pas en embarqué : le dépôt frère les écarte d'emblée,
parce que leur coût et leur non-déterminisme sont rédhibitoires. En Ada, le
débat est plus riche : le mécanisme est propre, typé, et intégré au langage.

Quatre raisons de s'en priver quand même :

1. **Un chemin de contrôle invisible.** Toute instruction susceptible de lever
   crée un arc de sortie que le source ne montre pas. Le graphe de flot réel
   n'est pas celui qu'on lit — et c'est celui qu'il faut couvrir (A-7.5,
   A-7.6).
2. **Du code objet sans équivalent source.** Le déroulement de pile et les
   tables d'exception sont générés par le compilateur. C'est le sujet du
   module 02, et l'objectif A-7.9 au DAL A.
3. **Un temps d'exécution non borné.** Le coût d'une propagation dépend de la
   profondeur de pile et des tables parcourues. Une analyse WCET honnête doit
   soit le borner, soit exclure le mécanisme.
4. **Une sortie qui n'est pas un comportement spécifié.** Une exception non
   traitée arrête la tâche. Sur un calculateur de vol, « s'arrêter » est un
   comportement — et il doit avoir été demandé par une exigence, pas subi.

### 1.2 Ce qu'on met à la place : le statut est une valeur

```ada
type Status_Code is (Ok, Stale_Data, Out_Of_Range, Bad_Checksum);

procedure Decode
  (Input : Frame; Value : out Litres; Status : out Status_Code);
```

Trois propriétés qui comptent :

- **Le statut voyage avec la donnée.** L'appelant reçoit les deux, il ne peut
  pas lire la valeur sans avoir le statut sous les yeux.
- **Le chemin d'erreur est un chemin ordinaire.** Un `elsif` se teste et se
  mesure comme les autres. Avec des exceptions, les mêmes chemins seraient
  invisibles à la couverture structurelle du source.
- **La postcondition dit tout.** Ici :

```ada
Post =>
  (Status = Ok)
  = (Input.Checksum = Expected_Checksum (Input.Raw, Input.Age)
     and then Input.Raw <= Litres'Last
     and then Input.Age <= Max_Age)
  and then (if Status = Ok then Value = Input.Raw else Value = 0);
```

Le `= (…)` est important : la postcondition dit **exactement quand** le statut
vaut `Ok`, pas seulement ce qui se passe quand il le vaut. Une spécification
qui ne dirait que le cas nominal laisserait le corps libre de refuser des
trames valides.

> **Détail de conception à ne pas rater.** L'ordre des littéraux de
> `Status_Code` est l'ordre de **gravité croissante**. `Worst` se réduit alors
> à `Status_Code'Max`, sans table de correspondance à maintenir en parallèle
> du type. C'est une idée simple qui évite une classe entière de défauts de
> synchronisation.

### 1.3 L'interdire pour de bon : `pragma Restrictions`

Un standard de codage qui dit « pas d'exceptions » est un document. Ceci est
une contrainte vérifiée par le compilateur **et** par l'éditeur de liens :

```ada
pragma Restrictions (No_Exception_Handlers);
pragma Restrictions (No_Exception_Propagation);
```

Le sous-projet [`restreint/`](restreint/) construit **le même source** — il
pointe sur `../src`, il ne duplique rien — sous ce profil. S'il se lie, c'est
que `Mod06.Sensor_Io` ne dépend d'aucune exception. Aucune relecture ne
donnerait cette garantie.

### 1.4 Ce que l'interdiction révèle — et c'est le meilleur du module

Première tentative de construction sous ce profil, sans rien d'autre :

```
m.adb:6:37: warning: pragma Restrictions (No_Exception_Propagation) in effect
m.adb:6:37: warning: "Constraint_Error" may result in unhandled exception
```

GNAT signale **chaque endroit** où une vérification pourrait lever une
exception qui n'a nulle part où aller. Avec `-gnatwe`, ce sont des erreurs :
la construction échoue.

Pour qu'elle passe, il faut supprimer les vérifications — `-gnatp`. Et
supprimer une vérification sans avoir prouvé qu'elle ne pouvait pas se
déclencher rend l'exécution *erroneous* (module 02, §1.5).

**Les trois modules se referment ici :**

> interdire les exceptions **oblige** à supprimer les vérifications, ce qui
> **oblige** à les avoir prouvées.

Ce n'est pas une chaîne de conséquences théorique : c'est ce que la
construction de `restreint/` impose, ligne de commande à l'appui.

### 1.5 Ariane 5, Vol 501 — et la vraie leçon

**4 juin 1996.** Vol inaugural d'Ariane 5. Trente-sept secondes après le
décollage, le lanceur bascule, se disloque sous les efforts aérodynamiques et
se détruit. Environ 370 M$ perdus, charge utile comprise.

La chaîne des faits, telle que l'a établie la commission d'enquête présidée
par Jacques-Louis Lions :

1. Le **Système de Référence Inertielle (SRI)**, écrit en Ada et **repris
   d'Ariane 4**, convertit une valeur de biais horizontal d'un flottant 64
   bits vers un entier signé 16 bits.
2. La trajectoire d'Ariane 5 comporte une vitesse horizontale bien supérieure
   à celle d'Ariane 4. La valeur **dépasse la plage** de l'entier 16 bits.
3. La conversion lève une **Operand Error**. Elle **n'est pas traitée** : la
   protection avait été retirée sur cette variable, parmi d'autres, pour tenir
   le budget de charge processeur.
4. Le SRI s'arrête — comportement spécifié pour une **panne matérielle**, pas
   pour une faute logicielle — et émet un motif de diagnostic sur son bus.
5. Le SRI de secours, exécutant **le même logiciel sur les mêmes données**,
   avait échoué de façon identique une fraction de seconde plus tôt.
6. Le calculateur de bord interprète le motif de diagnostic comme des données
   de vol, commande une déflexion extrême des tuyères, et le lanceur se
   rompt.

Ce qu'on en retient d'habitude — « il ne faut pas réutiliser du code » — est
faux et inutile. Les vraies leçons sont ailleurs :

- **Le code était correct.** Il l'était pour le domaine opérationnel
  d'Ariane 4. C'est l'**hypothèse** qui a changé, pas le code.
- **La protection avait été retirée sur la foi d'une analyse.** L'analyse
  disait que la valeur ne pouvait pas déborder. Elle était juste — pour
  Ariane 4. Personne ne l'a rejouée pour Ariane 5, parce que rien, dans le
  code, ne disait de quoi elle dépendait.
- **La redondance n'a rien apporté.** Deux exemplaires du même logiciel avec
  les mêmes entrées produisent la même panne. La redondance couvre les pannes
  matérielles, pas les fautes de conception.
- **La fonction fautive ne servait plus.** Le calcul d'alignement du SRI
  n'était utile qu'avant le décollage ; il continuait de tourner pendant
  quarante secondes de vol par héritage d'Ariane 4.

**Et le lien avec ce dépôt.** Le point 2 est exactement le motif du module 02 :
supprimer une vérification sur la foi d'une analyse. Écrite en SPARK, cette
analyse serait une **précondition explicite** sur le domaine d'entrée, et
rejouer `gnatprove` sur la nouvelle trajectoire aurait produit une obligation
non déchargée. L'hypothèse aurait été dans le code, et sa révision aurait été
mécanique au lieu d'être oubliée.

Ce n'est pas dire que SPARK aurait sauvé le vol : c'est dire **où** l'outillage
moderne place le filet — sur la transmission des hypothèses, qui est le point
exact où celle-ci a cédé.

### 1.6 Et `Last_Chance_Handler` ?

Sur un environnement d'exécution restreint (*Zero FootPrint*), il n'y a pas de
propagation d'exception du tout. Ce qui reste est un point d'entrée unique :

```ada
procedure Last_Chance_Handler (Msg : System.Address; Line : Integer)
  with Export, Convention => C,
       External_Name => "__gnat_last_chance_handler";
```

GNAT y saute quand une vérification échoue. Le corps typique n'a pas le droit
de revenir : il journalise dans une mémoire non volatile, force un état sûr,
et déclenche le chien de garde.

Ce dépôt ne le compile pas : avec l'environnement d'exécution complet, le
symbole est déjà défini et la démonstration serait un conflit d'édition de
liens plutôt qu'un enseignement. Le sujet appartient au module 07, avec le
profil Ravenscar.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod06-sensor_io.ads`](src/mod06-sensor_io.ads) | Le type `Status_Code` ordonné, et la postcondition complète |
| [`src/mod06-sensor_io.adb`](src/mod06-sensor_io.adb) | Onze instructions, aucun `raise` |
| [`src/main.adb`](src/main.adb) | Quatre trames, quatre statuts |
| [`tests/test_sensor_io.adb`](tests/test_sensor_io.adb) | Six cas, treize vérifications, 100 % MC/DC |
| [`restreint/restrictions.adc`](restreint/restrictions.adc) | Le profil sans exceptions |
| [`restreint/restreint.gpr`](restreint/restreint.gpr) | La démonstration par la construction |

---

## 3. Exercices

1. Ajouter un `exception when others => null;` dans `Sensor_Io` et
   reconstruire `restreint/`. Quel message, et de quel outil vient-il ?
2. Retirer `-gnatp` de `restreint.gpr`. Combien d'avertissements `-gnatw.x`,
   et sur quelles lignes exactement ? Rapprocher cette liste des obligations
   que `gnatprove` décharge sur le même code.
3. Inverser deux littéraux de `Status_Code` et relancer la campagne. Quel cas
   tombe, et qu'est-ce que cela dit du couplage entre l'ordre d'un type et le
   comportement de `Worst` ?
4. Rédiger l'exigence de bas niveau qui aurait dû accompagner la suppression
   de protection du SRI d'Ariane 4, sous une forme qui aurait obligé à la
   rejouer sur Ariane 5.

---

## 4. Pour l'entretien

> **« Ada a des exceptions, pourquoi les interdire ? »**
> Quatre raisons : un chemin de contrôle que le source ne montre pas, du code
> objet sans équivalent source, un temps de propagation non borné, et une
> sortie qui n'est pas un comportement spécifié. On les remplace par un statut
> de retour, ce qui rend le chemin d'erreur ordinaire — donc testable et
> mesurable.

> **« Comment garantissez-vous qu'il n'y en a pas ? »**
> Par `pragma Restrictions (No_Exception_Handlers,
> No_Exception_Propagation)`, vérifié à la compilation et à l'édition de
> liens. Sur ce dépôt, un sous-projet construit le même source sous ce
> profil : si ça se lie, la garantie est acquise. Et l'activer révèle
> immédiatement toutes les vérifications qu'il faut alors avoir prouvées.

> **« Parlez-moi d'Ariane 501. »**
> Une conversion flottant 64 bits vers entier 16 bits déborde parce que la
> trajectoire d'Ariane 5 sortait du domaine d'Ariane 4 ; la protection avait
> été retirée pour tenir le budget CPU, sur la foi d'une analyse valable pour
> l'ancien lanceur. La leçon n'est pas « ne pas réutiliser » : c'est que
> l'hypothèse justifiant la suppression n'était écrite nulle part dans le
> code, donc personne ne l'a rejouée. En SPARK, ce serait une précondition, et
> sa révision serait mécanique.

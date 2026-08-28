# Module 12 — Projet intégré : le FQMS

> **Durée estimée** : 3 journées
> **Prérequis** : tous les modules précédents

---

Le module final, et la raison d'être des deux dépôts pris ensemble.

Le **FQMS** — *Fuel Quantity Management System*, DAL B — est implémenté ici en
Ada/SPARK contre **exactement les mêmes exigences de haut niveau** que le
module 16 du dépôt frère en C++. Mêmes énoncés, mêmes seuils, même hystérésis,
même justification de DAL.

Un ingénieur qui ouvre les deux implémentations côte à côte voit en trente
secondes ce qui relève du **processus** — et qui ne bouge pas — et ce qui
relève du **langage**.

---

## 1. Ce qui ne change pas

| Artefact | Ada/SPARK | C++ |
|---|---|---|
| SRD (13 HLR, dont 1 dérivée) | identique | identique |
| Justification du DAL B | identique | identique |
| Seuils, hystérésis, temporisation | identiques | identiques |
| Notion de traçabilité bidirectionnelle | identique | identique |
| Familles de cas de test (HLR / LLR) | identiques | identiques |

Le [SRD](requirements/srd.md) est **le même document**, énoncé pour énoncé.
Seuls les champs *Vérification* citent des noms de cas de test différents,
puisqu'ils désignent des campagnes différentes.

C'est le point à faire valoir en entretien : **le processus est la constante,
le langage est la variable.**

---

## 2. Ce qui change

Le [SDD](requirements/sdd.md), lui, diffère — et c'est normal : les exigences
de haut niveau ne dépendent pas du langage, la conception si.

| | Ada/SPARK | C++ |
|---|---|---|
| Domaine des valeurs | dans le type (`subtype Kilograms is Natural range 0 .. 20_000`) | vérifié à la main |
| Absence d'erreur à l'exécution | **prouvée** (40 obligations) | argumentée, revue |
| Couplage données/contrôle | déclaré et vérifié | tableau tenu à la main |
| Loi de conversion | postcondition **prouvée** pour tout le domaine | testée sur les cas écrits |
| État du composant | paramètre `in out` | membre de classe |

### La décision d'architecture qui vient de l'outillage

**DA-01 : l'état est un paramètre, pas un `Abstract_State` de paquetage.**

Ce n'est pas un choix de style. Le module 04 §1.7 a établi que `gnatcov
instrument` ne sait pas instrumenter un paquetage porteur d'un
`Abstract_State`. Un composant DAL B doit être mesuré en couverture ; un état
de paquetage l'en empêcherait.

C'est un cas où **l'outillage a façonné l'architecture**. Cela arrive plus
souvent qu'on ne l'admet, et un SDD doit le dire plutôt que de le taire. Le
dépôt frère n'a pas cette contrainte : `gcov` instrumente le code objet et se
moque de la structure du paquetage.

---

## 3. Ce que la mesure de couverture a changé dans le code

C'est la partie la plus instructive du module, et elle n'était pas prévue.

Le composant compilait sans avertissement, ses 41 obligations de preuve étaient
déchargées, et ses 18 cas de test passaient. Le rapport de couverture disait
autre chose :

```
98% statement coverage (43 out of 44)
76% decision  coverage (13 out of 17)
72% MC/DC     coverage (13 out of 18)
```

**76 % de couverture de décisions sur un composant DAL B, où elle est exigée.**
Trois causes distinctes, trois réponses différentes — et aucune n'était
« ajouter un test pour faire monter le chiffre ».

### 3.1 Une garde inatteignable, retirée

```ada
if Ticks < Confirm_Cycles then
   Ticks := Ticks + 1;
end if;
```

Le compteur est remis à zéro à chaque transition : il **ne peut jamais**
atteindre `Confirm_Cycles` au moment d'être incrémenté. La garde était morte.

Réponse : réécrire la machine à confirmation sans garde,

```ada
if not Transition_Now then
   Ticks := 0;
elsif Ticks = Confirm_Cycles - 1 then
   Active := not Active;
   Ticks  := 0;
else
   Ticks := Ticks + 1;
end if;
```

et resserrer le domaine du compteur à `0 .. Confirm_Cycles - 1`, puisque c'est
désormais la vérité. **La mesure a rendu le type plus juste.**

### 3.2 Une saturation non atteignable, redimensionnée

```ada
if S.Rejected (Tank) < Natural'Last then
```

Le compteur de maintenance saturait à `Natural'Last`. La branche de saturation
est exigée par LLR-FQMS-020 — donc ce n'est **pas** du code mort — mais elle
n'est pas atteignable par un test : 2³¹ cycles ne se jouent pas dans une
campagne.

Deux issues possibles : justifier l'écart de couverture par analyse, ou rendre
la borne atteignable. Le domaine est devenu

```ada
subtype Reject_Count is Natural range 0 .. 65_535;
```

soit un compteur BITE 16 bits — ce qui est d'ailleurs **ce qu'on trouve en
équipement réel**. La campagne joue maintenant 65 536 cycles et vérifie la
saturation en quelques millisecondes.

C'est le meilleur exemple du module : **la conception s'est adaptée à la
vérifiabilité**, et le résultat est plus proche de la réalité industrielle
qu'avant.

### 3.3 Un cas de test manquant, ajouté

```ada
if Ok (Left_Wing) and then Ok (Right_Wing) then
```

Tous les cas de panne de jauge d'aile utilisaient l'aile **gauche**. La
condition `Ok (Right_Wing)` n'était donc jamais celle qui faisait basculer la
décision, et MC/DC restait incomplet. Un cas symétrique a été ajouté.

Aucune relecture n'aurait trouvé cela ; la mesure l'a trouvé en une exécution.

### 3.4 Le résultat

```
100% statement coverage (35 out of 35)
100% decision  coverage (14 out of 14)
100% MC/DC     coverage (15 out of 15)
```

Et au passage : **44 instructions sont devenues 35**. Le composant a maigri de
neuf lignes en gagnant en couverture — parce que ce qui a disparu était du code
que rien ne justifiait. C'est très exactement ce que le §6.4.4.3 attend de
l'analyse de couverture structurelle.

---

## 4. État de la vérification

| Activité | Résultat |
|---|---|
| Compilation, avertissements en erreurs | **0 avertissement** |
| Preuve SPARK, `--level=2` | **40 obligations déchargées** |
| Campagne | **24 cas, 46 vérifications, 0 échec** |
| Couverture | **100 %** instructions, décisions, MC/DC |
| Traçabilité, `--strict` | **0 défaut** |

Le DAL B n'exige que les décisions ; MC/DC est mesuré en plus parce que la
chaîne le permet et que le module 10 en fait le sujet.

---

## 5. Le profil de vol

`bin/main` joue vingt-trois cycles et montre le comportement complet :

```
== Déséquilibre : cinq cycles avant que l'alerte ne se lève ==
  cycle 4 | total 8791 kg | VALID | -
  ...
  cycle 8 | total 8791 kg | VALID | DESEQUILIBRE

== Panne de jauge d'aile : l'alerte est CONSERVÉE, pas réévaluée ==
  cycle 10 | total 6349 kg | DEGRADED | DESEQUILIBRE
  rejets sur l'aile gauche : 2

== Retour équilibré : cinq cycles avant effacement ==
  cycle 15 | total 8791 kg | VALID | DESEQUILIBRE
  cycle 16 | total 8791 kg | VALID | -
```

Les trois comportements que le SRD demande — confirmation sur cinq cycles,
gel sur panne de jauge, hystérésis à l'effacement — se lisent directement.

---

## 6. Les fichiers

| Fichier | Rôle |
|---|---|
| [`requirements/srd.md`](requirements/srd.md) | 13 HLR, **identiques au dépôt C++** |
| [`requirements/sdd.md`](requirements/sdd.md) | architecture Ada/SPARK et 9 LLR |
| [`src/mod12-fqms.ads`](src/mod12-fqms.ads) | l'interface et ses contrats |
| [`src/mod12-fqms.adb`](src/mod12-fqms.adb) | 35 instructions, 40 obligations prouvées |
| [`src/main.adb`](src/main.adb) | le profil de vol |
| [`tests/test_fqms.adb`](tests/test_fqms.adb) | 24 cas, deux familles |

---

## 7. Exercices

1. Ajouter un quatrième réservoir. Combien de fichiers faut-il toucher ?
   Combien d'exigences ? Comparer avec la même modification côté C++.
2. Faire passer `Confirm_Cycles` de 5 à 3 **sans** toucher aux tests. Combien
   de cas tombent, et lesquels ? Qu'est-ce que cela dit de la qualité de la
   campagne ?
3. Rétablir la garde inatteignable du §3.1 et relancer `coverage.sh`. Retrouver
   le chiffre exact avant correction.
4. Écrire l'exigence manquante : que doit faire le FQMS si la jauge d'un
   réservoir se met à osciller entre valide et invalide à chaque cycle ?
5. Rédiger la fiche de dérivation de HLR-FQMS-041, telle qu'elle serait
   transmise au processus de sécurité système.

---

## 8. Pour l'entretien

> **« Qu'est-ce que vous avez fait comme projet ? »**
> Le même système de jaugeage carburant DAL B, contre les mêmes exigences de
> haut niveau, dans deux langages : C++17 et Ada/SPARK. Les SRD sont
> identiques énoncé pour énoncé ; les SDD diffèrent. C'est ce qui rend la
> comparaison utile — on voit exactement ce que le langage change et ce qu'il
> ne change pas.

> **« Qu'est-ce que la version Ada apporte concrètement ? »**
> Quarante obligations de preuve déchargées, dont la loi de conversion
> démontrée pour tout le domaine d'entrée et l'absence d'erreur à l'exécution.
> Le couplage de données est déclaré dans le code et vérifié par l'outil au
> lieu d'être un tableau tenu à la main. Et les bornes sont dans les types,
> donc elles ne peuvent pas diverger de la spécification.

> **« Racontez-moi un défaut que vous avez trouvé. »**
> La couverture structurelle a trouvé trois choses sur un composant qui
> compilait sans avertissement, passait ses tests et était entièrement prouvé :
> une garde inatteignable, une saturation non testable, et un cas de test
> manquant. Le composant a perdu neuf instructions en gagnant vingt-quatre
> points de couverture de décisions. C'est exactement le rôle que le §6.4.4.3
> donne à la couverture : trouver ce que les exigences ne justifient pas.

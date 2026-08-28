# Module 10 — Couverture structurelle et crédit de preuve

> **Durée estimée** : 1,5 journée
> **Prérequis** : modules 00 à 09

---

Module de **processus**, donc condensé : le dépôt frère en C++
([module 11](../../../DO-178C-training/modules/11-couverture-structurelle/))
fait autorité pour le traitement long. Ce qui est ici, ce sont les **mesures**
— faites sur ce code-ci, avec GNATcoverage, jusqu'au MC/DC que `gcov` ne
savait pas produire.

---

## Objectifs pédagogiques

1. Distinguer couverture d'**instructions**, de **décisions** et **MC/DC**, et
   savoir laquelle est exigée à quel DAL.
2. Comprendre à quoi sert vraiment la couverture structurelle — ce n'est pas
   ce qu'on croit.
3. Savoir lire un rapport GNATcoverage et le rapprocher du minimum théorique.
4. Savoir ce que la preuve permet de créditer, et ce qu'elle ne remplace pas.
5. Connaître les trois cas où couverture et preuve se contredisent ou se
   gênent — tous rencontrés dans ce dépôt.

---

## 1. Le cours

### 1.1 Trois niveaux, trois DAL

| Objectif A-7 | Couverture | Exigée à partir du |
|---|---|---|
| 5 | **MC/DC** | DAL A |
| 6 | **décisions** | DAL B |
| 7 | **instructions** | DAL C |
| 8 | code objet sans équivalent source | DAL A (voir module 02) |

Ce n'est pas une échelle de zèle : chaque niveau répond à une question
différente.

- **Instructions** : chaque ligne a-t-elle été exécutée au moins une fois ?
- **Décisions** : chaque test booléen a-t-il pris ses deux valeurs ?
- **MC/DC** : chaque **condition** a-t-elle démontré qu'elle pouvait, **à elle
  seule**, faire basculer le résultat de sa décision ?

### 1.2 La mesure, sur ce module

Le composant a une décision et trois conditions :

```ada
if Low_Fuel or else (Imbalance and then Sensor_Fault) then
```

Deux campagnes exercent **le même source**. Voici les deux rapports, produits
côte à côte par `./scripts/coverage.sh` :

| Campagne | Instructions | Décisions | MC/DC |
|---|---|---|---|
| `decision-seule/` — 2 cas | 100 % (3/3) | **100 % (1/1)** | **33 % (1/3)** |
| `tests/` — 4 cas distincts | 100 % (3/3) | 100 % (1/1) | **100 % (3/3)** |

**Deux cas de test suffisent à atteindre 100 % de couverture de décisions, et
laissent deux conditions sur trois jamais démontrées.** Un projet DAL C
s'arrêterait là et aurait raison ; un projet DAL A ou B serait en défaut, avec
un tableau de bord au vert.

C'est l'argument le plus utile du module : **le chiffre de couverture n'a de
sens qu'avec son niveau.** « 100 % de couverture » ne veut rien dire.

### 1.3 Comment MC/DC se satisfait

Pour chaque condition, il faut une **paire** de cas qui ne diffèrent que par
elle et donnent des résultats opposés. Sur notre décision :

| Condition | Cas vrai | Cas faux | Ce qui varie |
|---|---|---|---|
| `Low_Fuel` | (T, F, F) → vrai | (F, F, F) → faux | `Low_Fuel` seul |
| `Imbalance` | (F, T, T) → vrai | (F, F, T) → faux | `Imbalance` seul |
| `Sensor_Fault` | (F, T, T) → vrai | (F, T, F) → faux | `Sensor_Fault` seul |

Quatre cas distincts au total — le minimum théorique pour N conditions est
**N+1**, et il est atteint ici. C'est pour permettre cette relecture que le
composant expose `Condition_Count` : une revue de couverture sans point de
comparaison se réduit à faire confiance à l'outil.

> **Note sur le court-circuit.** `or else` et `and then` court-circuitent.
> GNATcoverage applique alors le **MC/DC masqué** (*masking MC/DC*), qui est la
> variante admise par la CAST-10 et par les outils qualifiés : une condition
> non évaluée est considérée comme masquée, pas comme non couverte. Sans cela,
> MC/DC serait inatteignable sur toute expression court-circuitée — c'est-à-dire
> sur la quasi-totalité du code Ada.

### 1.4 À quoi sert vraiment la couverture structurelle

C'est le point que la plupart des développeurs ont faux, et il est écrit noir
sur blanc au **§6.4.4.3** :

> La couverture structurelle ne sert pas à **valider** le code. Elle sert à
> révéler le code que les exigences ne justifient pas.

Ce qu'elle cherche :

| Ce qu'elle trouve | Ce que ça veut dire | Que faire |
|---|---|---|
| Code jamais exercé | exigence non testée | ajouter le cas |
| Code **inatteignable** | garde redondante, condition impossible | **retirer le code** |
| Code désactivé (*deactivated*) | option non utilisée sur cette configuration | justifier, isoler |
| Code mort (*dead code*) | rien ne le justifie | **retirer** |

La distinction *dead* / *deactivated* est un classique d'entretien : le code
**désactivé** est prévu, tracé à une exigence, simplement inactif dans cette
configuration — il reste et se justifie. Le code **mort** n'est justifié par
rien — il part.

**Ce dépôt en a trouvé un exemple réel.** Module 08, `Is_Plausible` des
ultrasons :

```ada
is (Value >= Self.Dead_Zone and then Value <= Full_Scale)
```

Onze obligations de preuve déchargées, zéro avertissement, et **MC/DC bloqué à
1 sur 2**. La seconde condition ne peut jamais valoir `False` : la `Pre'Class`
héritée garantit déjà `Value <= Full_Scale`. La bonne réponse n'était pas
d'inventer un cas de test impossible, c'était de **retirer la garde**. La
couverture avait fait exactement son travail.

### 1.5 Couverture ≠ vérification des exigences

Une confusion coûteuse, à savoir désamorcer :

- La couverture **structurelle** mesure ce que le **code** a subi.
- La couverture **des exigences** mesure ce que la **spécification** a subi.

Un code peut être couvert à 100 % en MC/DC et ne satisfaire aucune exigence :
il suffit qu'il fasse la mauvaise chose, complètement. Inversement, toutes les
exigences peuvent être testées et laisser du code non exercé — c'est
précisément le signal du §6.4.4.3.

**Les deux sont exigées, et elles se lisent ensemble.** C'est pourquoi
`verify.sh` produit la matrice de traçabilité (module 09) *et*
`coverage.sh` produit les rapports.

### 1.6 Ce que la preuve permet de créditer

La **DO-333** autorise à satisfaire certains objectifs par la preuve plutôt
que par le test. Le détail est au [module 05](../05-spark-preuve-do333/), et
voici ce qu'il faut en retenir ici :

| | Ce que ça démontre | Sur quoi |
|---|---|---|
| **Preuve** | la propriété vaut pour **tout** le domaine | le **code source** |
| **Couverture** | les tests ont exercé telle partie du code | l'**exécutable** |

Elles ne se remplacent pas, et **ce dépôt l'a mesuré**. Module 05 : la
postcondition du vote médian était démontrée pour toutes les entrées — 28
obligations sur 28 — et la campagne initiale plafonnait à **55 % de MC/DC**.
Il a fallu ajouter les six permutations de trois valeurs distinctes pour
atteindre 11 sur 11.

Autrement dit : **une preuve complète ne dit rien de ce que les tests ont
exercé sur le binaire.** C'est pourquoi la DO-333 n'autorise pas à créditer
A-7.5 sans démontrer par ailleurs la complétude des propriétés (FM.6.7.1).

### 1.7 Quand les deux outils se gênent

Trois cas rencontrés en construisant ce dépôt, tous documentés là où ils
mordent :

1. **`gnatcov` et `Abstract_State` sont incompatibles** (module 04 §1.7).
   L'instrumentation insère une variable témoin devant chaque déclaration
   d'objet ; dans un paquetage à état abstrait, ces variables deviennent de
   l'état caché absent du `Refined_State`, et GNAT rejette le raffinement.
   Réponse retenue : coquille d'état mince sans décision, logique dans un
   paquetage sans état — qui, lui, est mesuré — et exclusion **justifiée par
   écrit** dans [`scripts/coverage.sh`](../../scripts/coverage.sh).
2. **La preuve ne remplace pas la mesure** (§1.6 ci-dessus).
3. **La mesure trouve ce que la preuve accepte** (§1.4 ci-dessus).

Ce genre d'arbitrage — deux outils qualifiables qui ne peuvent pas s'appliquer
au même code — est ce qu'un **plan de vérification** doit trancher et
justifier. Le rencontrer sur un dépôt de cette taille est une chance.

### 1.8 Instrumentation de source ou traces binaires

GNATcoverage sait faire les deux, et le choix n'est pas neutre :

| | Instrumentation de source | Traces binaires |
|---|---|---|
| Ce qui est mesuré | le **source** | le **code objet** |
| Ce qu'il faut | rien de spécial | émulateur ou sonde matérielle |
| Objectif A-7.8 (DAL A) | ne le couvre pas | le couvre |
| Effet sur le code | le modifie (voir §1.7) | aucun |

Ce dépôt fait de l'instrumentation de source : c'est ce qui tourne sans cible.
Un projet DAL A réel utilise les traces binaires, ou justifie l'écart.

---

## 2. Les artefacts du module

| Fichier | Rôle |
|---|---|
| [`src/mod10-warning.adb`](src/mod10-warning.adb) | Une décision, trois conditions |
| [`tests/test_warning.adb`](tests/test_warning.adb) | La campagne qui atteint MC/DC |
| [`decision-seule/`](decision-seule/) | La campagne qui s'arrête à la décision |
| [`requirements/`](requirements/) | SRD et SDD, dont une exigence dérivée |
| [`../../scripts/coverage.sh`](../../scripts/coverage.sh) | La mesure, et ses exclusions justifiées |

Les deux rapports sortent dans `reports/couverture/`, un par projet.

---

## 3. Exercices

1. Retirer un des trois cas `mcdc_pair_*` de la campagne complète. Quel
   chiffre bouge, et de combien ? Le prédire **avant** de mesurer.
2. Remplacer `or else` par `or` dans la décision. La couverture MC/DC
   change-t-elle ? Et le nombre de cas nécessaires ? Expliquer avec la notion
   de MC/DC masqué.
3. Ajouter une quatrième condition. Combien de cas au minimum, et combien de
   paires faut-il construire ?
4. Retirer `mod04-fuel_monitor.ad?` de la liste d'exclusions de
   `coverage.sh`, reproduire l'erreur du §1.7, puis rédiger la justification
   d'exclusion comme si elle devait être lue par une autorité.
5. Écrire un sous-programme couvert à 100 % en MC/DC et qui ne satisfait
   **aucune** exigence du SRD. Conclusion ?

---

## 4. Pour l'entretien

> **« Vous avez 100 % de couverture ? »**
> La question est incomplète : 100 % de quoi ? Sur ce dépôt, deux cas de test
> donnent 100 % de couverture de décisions sur une expression à trois
> conditions, et 33 % de MC/DC. Le chiffre n'a de sens qu'avec son niveau, et
> le niveau dépend du DAL : instructions au DAL C, décisions au DAL B, MC/DC
> au DAL A.

> **« À quoi sert la couverture structurelle ? »**
> Pas à valider le code : à trouver ce que les exigences ne justifient pas —
> code mort, code désactivé, gardes redondantes. Le §6.4.4.3 le dit ainsi.
> Sur ce dépôt, elle a trouvé une garde rendue inatteignable par une
> précondition de classe, sur du code par ailleurs entièrement prouvé.

> **« La preuve dispense-t-elle de mesurer la couverture ? »**
> Non, et j'ai le contre-exemple : un vote médian dont les 28 obligations
> étaient déchargées, donc correct pour toutes les entrées, et dont la
> campagne initiale ne couvrait que 55 % du MC/DC. La preuve porte sur le
> source, la couverture sur ce que les tests ont exercé du binaire. La DO-333
> encadre le crédit, elle ne l'accorde pas gratuitement.

> **« Dead code ou deactivated code ? »**
> Le code désactivé est prévu et tracé à une exigence, simplement inactif dans
> cette configuration : il reste, et il se justifie. Le code mort n'est
> justifié par rien : il part. Confondre les deux mène soit à supprimer du
> code nécessaire, soit à garder du code que personne n'a demandé.

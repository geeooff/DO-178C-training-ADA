# Module 04 — SPARK, analyse de flot

> **Durée estimée** : 1 journée
> **Prérequis** : modules 00 à 03

---

C'est le premier des deux modules SPARK. Celui-ci ne parle **pas** de preuve
mathématique : l'analyse de flot est rapide, elle n'a besoin d'aucun prouveur,
et elle trouve une famille de défauts que ni le compilateur ni les tests ne
trouvent. C'est aussi elle qui produit, gratuitement, l'artefact que
l'objectif **A-7.8** réclame.

---

## Objectifs pédagogiques

1. Savoir ce que `SPARK_Mode => On` interdit, et pourquoi.
2. Lire et écrire `Global`, `Depends`, `Abstract_State`, `Initializes`,
   `Refined_State`.
3. Comprendre que l'analyse de flot détecte les lectures non initialisées et
   les dépendances imprévues **sans exécuter le code**.
4. Faire le lien avec le **couplage de données et de contrôle** (A-7.8), et
   voir pourquoi Ada/SPARK transforme ce tableau en sortie d'outil.
5. Savoir séparer une **coquille d'état** d'une **logique de décision**, et
   savoir dire pourquoi ce n'est pas seulement une question de goût.

---

## 1. Le cours

### 1.1 SPARK, c'est Ada moins ce qui empêche de raisonner

SPARK n'est pas un autre langage : c'est un **sous-ensemble** d'Ada, plus des
aspects. Ce qu'il retire, il le retire parce que ça rend le raisonnement
automatique impossible :

| Interdit en SPARK | Pourquoi |
|---|---|
| Effets de bord dans les fonctions | une expression doit valoir la même chose deux fois |
| Aliasing entre paramètres | `Swap (X, X)` rend tout raisonnement faux |
| `goto` arrière, sorties non structurées | le graphe de flot doit rester lisible |
| Allocation dynamique non maîtrisée | pas de tas à raisonner |
| Exceptions comme flot normal | une sortie implicite par instruction |

`SPARK_Mode => On` s'applique unité par unité, et peut même s'appliquer à la
partie visible d'un paquetage dont le corps ne l'est pas. Le harnais de test
de ce dépôt est en `SPARK_Mode => Off` : c'est **déclaré**, pas subi.

> **Écart C# à retenir** : il n'y a pas d'équivalent. Les analyseurs Roslyn
> font de l'analyse de flot pour la nullité (`CS8602`), ce qui en est le
> cousin lointain — mais rien ne vérifie qu'une méthode ne touche que les
> champs qu'elle déclare toucher.

### 1.2 Ce que l'analyse de flot trouve

Sans prouveur, en quelques secondes, elle signale :

- une **variable lue avant d'être écrite**, sur n'importe quel chemin ;
- un paramètre `out` **non affecté** sur un chemin ;
- une affectation **jamais lue** — donc du code inutile ;
- une **dépendance non déclarée** entre une sortie et une entrée ;
- un **aliasing** entre deux paramètres modifiables.

Les trois premières familles sont ce que les revues de code cherchent
péniblement. La quatrième est celle qui intéresse la certification.

### 1.3 `Global` et `Depends` : le couplage de données, écrit dans le code

```ada
procedure Update (Reading : Litres)
with
  Global  => (In_Out => State),
  Depends => (State => (State, Reading));
```

`Global` dit **ce qui est touché**. `Depends` dit **ce qui dépend de quoi**.

Comparez avec `Reset` :

```ada
procedure Reset
with
  Global  => (Output => State),
  Depends => (State => null);
```

`Output` et non `In_Out` : l'état précédent n'est pas lu. `=> null` : aucune
information ne traverse le `Reset`. Ce n'est pas un commentaire d'intention —
si le corps lisait l'ancien état, `gnatprove` refuserait le contrat.

C'est exactement ce que l'objectif **A-7.8** demande d'établir : le couplage
de données (quelles données circulent entre composants) et le couplage de
contrôle (qui appelle qui). Le dépôt frère en C++ y consacre un module entier
et un tableau tenu à la main, qu'il faut ré-auditer à chaque modification.
Ici, le tableau **est** le contrat, et l'outil interdit qu'il mente.

> **Note d'écriture.** SPARK admet le raccourci `State =>+ Reading` pour
> « dépend aussi de lui-même ». Ce dépôt l'écrit en toutes lettres, parce que
> `gnatformat` réécrit `=>+` en `=> +`, forme que le vérificateur de style
> `-gnatyt` refuse ensuite. **Deux outils de notre propre chaîne se
> contredisent sur ce point.** La forme longue les met d'accord — et se lit
> mieux pour qui découvre la notation.

### 1.4 `Abstract_State` : cacher sans perdre l'information

Le paquetage a trois variables cachées. Les exposer serait une faute de
conception ; ne rien dire rendrait le couplage inanalysable. `Abstract_State`
résout les deux :

```ada
package Mod04.Fuel_Monitor
  with SPARK_Mode     => On,
       Abstract_State => State,
       Initializes    => State
```

La spécification parle de `State`, une abstraction. Le corps la raffine :

```ada
package body Mod04.Fuel_Monitor
  with Refined_State => (State => (Current, Alarm, Samples))
```

et chaque sous-programme précise son contrat au niveau concret
(`Refined_Global`, `Refined_Depends`). `gnatprove` vérifie que le raffinement
est **cohérent** avec l'abstraction. Un lecteur de la spécification a donc une
information vraie sans voir la représentation.

`Initializes => State` est la promesse que l'état est défini avant le premier
appel. C'est elle qui rend `Last_Reading` légitime dès la première ligne du
programme.

### 1.5 `Global => null` : la pureté déclarée

```ada
function Is_Low (Value : Litres) return Boolean
is (Value < Low_Level_Threshold)
with Global => null;
```

Cette fonction ne touche à rien. En C#, on l'écrirait `static` et on
espérerait. Ici c'est vérifié : si quelqu'un ajoute demain une lecture d'une
variable d'état dans son corps, la preuve échoue.

Pour le couplage de données, une fonction `Global => null` est un
**non-événement** : elle n'apparaît dans aucun couplage. C'est ce qui permet
de garder un tableau de couplage court, donc lisible, donc revu pour de vrai.

### 1.6 Les deux modes de `gnatprove`

```bash
gnatprove -P … --mode=flow    # analyse de flot seule : rapide
gnatprove -P … --mode=all     # flot + preuve : ce que fait verify.sh
```

En projet réel, on lance `--mode=flow` à chaque sauvegarde et `--mode=all` à
chaque intégration. Le premier trouve les défauts de structure en secondes ;
le second, les défauts d'arithmétique en minutes.

### 1.7 Coquille d'état mince : une bonne conception, et ici une nécessité

Le module est découpé en **deux** paquetages, et le découpage n'est pas
décoratif :

| Paquetage | Contenu | Comment il se vérifie |
|---|---|---|
| `Mod04.Alarm_Logic` | seuils, décision d'alarme, incrément saturant | tests exhaustifs sur les bornes, **MC/DC mesuré** |
| `Mod04.Fuel_Monitor` | trois variables, trois affectations | tests de **séquences** d'appels, contrats de flot prouvés |

C'est un motif classique en avionique : on garde la coquille d'état aussi
mince que possible, pour que la vérification porte sur la logique. Une
décision sans état se teste exhaustivement ; un état ne se teste qu'en
séquence.

**Et ici, ce découpage est obligatoire.** Vérifié sous GNATcoverage 26.2.1 :

> `gnatcov instrument` insère une variable témoin devant **chaque déclaration
> d'objet**. Dans un paquetage qui déclare un `Abstract_State`, ces variables
> deviennent de l'état caché que le `Refined_State` ne mentionne pas — et GNAT
> rejette alors le raffinement :
>
> ```
> mod04-fuel_monitor.adb:1:116: error: body of package "Fuel_Monitor"
>                                     has unused hidden states
> mod04-fuel_monitor.adb:1:116: error: variable "Discard_S_BODY0" ...
> ```
>
> Le comportement est identique que les constituants soient déclarés dans le
> corps ou dans la partie privée de la spécification, et l'option
> `--spark-compat` — qui rend le code instrumenté conforme aux règles *Ghost*
> — n'y change rien.

**Un paquetage à `Abstract_State` n'est donc pas mesurable par instrumentation
de source.** Trois réponses possibles, et il faut en choisir une explicitement :

1. **Concentrer la logique ailleurs**, et exclure la coquille de la mesure
   avec une justification écrite. C'est ce que fait ce dépôt : l'exclusion
   est dans [`scripts/coverage.sh`](../../scripts/coverage.sh), commentée.
2. **Mesurer par traces binaires** plutôt que par instrumentation de source.
   GNATcoverage sait le faire ; cela demande un émulateur ou une cible
   instrumentée.
3. **Renoncer à `Abstract_State`** sur les unités à mesurer. C'est perdre
   l'artefact A-7.8 pour gagner l'artefact A-7.5 : un mauvais échange.

Ce genre d'arbitrage — deux outils qualifiables qui ne peuvent pas s'appliquer
au même code — est exactement ce qu'un plan de vérification doit trancher et
justifier. Le rencontrer sur un dépôt de quarante lignes est une chance.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod04-alarm_logic.ads`](src/mod04-alarm_logic.ads) | La décision, sans état : `Global => null` partout |
| [`src/mod04-alarm_logic.adb`](src/mod04-alarm_logic.adb) | Deux corps, trois obligations MC/DC |
| [`src/mod04-fuel_monitor.ads`](src/mod04-fuel_monitor.ads) | `Abstract_State`, `Global`, `Depends`, `Initializes` |
| [`src/mod04-fuel_monitor.adb`](src/mod04-fuel_monitor.adb) | `Refined_State` et les contrats raffinés |
| [`tests/test_fuel_monitor.adb`](tests/test_fuel_monitor.adb) | Neuf cas, vingt-deux vérifications |

Le contrat raffiné de `Update` mérite un regard :

```ada
Refined_Global  => (Output => (Current, Alarm), In_Out => Samples),
Refined_Depends =>
  (Current => Reading, Alarm => Reading, Samples => Samples)
```

Trois informations vérifiées, qu'aucune revue ne garantirait aussi bien :
`Current` et `Alarm` sont **écrasés** (pas lus), ils dépendent **uniquement**
de `Reading`, et `Samples` ne dépend **que de lui-même**. Un futur
développeur qui ferait dépendre l'alarme du compteur d'échantillons casserait
la preuve, pas seulement le bon goût.

---

## 3. Exercices

1. Dans `Update`, remplacer `Alarm_Logic.Alarm_For (Reading)` par
   `Alarm_Logic.Alarm_For (Current)`. Le code reste correct — que dit
   `gnatprove`, et pourquoi a-t-il raison de protester ?
2. Retirer `Initializes => State` et relancer la preuve. Quel message, et sur
   quelle ligne ?
3. Ajouter une variable globale `Peak : Litres := 0;` mise à jour dans
   `Update`, **sans** toucher aux contrats. Combien d'erreurs, et où ?
4. Retirer `mod04-fuel_monitor.ad?` de la liste d'exclusions de
   `coverage.sh` et relancer. Reproduire le message du §1.7, puis rédiger la
   justification d'exclusion comme si elle devait être lue par une autorité.
5. Lancer `gnatprove --mode=flow` seul et chronométrer, puis `--mode=all`.
   Quel rapport de temps ? Qu'en conclure sur le rythme d'utilisation ?

---

## 4. Pour l'entretien

> **« Comment établissez-vous le couplage de données et de contrôle ? »**
> En Ada/SPARK, il est déclaré dans le code par `Global` et `Depends`, et
> `gnatprove` vérifie que le corps s'y conforme. L'artefact A-7.8 devient une
> sortie d'outil au lieu d'un tableau qu'on ré-audite à chaque modification.
> C'est probablement l'écart le plus net avec un projet C ou C++ équivalent.

> **« SPARK, c'est un autre langage ? »**
> Non, un sous-ensemble d'Ada plus des aspects. Le code SPARK se compile avec
> un compilateur Ada ordinaire ; les aspects sont ignorés si on ne lance pas
> `gnatprove`. On peut donc l'adopter unité par unité, ce qui compte sur un
> existant.

> **« Vous avez déjà vu deux outils de vérification se gêner ? »**
> Oui, et sur ce dépôt : l'instrumentation de GNATcoverage ajoute de l'état
> caché qui invalide le `Refined_State` de SPARK. La réponse a été de garder
> la coquille d'état mince et sans décision, de mesurer la logique, et
> d'écrire la justification d'exclusion dans le script de couverture plutôt
> que de la laisser implicite. Un plan de vérification doit trancher ce genre
> de conflit, pas le découvrir en audit.

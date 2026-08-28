# Module 11 — Standards, qualification d'outils et configuration

> **Durée estimée** : 1 journée
> **Prérequis** : modules 00 à 10

---

Module de **processus**, donc condensé : le dépôt frère en C++
([module 13](../../../DO-178C-training/modules/13-standards-codage/) pour le
standard,
[module 14](../../../DO-178C-training/modules/14-configuration-qualite/) pour
la configuration) fait autorité pour le traitement long.

Ce qui est **ici** : un standard de codage écrit pour Ada, son contre-exemple
qui refuse de compiler, le générateur de SCI et de SECI, et la question qui
revient toujours en entretien — *cet outil, il est qualifié ?*

---

## Objectifs pédagogiques

1. Écrire un standard de codage dont chaque règle dit **comment elle est
   vérifiée**, et savoir pourquoi c'est la seule colonne qui compte.
2. Connaître les trois **critères** de la DO-330 et les cinq **TQL**, et
   savoir poser la bonne question.
3. Savoir ce qu'est un **SCI** et un **SECI**, et pourquoi ils sont CC1 à
   tous les niveaux.
4. Savoir distinguer **CC1** et **CC2**, et ce que ça change.

---

## 1. Le cours

### 1.1 Un standard de codage utile

L'objectif **A-5.2** demande que le code soit conforme au standard. Il ne dit
pas ce que le standard doit contenir : c'est au projet de l'écrire, et de le
faire approuver.

Le standard de ce dépôt est
[`standard-de-codage.md`](standard-de-codage.md). Sa particularité est une
colonne : **chaque règle dit comment elle est vérifiée.**

| Mécanisme | Nombre de règles |
|---|---|
| compilateur | 11 |
| preuve | 7 |
| outil | 2 |
| **revue seule** | **8** |

Huit règles sur vingt-huit reposent sur un humain. **C'est le chiffre qu'un
auditeur regardera**, parce qu'il dit combien du standard tient à la
discipline plutôt qu'à la mécanique. Un standard de cent règles toutes en
revue vaut moins qu'un standard de vingt dont dix-huit sont vérifiées.

Ada aide beaucoup ici : `-gnatwe`, `-gnatyy` et surtout les `pragma
Restrictions` transforment en erreurs de compilation des règles qui, en C ou
en C++, resteraient des consignes.

### 1.2 Le contre-exemple qui refuse de compiler

Un standard sans contre-exemple exécutable est un document que personne ne
relit. [`nonconforme/src/bad_style.adb`](nonconforme/src/bad_style.adb) viole
**délibérément** six règles.

```bash
./scripts/coding-standard.sh
```

```
== Le contre-exemple sous les commutateurs du dépôt ==
  bad_style.adb:14:04: (style) subprogram body has no previous spec [-gnatys]
  bad_style.adb:16:06: (style) bad indentation [-gnaty0]
  bad_style.adb:16:80: (style) this line is too long: 91 [-gnatyM]
  bad_style.adb:20:04: (style) subprogram body has no previous spec [-gnatys]

Compilation refusée, comme attendu.
```

Et surtout, la seconde moitié de la sortie :

```
Ce que le compilateur N'A PAS vu, et qui reste à la revue :
  R-11  type nu Integer sans domaine borné
  R-21  garde redondante avec la précondition
  R-42  Ada.Text_IO et chaîne de longueur variable
  R-43  récursion
  R-61  identifiant en français
  R-62  commentaire qui paraphrase le code
```

**Quatre violations attrapées, six laissées.** C'est la frontière réelle entre
l'outillage et la revue, mesurée plutôt qu'estimée. Sur un projet GNAT Pro,
**GNATcheck** en attraperait plusieurs — R-43 et R-42 ont des règles LKQL
correspondantes. Ce dépôt ne peut pas s'en servir : GNATcheck n'est pas
distribué librement, et c'est une limite assumée.

> Le projet `nonconforme/` est **exclu** de `verify.sh` et de `format.sh` :
> il viole le standard à dessein, et son seul point d'entrée est le script
> ci-dessus. L'exclusion est écrite dans les scripts, avec sa raison.

### 1.3 Qualification d'outils : la bonne question

C'est la question piège, et la plupart des candidats y répondent à côté.

**La question n'est jamais « l'outil est-il bon ? ».** C'est :

> *Son résultat élimine-t-il, réduit-il ou automatise-t-il une activité que la
> DO-178C exige ?*

Si oui, il faut le **qualifier**. Sinon, non. La DO-330 formalise cela en
trois **critères** :

| Critère | L'outil… | Exemple |
|---|---|---|
| **1** | produit du code embarqué **et** son erreur peut introduire un défaut | générateur de code, compilateur dont on ne vérifie pas la sortie |
| **2** | vérifie, **et** son résultat permet de réduire une autre activité | outil de couverture dont le résultat remplace une revue |
| **3** | vérifie, sans réduire aucune autre activité | analyseur utilisé en complément |

Le critère se croise ensuite avec le DAL pour donner le **TQL** :

| Critère | DAL A | DAL B | DAL C | DAL D |
|---|---|---|---|---|
| 1 | TQL-1 | TQL-2 | TQL-3 | TQL-4 |
| 2 | TQL-4 | TQL-4 | TQL-5 | TQL-5 |
| 3 | TQL-5 | TQL-5 | TQL-5 | TQL-5 |

TQL-1 est proche de développer le logiciel embarqué lui-même. TQL-5 demande
des exigences opérationnelles de l'outil (*Tool Operational Requirements*) et
leur vérification.

**Les outils de ce dépôt :**

| Outil | Critère | Qualification requise ? |
|---|---|---|
| `common/src/testing.ads` | 3 | non — complète la revue |
| `gnatformat` | 3 | non — il **vérifie** en CI, il ne corrige pas |
| `tools/trace_check.py` | 3 | non — complète la revue manuelle |
| `tools/config_index.py` | — | non — produit une donnée, relue |
| `gnatprove` | **2** | **oui, si** la preuve remplace un objectif de test (DO-333) |
| `gnatcov` | **2** | **oui, si** le résultat remplace une revue de couverture |

Les deux derniers sont le vrai sujet. Et c'est là qu'Ada a un avantage
concret : **GNATcoverage dispose d'un kit de qualification DO-330 réel**,
vendu par AdaCore, avec ses TOR et ses tests. `clang-tidy` n'est qualifié pour
rien. Le sujet passe du concept à l'artefact commercial.

> **Nuance sur `gnatformat`.** La séparation entre `verify.sh format`, qui
> vérifie, et `format.sh`, qui corrige, n'est pas cosmétique. Un outil qui
> **réécrit** du code sous contrôle de configuration sans qu'un humain le
> demande serait un outil de **développement**, donc critère 1. La CI ne lance
> donc jamais `format.sh`.

### 1.4 SCI et SECI

Deux documents du §11, **CC1 à tous les niveaux** :

| Document | §  | Ce qu'il dit |
|---|---|---|
| **SCI** | 11.16 | ce qui **constitue** le logiciel : chaque fichier, sa taille, son empreinte |
| **SECI** | 11.15 | ce qui l'a **produit** : compilateur, options, outils, hôte |

Sans SCI, on ne peut pas affirmer que le binaire vérifié est celui qui vole.
Sans SECI, on ne peut pas le reconstruire dans quinze ans.

```bash
python3 tools/config_index.py
```

L'outil produit les deux dans `reports/`, depuis l'état réel du dépôt Git :
commit, étiquette, SHA-256 de chaque fichier suivi, empreinte globale. Il
refuse implicitement de mentir : si l'arbre de travail est modifié, le SCI le
dit en toutes lettres — **« OUI — NON BASELINABLE »**.

**Ce que cet outil fait de particulier ici.** Le SECI de ce dépôt n'est pas
une liste qu'on tient à jour : c'est
[`.devcontainer/Dockerfile`](../../.devcontainer/Dockerfile), où chaque
version est épinglée. L'outil lit donc ses `ARG` **et** interroge les outils
présents, puis rapproche les deux :

| Outil | Épinglé | Détecté |
|---|---|---|
| GNAT (gnatmake) | `16.1.0` | `16.1.0` |
| gprbuild | `26.0.1` | `26.0.0` |
| gnatprove | `16.1.0` | `16.1.0` |

Un écart est signalé. Et le premier rapprochement en a produit un vrai :
`gprbuild` s'annonce `26.0.0` alors que la crate Alire qui l'installe est
`26.0.1`. **Version de paquet et version auto-déclarée ne coïncident pas
toujours** — la comparaison porte donc sur `majeur.mineur`, et le document le
dit. C'est exactement le genre de détail qu'un SECI doit rendre visible plutôt
que lisser.

### 1.5 CC1 et CC2

Toutes les données de vie ne sont pas gardées de la même façon.

| | CC1 | CC2 |
|---|---|---|
| Traçabilité des changements | oui | oui |
| Protection contre modification non autorisée | oui | oui |
| **Revue et approbation formelles** | **oui** | non |
| **Archivage et récupération garantis** | **oui** | allégé |
| Exemples | plans, exigences, code source, SCI, SECI, résultats de vérification | standards de codage, cas de test intermédiaires, données de développement |

Le tableau A-2 de l'annexe A donne la catégorie de chaque donnée par niveau.
Le point à retenir : **le SCI et le SECI sont CC1 quel que soit le DAL**,
parce que sans eux le produit n'est ni identifiable ni reproductible.

Le standard de codage de ce dépôt est marqué **CC2**, et c'est délibéré : il
se relit et se met à jour sans la lourdeur d'une approbation formelle.

---

## 2. Les artefacts du module

| Fichier | Rôle DO-178C |
|---|---|
| [`standard-de-codage.md`](standard-de-codage.md) | *Software Code Standards*, §11.8 — CC2 |
| [`nonconforme/`](nonconforme/) | le contre-exemple, exclu du protocole |
| [`../../scripts/coding-standard.sh`](../../scripts/coding-standard.sh) | la frontière outillage / revue, mesurée |
| [`../../tools/config_index.py`](../../tools/config_index.py) | générateur SCI (§11.16) et SECI (§11.15) |

---

## 3. Exercices

1. Corriger les quatre violations que le compilateur attrape dans
   `bad_style.adb`, sans toucher aux six autres. Relancer le script :
   qu'est-ce qui reste, et qu'est-ce que cela dit du coût de la revue ?
2. Ajouter au standard une règle **vérifiable par le compilateur** qui
   attraperait R-43 (récursion). Indice : `pragma Restrictions`.
3. Générer le SCI, modifier un fichier, le régénérer. Que change la
   deuxième exécution, et pourquoi est-ce important ?
4. Modifier une version dans le `Dockerfile` sans reconstruire l'image, puis
   régénérer le SECI. Que dit-il ?
5. Pour chacun des six outils du §1.3, écrire la phrase qui justifierait sa
   **non**-qualification dans un plan de vérification.

---

## 4. Pour l'entretien

> **« Cet outil, il faut le qualifier ? »**
> La question n'est jamais « l'outil est-il bon » mais « son résultat
> élimine-t-il, réduit-il ou automatise-t-il une activité que la norme
> exige ». Si oui, on regarde le critère DO-330 — 1 pour un outil qui produit
> du code, 2 pour un outil de vérification dont le résultat réduit une autre
> activité, 3 pour un outil utilisé en complément — puis on croise avec le DAL
> pour obtenir le TQL.

> **« Un exemple concret ? »**
> GNATcoverage. Si le rapport de couverture remplace une revue, c'est critère
> 2, donc TQL-5 au DAL C, TQL-4 au DAL A. AdaCore vend un kit de qualification
> DO-330 réel pour cet outil, avec ses exigences opérationnelles et ses tests.
> C'est un argument concret en faveur de la chaîne Ada : `clang-tidy` n'est
> qualifié pour rien.

> **« Qu'est-ce qu'un SECI et pourquoi CC1 ? »**
> C'est l'identification exacte de l'environnement qui a produit le binaire :
> compilateur, version, options, outils. CC1 parce qu'un logiciel qu'on ne
> sait pas reconstruire à l'identique n'est pas certifiable, quel que soit son
> DAL. Sur mon dépôt, le SECI est généré depuis les versions épinglées du
> Dockerfile et rapproché de la machine — un écart est signalé plutôt que
> lissé.

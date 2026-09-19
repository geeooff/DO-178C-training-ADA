# Module 09 — Exigences, traçabilité et tests

> **Durée estimée** : 1,5 journée
> **Prérequis** : modules 00 à 08

---

Premier module de **processus**. Ce qu'il enseigne est indépendant du langage :
un ingénieur qui sait rédiger et tracer des exigences le sait en Ada comme en
C++. Le traitement est donc **condensé** — le dépôt frère en C++ y consacre
trois modules, [`09`](https://github.com/geeooff/DO-178C-training/tree/main/modules/09-exigences-tracabilite),
[`10`](https://github.com/geeooff/DO-178C-training/tree/main/modules/10-tests-bases-exigences) et
[`12`](https://github.com/geeooff/DO-178C-training/tree/main/modules/12-couplage-donnees-controle), et
fait autorité pour le traitement long.

Ce qui est **ici** et pas là-bas : les artefacts et l'outillage tournent dans
ce dépôt, sur du code Ada. Un renvoi aurait cassé la règle « vérifié pour de
vrai ».

---

## Objectifs pédagogiques

1. Distinguer HLR, LLR et exigence **dérivée**, et savoir pourquoi la
   troisième coûte cher.
2. Écrire un SRD et un SDD qui se tiennent, et savoir ce qui ne doit **pas** y
   figurer.
3. Comprendre la traçabilité **bidirectionnelle**, et pourquoi le sens
   remontant est le plus utile.
4. Faire vérifier la matrice **par un outil**, et savoir quel statut DO-330
   cet outil a.
5. Savoir pourquoi ce dépôt n'utilise pas AUnit.

---

## 1. Le cours

### 1.1 Trois niveaux, et une catégorie à part

| Niveau | Répond à | Écrit par | Vérifié par |
|---|---|---|---|
| Exigences système | *quel besoin ?* | ingénierie système | hors DO-178C |
| **HLR** | *que doit faire le logiciel ?* | processus d'exigences (§5.1) | tests boîte noire, revue A-3 |
| **LLR** | *comment ?* | processus de conception (§5.2) | tests boîte blanche, revue A-4 |

Et une catégorie transverse : l'**exigence dérivée** — celle qui ne remonte à
aucune exigence de niveau supérieur. Elle naît d'une décision de conception.
La DO-178C §5.1.2.h impose de l'identifier comme telle et de la **remonter au
processus de sécurité système**, parce que personne d'autre n'a pu en évaluer
l'effet sur la sécurité.

Le composant de ce module en a une :

```
  dont exigences DERIVEES        : 1
      HLR-FQMSCAL-004  (…/srd.md:65)
      -> a remonter au processus de securite systeme (5.1.2.h)
```

`HLR-FQMSCAL-004` dit que l'indication ne doit jamais dépasser la capacité du
réservoir. Aucune exigence système ne le demandait : c'est une décision prise
en concevant, parce qu'une sonde dérivée peut indiquer davantage et qu'un
équipage surestimerait alors son autonomie. **C'est exactement le genre de
raisonnement que le processus de sécurité doit voir**, et c'est pourquoi
l'outil la fait remonter en haut du rapport plutôt que de la noyer.

### 1.2 Ce qui ne doit pas être dans un SRD

Aussi important que ce qui y est :

- **Pas de valeurs numériques de conception.** Le gain de 2 litres par compte
  est dans le SDD, pas dans le SRD : le changer ne change pas *ce que* le
  logiciel doit faire.
- **Pas de structure de code.** « Le composant doit appeler `Convert` avant
  `Consolidate` » n'est pas une exigence de haut niveau, c'est de la
  conception.
- **Pas de « le logiciel doit être fiable ».** Une exigence non vérifiable
  n'est pas une exigence. Le test qui la vérifierait doit pouvoir s'écrire au
  moment où on la lit.

Le SRD de ce module contient d'ailleurs une section **« Ce qui n'est PAS
ici »**. C'est une bonne pratique : elle évite qu'un relecteur croie à un
oubli.

### 1.3 Traçabilité bidirectionnelle

| Sens | Ce qu'il démontre | Ce qu'il révèle |
|---|---|---|
| exigence → code | tout ce qui était demandé est fait | exigences **non implémentées** |
| code → exigence | rien de plus que ce qui était demandé | **code non justifié** |

Le second sens est celui qu'on néglige, et c'est le plus utile : il trouve le
code mort, les fonctions ajoutées « au cas où », et les branches que personne
n'a demandées. C'est aussi lui qui donne son sens à l'analyse de couverture
structurelle du module 10.

### 1.4 L'outil : `tools/trace_check.py`

La matrice n'est pas un document tenu à la main : elle est **reconstruite**
à chaque exécution, depuis trois sources.

| Source | Ce qu'elle porte | Forme |
|---|---|---|
| `requirements/*.md` | les exigences | `### LLR-FQMSCAL-010` + champs |
| le code Ada | l'implémentation | `--  @satisfies LLR-FQMSCAL-010` |
| les tests | la vérification | `Testing.Start (Suite, "cas", "LLR-…")` |

Cinq défauts sont détectés, et le cinquième mérite d'être connu :

```
[1] LLR sans code                    -> non implémentée
[2] exigence sans vérification       -> non vérifiée
[3] code citant une exigence inconnue-> référence pourrie
[4] test sans exigence valide        -> test orphelin
[5] document citant un cas inexistant-> la matrice désigne du vide
```

Le défaut 5 attrape le cas le plus vicieux : le SRD cite
`` `Calibration.hlr_never_exceeds_capacity` `` dans son champ *Vérification*.
Si quelqu'un renomme ce cas de test, le document continue de citer un nom qui
n'existe plus. **La matrice a l'air complète et elle désigne du vide.**
Aucun humain ne rattrape ça de façon fiable ; un outil, si.

> **Ce que le harnais Ada change.** Le nom de la suite est déclaré une fois
> par fichier (`Suite : constant String := "Calibration";`) et chaque cas le
> reprend. `trace_check.py` lit les deux, avec une expression régulière
> tolérante aux retours à la ligne — parce que `gnatformat` a le droit de
> répartir un appel sur plusieurs lignes, et qu'un outil de traçabilité qui se
> casserait au premier reformatage ne servirait à rien.

### 1.5 Statut DO-330 de l'outil

Question systématique en entretien, et elle a une bonne réponse.

`trace_check.py` est un **outil de vérification** au sens du §12.2 : il ne
produit pas de code, il cherche des défauts. Un outil de vérification dont
l'échec laisserait passer un défaut relève du **TQL-5**, le niveau le moins
exigeant — *si* on lui donne du crédit.

Ici, on ne lui en donne pas : il est utilisé **en complément** de la revue
manuelle de la matrice, jamais à sa place. La qualification n'est donc pas
requise. Cette distinction — *crédit accordé ou non* — est exactement ce que
la DO-330 demande d'expliciter dans le plan. Le module 11 la traite en détail.

### 1.6 Deux familles de tests, et pourquoi elles sont séparées

La campagne de ce module distingue :

- les cas `hlr_*`, écrits depuis le **SRD**, sans regarder le code (table A-6,
  objectifs 1 et 2) ;
- les autres, écrits depuis le **SDD**, qui exercent les chemins internes
  (objectifs 3 et 4).

Sur un vrai programme, ces deux familles sont souvent confiées à des personnes
différentes : la table A-7 exige l'**indépendance** de la vérification au
DAL A et B. Ce n'est pas de la bureaucratie — quelqu'un qui a écrit le code
teste ce qu'il a écrit, pas ce qui était demandé.

### 1.7 Pourquoi pas AUnit ?

AUnit est le cadre de test d'AdaCore. Il existe comme *crate* Alire, il est
mûr, et un employeur peut le citer. Ce dépôt ne l'utilise pas, pour trois
raisons — et il vaut mieux les connaître que de les subir en entretien :

| | AUnit | Le harnais de `common/` |
|---|---|---|
| Dépendance | exige un `alire.toml` par projet | aucune |
| Mémoire | types étiquetés, allocation dynamique | rien de tout cela |
| Exigences | ne les connaît pas | l'identifiant est dans l'appel |

La troisième raison est décisive ici. `Testing.Start (Suite, "cas", "LLR-…")`
met l'identifiant d'exigence **dans le code exécuté**, ce qui rend la
traçabilité vérifiable par outil. Avec AUnit, il faudrait un tableau externe à
maintenir — et donc un cinquième document à ne pas laisser pourrir.

Le prix payé est de deux cents lignes à écrire et à maintenir. Sur un vrai
programme, cet arbitrage se poserait différemment : AUnit, plus un *wrapper*
qui porte l'identifiant, serait probablement le bon choix.

---

## 2. Les artefacts du module

| Fichier | Rôle DO-178C |
|---|---|
| [`requirements/srd.md`](requirements/srd.md) | *Software Requirements Data*, §11.9 — les HLR |
| [`requirements/sdd.md`](requirements/sdd.md) | *Design Description*, §11.10 — architecture et LLR |
| [`src/mod09-calibration.ads`](src/mod09-calibration.ads) | le code, annoté `@satisfies` |
| [`tests/test_calibration.adb`](tests/test_calibration.adb) | la campagne, deux familles |
| [`../../tools/trace_check.py`](../../tools/trace_check.py) | l'outil qui reconstruit la matrice |

Sortie actuelle : **8 exigences, 1 dérivée, 0 défaut**, et
`reports/tracabilite.csv` produit à chaque exécution de `verify.sh`.

---

## 3. Exercices

1. Renommer `consolidate_no_probe` en `consolidate_without_probe` **sans**
   toucher au SDD. Relancer `verify.sh trace` : quel défaut, et pourquoi
   aucun compilateur ne l'aurait vu ?
2. Ajouter une LLR au SDD sans écrire le `@satisfies` correspondant. Quel
   numéro de défaut ?
3. Retirer le champ `- **Parent** :` de `LLR-FQMSCAL-010`. Que devient-elle
   dans le rapport, et quelle obligation cela crée-t-il ?
4. Écrire l'exigence de haut niveau qui manque : que doit faire le composant
   quand les deux sondes divergent de plus de 10 % ? La tracer jusqu'au code
   et aux tests.
5. Rédiger la fiche de dérivation FD-001 citée par `HLR-FQMSCAL-004`, telle
   qu'elle serait transmise au processus de sécurité système.

---

## 4. Pour l'entretien

> **« Qu'est-ce qu'une exigence dérivée, et pourquoi est-ce important ? »**
> Une exigence qui ne remonte à aucune exigence de niveau supérieur : elle
> naît d'une décision de conception. La §5.1.2.h impose de l'identifier et de
> la remonter au processus de sécurité système, parce que personne d'autre n'a
> pu en évaluer l'effet. C'est le point où un logiciel introduit un
> comportement que le système n'avait pas demandé.

> **« Comment tenez-vous la matrice de traçabilité ? »**
> Je ne la tiens pas : elle est reconstruite par un outil depuis les exigences,
> les annotations `@satisfies` du code et les identifiants portés par les cas
> de test. L'outil signale cinq familles de défauts, dont les références
> documentaires périmées — le cas où la matrice a l'air complète et désigne du
> vide.

> **« Cet outil, il est qualifié ? »**
> Non, et il n'a pas à l'être : il est utilisé en complément de la revue
> manuelle, pas à sa place. Si on lui donnait du crédit pour éliminer cette
> revue, ce serait un outil de vérification TQL-5 au sens de la DO-330, avec
> ses exigences opérationnelles et ses propres tests. La question n'est jamais
> « l'outil est-il bon », c'est « quel crédit lui donne-t-on ».

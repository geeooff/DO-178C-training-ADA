# Plan de formation

> **Public** : développeur C# expérimenté, débutant en Ada.
> **Objectif** : être capable de tenir une conversation d'ingénieur sur
> Ada/SPARK et sur la DO-178C, et de le prouver par un dépôt qui tourne.
> **Durée** : environ 18 journées de travail effectif.

---

## Comment lire ce dépôt

Chaque module contient un `README.md` qui **est** le cours, du code qui
compile, une campagne de test qui passe, et — pour la plupart — des
obligations de preuve déchargées. Rien n'y est affirmé sans avoir été exécuté.

Trois règles de lecture :

1. **Lancer avant de lire.** `./scripts/verify.sh` d'abord ; le cours prend
   son sens quand on a vu la sortie.
2. **Faire les exercices.** Ils sont conçus pour *casser* le code et lire ce
   que l'outil répond. C'est là que l'apprentissage se fait.
3. **Lire les commentaires du code.** Ils portent le *pourquoi* — objectif
   DO-178C, accident historique, arbitrage — pas le *quoi*.

---

## Le parcours

| # | Module | Journées | Ce qu'on en retire |
|---|---|---|---|
| 00 | [environnement](../modules/00-environnement/) | 0,5 | le SECI conteneurisé, et pourquoi il est le document §11.15 |
| 01 | [types et contraintes](../modules/01-types-et-contraintes/) | 1 | la borne est dans le type ; Mars Climate Orbiter |
| 02 | [vérifications à l'exécution](../modules/02-verifications-execution/) | 1 | ce que GNAT ajoute, ce que ça coûte, ce que la suppression oblige |
| 03 | [contrats Ada 2022](../modules/03-contrats-ada-2022/) | 1 | le contrat remplace la défense |
| 04 | [SPARK — analyse de flot](../modules/04-spark-analyse-de-flot/) | 1 | le couplage données/contrôle devient une sortie d'outil |
| 05 | [SPARK — preuve, DO-333](../modules/05-spark-preuve-do333/) | 2 | ce que la preuve crédite, et ce qu'elle ne voit pas |
| 06 | [erreurs sans exceptions](../modules/06-erreurs-sans-exceptions/) | 1 | interdire les exceptions oblige à prouver ; Ariane 501 |
| 07 | [mémoire statique](../modules/07-memoire-statique/) | 1,5 | pas de tas, Ravenscar, analyse de pile |
| 08 | [objet et DO-332](../modules/08-objet-do332/) | 1 | Liskov devient une obligation de preuve |
| 09 | [exigences et traçabilité](../modules/09-exigences-tracabilite/) | 1,5 | la matrice se reconstruit, elle ne se tient pas |
| 10 | [couverture et crédit de preuve](../modules/10-couverture-et-preuve/) | 1,5 | 100 % de décisions ne veut rien dire sans son niveau |
| 11 | [standards et qualification](../modules/11-standards-qualification/) | 1 | la bonne question n'est pas « l'outil est-il bon » |
| 12 | [projet intégré FQMS](../modules/12-projet-integre/) | 3 | le même système DAL B qu'en C++, mêmes exigences |

**Total : environ 18 journées.**

---

## Trois façons de parcourir

### Parcours complet — 18 jours

Dans l'ordre. Chaque module suppose les précédents.

### Parcours « langage » — 8 jours

Modules 00 à 08. On en sort capable d'écrire de l'Ada/SPARK correct et de
comprendre ce que la preuve apporte. Il manque tout le processus.

### Parcours « certification » — 7 jours

Modules 00, 09, 10, 11, 12. Pour quelqu'un qui connaît déjà un langage
embarqué et veut le vocabulaire et les artefacts de la DO-178C. Le module 12
demande d'avoir lu au moins 01 à 05 en diagonale.

---

## Ce que ce dépôt ne couvre pas

Dit une fois, clairement, plutôt que découvert en entretien :

| Sujet | Pourquoi |
|---|---|
| Tests sur cible réelle | demande le matériel |
| Couverture du **code objet** (A-7.7) | demande un émulateur ou une sonde |
| Analyse **WCET** réelle | demande la cible et son cache |
| Multicœur, CAST-32A | hors périmètre d'un dépôt d'apprentissage |
| DO-331 (SCADE, Simulink) | cité au module 05, non traité |
| Rédaction complète des plans (PSAC, SDP, SVP…) | des extraits seulement |
| Relation avec l'autorité de certification | ne s'apprend pas dans un dépôt |

Ces sujets sont **cités** là où ils s'insèrent, avec ce qu'il faut pour en
parler juste. Ils ne sont pas traités.

---

## Le dépôt frère

[`../DO-178C-training`](../../DO-178C-training/) traite la même démarche en
**C++17**, avec le **même cas d'étude FQMS** et les **mêmes exigences de haut
niveau**.

Les deux dépôts pris ensemble valent plus que la somme des deux : ils montrent
ce qui relève du processus — et ne bouge pas — et ce qui relève du langage.
C'est le sujet du [module 12](../modules/12-projet-integre/).

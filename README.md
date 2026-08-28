# DO-178C — auto-formation Ada / SPARK

Support d'auto-formation d'un développeur **C#** à **Ada / SPARK** et à
l'impact de la **DO-178C** sur la façon de développer. Ce n'est pas un
produit : c'est un cours qu'on peut compiler, exécuter, prouver et mesurer.

**Rien n'y est affirmé sans avoir été exécuté.**

| | |
|---|---|
| Modules | **13**, du SECI au projet intégré |
| Campagnes de test | **106 cas, 222 vérifications, 0 échec** |
| Preuve SPARK | **253 obligations déchargées**, 1 justifiée |
| Couverture | **100 %** instructions, décisions et MC/DC sur le code sous test |
| Traçabilité | **0 défaut**, matrice reconstruite par outil |
| Avertissements de compilation | **0**, traités en erreurs |

---

## Le dépôt frère

[`../DO-178C-training`](../DO-178C-training) traite la même démarche en
**C++17**. Les deux dépôts partagent le **même cas d'étude** — un système de
jaugeage carburant **FQMS**, DAL B — contre les **mêmes exigences de haut
niveau**, énoncé pour énoncé.

L'intérêt est là : *le processus est la constante, le langage est la
variable*. Voir le [module 12](modules/12-projet-integre/), qui met les deux
implémentations en regard.

Ce dépôt-ci se lit néanmoins **seul** : il ne suppose connu ni le C++, ni le
dépôt frère.

---

## Ce que la chaîne Ada permet et que le C++ ne permettait pas

| | Dépôt C++ | Ce dépôt |
|---|---|---|
| Couverture | lignes et branches (`gcovr`) | instructions, décisions, **MC/DC** (`gnatcov`) |
| Absence d'erreur à l'exécution | argumentée, revue | **prouvée** (`gnatprove`, DO-333) |
| Couplage données/contrôle | tableau tenu à la main | `Global` / `Depends`, **vérifiés par l'outil** |
| Interdiction des exceptions | convention de codage | `pragma Restrictions`, vérifié à l'édition de liens |
| Absence d'allocation | revue | `pragma Restrictions`, vérifié |
| Qualification d'outil | `clang-tidy`, qualifié pour rien | **kit DO-330 réel** pour GNATcoverage |

---

## Démarrer

Le protocole ne se lance pas sur le poste : il se lance **dans le SECI**.
C'est ce qui rend le résultat reproductible, donc opposable.

```bash
docker build -t do178c-ada:verif .devcontainer
```

```bash
docker run --rm -v "$PWD:/workspace" do178c-ada:verif ./scripts/verify.sh
```

```bash
docker run --rm -v "$PWD:/workspace" do178c-ada:verif ./scripts/coverage.sh
```

VS Code ouvre directement le dépôt dans ce conteneur (*Reopen in Container*).

`verify.sh` enchaîne compilation, exécution, preuve SPARK, traçabilité et
formatage. Il accepte une étape isolée : `./scripts/verify.sh prove`.

---

## Le parcours

| # | Module | Ce qu'on en retire |
|---|---|---|
| 00 | [environnement](modules/00-environnement/) | le SECI conteneurisé, et pourquoi il est le document §11.15 |
| 01 | [types et contraintes](modules/01-types-et-contraintes/) | la borne est dans le type, pas dans les gardes |
| 02 | [vérifications à l'exécution](modules/02-verifications-execution/) | ce que GNAT ajoute, ce que ça coûte, ce que la suppression oblige |
| 03 | [contrats Ada 2022](modules/03-contrats-ada-2022/) | le contrat remplace la programmation défensive |
| 04 | [SPARK — analyse de flot](modules/04-spark-analyse-de-flot/) | le couplage données/contrôle devient une sortie d'outil |
| 05 | [SPARK — preuve, DO-333](modules/05-spark-preuve-do333/) | ce que la preuve crédite, et ce qu'elle ne voit pas |
| 06 | [erreurs sans exceptions](modules/06-erreurs-sans-exceptions/) | interdire les exceptions **oblige** à prouver |
| 07 | [mémoire statique](modules/07-memoire-statique/) | pas de tas, Ravenscar, analyse de pile |
| 08 | [objet et DO-332](modules/08-objet-do332/) | Liskov devient une obligation de preuve |
| 09 | [exigences et traçabilité](modules/09-exigences-tracabilite/) | la matrice se reconstruit, elle ne se tient pas |
| 10 | [couverture et crédit de preuve](modules/10-couverture-et-preuve/) | « 100 % de couverture » ne veut rien dire |
| 11 | [standards et qualification](modules/11-standards-qualification/) | la bonne question n'est pas « l'outil est-il bon » |
| 12 | [projet intégré FQMS](modules/12-projet-integre/) | le même système DAL B qu'en C++, mêmes exigences |

Plan détaillé et parcours abrégés : [`docs/00-plan-de-formation.md`](docs/00-plan-de-formation.md).

---

## Cinq chiffres que ce dépôt a mesurés

Aucun n'est une estimation, et chacun se rejoue d'une commande.

| Chiffre | Ce qu'il dit | Où |
|---|---|---|
| **13 %** | surcoût en `.text` des vérifications à l'exécution | [module 02](modules/02-verifications-execution/) |
| **55 %** | MC/DC d'une campagne, sur du code dont **28 obligations sur 28** étaient prouvées | [module 05](modules/05-spark-preuve-do333/) |
| **33 %** | MC/DC atteint par deux cas de test qui donnent **100 % de couverture de décisions** | [module 10](modules/10-couverture-et-preuve/) |
| **4 sur 10** | violations du standard de codage attrapées par le compilateur ; six restent à la revue | [module 11](modules/11-standards-qualification/) |
| **44 → 35** | instructions du FQMS après correction des écarts : le composant a **maigri** en gagnant en couverture | [module 12](modules/12-projet-integre/) |

---

## Chaîne d'outils

Toutes les versions sont épinglées dans
[`.devcontainer/Dockerfile`](.devcontainer/Dockerfile), qui tient lieu de
**SECI** exécutable (DO-178C §11.15).

| Outil | Version | Rôle |
|---|---|---|
| GNAT (`gnat_native`) | 16.1.0 | compilateur Ada 2022 |
| `gprbuild` | 26.0.1 | construction |
| `gnatprove` (SPARK) | 16.1.0 (Why3 1.8.2, CVC5) | preuve formelle |
| `gnatcov` | 26.2.1 | couverture structurelle, jusqu'au MC/DC |
| `gnatformat` | 26.0.0 | formatage |
| Alire (`alr`) | 2.1.1 | installation de la chaîne |

Détails, pièges vérifiés et statut DO-330 de chaque outil :
[`docs/03-outils.md`](docs/03-outils.md).

### Pourquoi le binaire Alire et non le paquet Ubuntu

`alire` **existe** dans l'univers Ubuntu 26.04, en version `1.2.1`. Mais cette
version n'accepte que la branche d'index figée `stable-1.2.1`, de 2023 :

| Voie | `alr` | Index | `gnatprove` accessible |
|---|---|---|---|
| apt `universe` | 1.2.1 | `stable-1.2.1` | **13.2.1** au mieux |
| binaire amont | 2.1.1 | `stable-1.4.0` | **16.1.0** |

---

## Organisation du dépôt

```
.devcontainer/   le SECI : Dockerfile à versions épinglées
common/          le harnais de test, deux cents lignes, sans allocation
docs/            plan, glossaire, C# vers Ada, outils, entretien, ressources
modules/         les treize modules
  NN-.../
    README.md          le cours
    src/               le code, annoté @satisfies
    tests/             la campagne
    requirements/      SRD et SDD, là où la traçabilité s'applique
scripts/         verify, coverage, format, et trois scripts de mesure
templates/       gabarits de revue, fiches d'anomalie et de déviation
tools/           trace_check.py, config_index.py
shared.gpr       les commutateurs de compilation, écrits une seule fois
```

---

## Documents transverses

| Document | Contenu |
|---|---|
| [`docs/00-plan-de-formation.md`](docs/00-plan-de-formation.md) | le parcours, et **ce que le dépôt ne couvre pas** |
| [`docs/01-glossaire.md`](docs/01-glossaire.md) | sigles de certification et termes Ada/SPARK |
| [`docs/02-csharp-vers-ada.md`](docs/02-csharp-vers-ada.md) | les réflexes C# à désapprendre |
| [`docs/03-outils.md`](docs/03-outils.md) | la chaîne, ses pièges, son statut DO-330 |
| [`docs/04-entretien.md`](docs/04-entretien.md) | les questions, et des réponses chiffrées |
| [`docs/05-ressources.md`](docs/05-ressources.md) | normes, livres, et le marché français |

---

## Convention de langue

Identifiants Ada, noms de cas de test et de suites : **anglais**, pour coller
à ce qui se lit chez les donneurs d'ordre. Commentaires, documentation,
exigences et messages de commit : **français**, parce que le lecteur visé
apprend plus vite dans cette langue.

Le style est `Mixed_Case_With_Underscores`, conforme au style GNAT et vérifié
par `gnatformat`.

---

## Hors périmètre, assumé

Tests sur cible réelle, couverture du **code objet** (A-7.7), analyse **WCET**
réelle, multicœur (CAST-32A), **DO-331** (SCADE, Simulink), rédaction complète
des plans, relation avec l'autorité de certification.

Ces sujets sont **cités** là où ils s'insèrent, avec ce qu'il faut pour en
parler juste. Ils ne sont pas traités, et le dire fait partie du travail.

---

## Licence

| Contenu | Licence |
|---|---|
| **Code** — `common/`, `modules/*/{src,tests}`, `tools/`, `scripts/` | [MIT](LICENSE) |
| **Documentation** — README, `docs/`, `modules/*/README.md`, `requirements/`, `templates/` | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |

Deux licences parce que ce dépôt contient deux natures d'objets. MIT est
rédigée pour du logiciel ; l'essentiel de la valeur est ici du support de
formation, que CC BY 4.0 couvre correctement. Dans les deux cas : réutilisation
libre, y compris commerciale, à condition de citer l'auteur.

Le dépôt ne contient **aucun code tiers** : le harnais de test de `common/` est
écrit pour l'occasion, et la seule dépendance externe est la chaîne d'outils
elle-même, installée dans l'image.

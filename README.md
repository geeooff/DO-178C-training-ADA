# DO-178C — auto-formation Ada / SPARK

Support d'auto-formation d'un développeur **C#** à **Ada / SPARK** et à
l'impact de la **DO-178C** sur la façon de développer. Ce n'est pas un
produit : c'est un cours qu'on peut compiler, exécuter, prouver et mesurer.

> **En construction.** Ce README ne décrit que ce qui est **vérifié**
> aujourd'hui. Les modules de cours restent à écrire ; leur découpage n'est
> pas arrêté.

## Le dépôt frère

[`../DO-178C-training`](../DO-178C-training) traite la même démarche en
**C++17** : 17 modules, 19 campagnes de test, CI verte. Les deux dépôts
partagent le même cas d'étude — un système de jaugeage carburant **FQMS**,
DAL B — contre les **mêmes exigences** et la **même matrice de traçabilité**.

L'intérêt est là : *le processus est la constante, le langage est la
variable*. Ce dépôt-ci se lit néanmoins **seul** ; il ne suppose connu ni le
C++, ni le dépôt frère.

## Ce que la chaîne Ada permet et que le C++ ne permettait pas

| | Dépôt C++ | Ce dépôt |
|---|---|---|
| Couverture | lignes et branches (`gcovr`) | statements, décisions et **MC/DC** (`gnatcov`) |
| Absence d'erreur à l'exécution | argumentée, revue | **prouvée** (`gnatprove`, DO-333) |
| Contrats | assertions et revue | `Pre` / `Post` / `Type_Invariant`, vérifiés par preuve |

Le MC/DC est l'objectif de couverture du **DAL A** (DO-178C, tableau A-7,
objectif 5). Le mesurer pour de vrai, plutôt que d'en parler, est la première
raison d'être de ce dépôt.

## Chaîne d'outils — vérifiée le 2026-08-28

Toutes les versions sont épinglées dans
[`.devcontainer/Dockerfile`](.devcontainer/Dockerfile), qui tient lieu de
**SECI** exécutable (*Software Life Cycle Environment Configuration Index*,
DO-178C §11.15).

| Outil | Version | Rôle |
|---|---|---|
| GNAT (`gnat_native`) | 16.1.0 | compilateur Ada 2022 |
| `gprbuild` | 26.0.1 | construction |
| `gnatprove` (SPARK) | 16.1.0 (Why3 1.8.2, CVC5) | preuve formelle |
| `gnatcov` | 26.2.1 | couverture structurelle, jusqu'au MC/DC |
| `gnatformat` | 26.0.0 | formatage |
| Alire (`alr`) | 2.1.1 | installation de la chaîne |

### Pourquoi le binaire Alire et non le paquet Ubuntu

`alire` **existe** dans l'univers Ubuntu 26.04 (`resolute/universe`), en
version `1.2.1-2.1build1`. Mais cette version n'accepte que la branche d'index
figée `stable-1.2.1`, datée de 2023 :

| Voie | `alr` | Index | `gnatprove` accessible |
|---|---|---|---|
| apt `universe` | 1.2.1 | `stable-1.2.1` | **13.2.1** au mieux |
| binaire amont | 2.1.1 | `stable-1.4.0` | **16.1.0** |

L'apt fournit par ailleurs GNAT 14.3 : la chaîne obtenue serait dépareillée,
un `gnatprove` de 2023 devant analyser du code compilé par un GNAT de 2026.
D'où le binaire amont, épinglé dans l'image.

## Vérifier

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

`verify.sh` enchaîne compilation (avertissements traités en erreurs),
exécution des programmes témoins, preuve SPARK et contrôle de formatage. Il
accepte une étape isolée : `./scripts/verify.sh prove`.

VS Code ouvre directement le dépôt dans ce conteneur
(*Reopen in Container*) : [`.devcontainer/`](.devcontainer/) contient tout.

### État actuel

Sur le module témoin `00-environnement`, dans l'image ci-dessus :

- **0** avertissement de compilation ;
- **4/4** vérifications prouvées par CVC5 ;
- **0** écart de formatage ;
- **100 %** statements, décisions et **MC/DC**.

## Convention de langue

Identifiants Ada, noms de cas de test et de suites : **anglais**, pour coller
à ce qui se lit chez les donneurs d'ordre. Commentaires, documentation,
exigences et messages de commit : **français**, parce que le lecteur visé
apprend plus vite dans cette langue.

Le style Ada est `Mixed_Case_With_Underscores` (`Fuel_System`,
`Saturating_Add`), conforme au style GNAT et vérifié par `gnatformat`.

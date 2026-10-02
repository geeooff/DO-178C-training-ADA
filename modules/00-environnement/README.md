# Module 00 — Environnement, SECI et vue d'ensemble de la DO-178C

> **Durée estimée** : 1 journée
> **Prérequis** : savoir programmer en C#, avoir Docker. Rien d'autre — ni
> Ada, ni C++, ni DO-178C. Les sigles du métier sont dans le
> [glossaire](../../docs/01-glossaire.md).

> **Avant de lire.** Lancez dès maintenant la construction de l'environnement,
> qui prend plusieurs minutes la première fois, et lisez la partie 1
> pendant qu'elle tourne :
>
> ```bash
> docker build -t do178c-ada:verif .devcontainer
> ```

---

## Objectifs pédagogiques

1. Lancer le protocole de vérification complet du dépôt dans son
   environnement, et lire ce qu'il répond.
2. Situer la DO-178C : ce qu'elle est et n'est pas, les niveaux **DAL**, les
   processus, les tables d'objectifs, les suppléments.
3. Expliquer ce qu'est le **SECI** (§11.15) et pourquoi ce dépôt en fait une
   image exécutable plutôt qu'un document.
4. Distinguer, dans un environnement de construction, ce qui est **épinglé**
   et ce qui est seulement **tracé** — et dire pourquoi.
5. Lire un fichier de projet GNAT (`.gpr`) en le rapprochant d'un `.csproj`.

---

## 1. Le cours

### 1.1 La DO-178C : ce qu'elle est, et ce qu'elle n'est pas

La **DO-178C** — *Software Considerations in Airborne Systems and Equipment
Certification*, publiée en 2011 par la RTCA, ED-12C chez EUROCAE — est le
document que la FAA (AC 20-115D) et l'EASA (AMC 20-115D) reconnaissent comme
moyen acceptable de démontrer la conformité du logiciel embarqué.

Elle n'est **pas** :

- une méthode de développement : elle n'impose ni cycle en V, ni agilité, ni
  modèles ;
- un standard de codage : elle exige, aux niveaux A à C, d'**en avoir un**
  (§11.8), sans dire lequel — c'est le sujet du
  [module 11](../11-standards-qualification/) ;
- un système de management de la qualité au sens d'ISO 9001 — EN 9100 en
  aéronautique : elle porte sur un logiciel donné, pas sur l'organisation.

C'est une liste d'**objectifs**. Pour chacun, la norme dit à quel niveau il
s'applique, s'il doit être satisfait avec **indépendance** — le vérificateur
n'est pas l'auteur —, et quelles **données de vie du logiciel** (§11) en
apportent la preuve.

> **Le renversement à faire en venant de C#.** Un code excellent sans preuve
> tracée ne passe pas. Un code ordinaire, mais exigé, tracé, revu, testé et
> couvert, passe. La norme ne juge pas le code : elle juge la démonstration.

### 1.2 Les niveaux : le DAL

Le niveau logiciel — *software level* dans la DO-178C, couramment appelé
**DAL** (*Development Assurance Level*, IDAL dans l'ARP4754B) — n'est pas
choisi par l'équipe logicielle. Il est alloué par l'analyse de sécurité du
**système** (ARP4754B, ARP4761A), à partir de l'effet qu'aurait une
défaillance du logiciel.

| DAL | Condition de panne | Objectifs | Couverture structurelle exigée |
|---|---|---:|---|
| **A** | catastrophique | 71 | instructions, décisions, **MC/DC**, couplage de données et de contrôle ; plus la vérification du code objet sans équivalent source |
| **B** | dangereuse | 69 | instructions, décisions, couplage |
| **C** | majeure | 62 | instructions, couplage |
| **D** | mineure | 26 | aucune |
| **E** | sans effet sur la sécurité | — | la DO-178C ne demande rien |

Le **MC/DC** — *Modified Condition/Decision Coverage* — demande que chaque
condition d'une décision ait montré, seule, qu'elle pouvait en faire basculer
le résultat ; le [module 10](../10-couverture-et-preuve/) le mesure et montre
où il diverge de la couverture de décisions. Le *couplage de données et de
contrôle* — qui lit quoi, qui appelle qui — est l'objet du
[module 04](../04-spark-analyse-de-flot/). Le *code objet sans équivalent
source* est ce que le compilateur ajoute sans que le source l'écrive : au DAL
A, la norme en demande une vérification à part, et le
[module 02](../02-verifications-execution/) en traite.

Le nombre d'objectifs à satisfaire avec indépendance croît avec le niveau —
une trentaine au DAL A, une vingtaine au DAL B. Le décompte exact varie d'une
source à l'autre, et le [glossaire](../../docs/01-glossaire.md) le rappelle :
ne pas l'affirmer à l'unité.

Le cas d'étude de ce dépôt, le jaugeage carburant FQMS du
[module 12](../12-projet-integre/), est **DAL B**, et son SRD dit pourquoi.

### 1.3 Les processus

La norme est rangée par processus, et ses numéros de section reviennent
partout :

| § | Processus | Dans ce dépôt |
|---|---|---|
| 4 | planification — les plans (PSAC, SDP, SVP, SCMP, SQAP), l'environnement (§4.4), les standards (§4.5) | les plans sont cités seulement ; l'environnement est le sujet de ce module, les standards celui du module 11 |
| 5 | développement — exigences, conception, codage, intégration | exigences de haut niveau (SRD) et de bas niveau (SDD) des modules 09, 10 et 12 ; le code |
| 6 | vérification — revues, analyses, tests | campagnes, preuves, couverture, traçabilité, gabarits de revue |
| 7 | gestion de configuration | Git, SCI et SECI, fiches d'anomalie |
| 8 | assurance qualité | hors périmètre : un dépôt à un seul auteur ne s'audite pas lui-même |
| 9 | liaison avec la certification | hors périmètre |

Le §11 décrit les données de vie que ces processus produisent ; le §12, les
considérations additionnelles, dont la qualification des outils (§12.2).

### 1.4 Les tables d'objectifs de l'annexe A

C'est le cœur opérationnel de la norme : dix tables, citées partout dans le
métier. Chacune donne ses objectifs, le niveau à partir duquel ils
s'appliquent, et la catégorie de contrôle de configuration de chaque donnée
produite.

| Table | Ce qu'elle couvre | Modules |
|---|---|---|
| A-1 | la planification — dont l'environnement et les standards | 00, 11 |
| A-2 | le développement | 09, 12 |
| A-3 | la vérification des exigences de haut niveau (HLR) | 01, 09 |
| A-4 | la vérification des exigences de bas niveau (LLR) et de l'architecture | 01, 03, 09 |
| A-5 | la vérification du code source | 01, 05, 07, 11 |
| A-6 | la vérification de l'exécutable, par les tests | toutes les campagnes |
| A-7 | la vérification de la vérification : couverture des exigences et du code, couplage | 02, 04, 05, 10 |
| A-8 | la gestion de configuration | 00, 11 |
| A-9 | l'assurance qualité | — |
| A-10 | la liaison avec la certification | — |

On désigne un objectif par sa table et son rang : A-7.5 est le MC/DC, A-7.7
la couverture d'instructions, A-7.8 le couplage de données et de contrôle,
A-7.9 la vérification du code ajouté par le compilateur sans équivalent
source. Les citer juste fait partie du métier ; vérifier un numéro
avant de l'écrire aussi — la revue de publication de ce dépôt en a corrigé
plusieurs.

### 1.5 La DO-330 et les trois suppléments

| Document | Sujet | Module |
|---|---|---|
| **DO-330** | qualification des outils — un document autonome, pas un supplément | 11 |
| DO-331 | développement à base de modèles : SCADE, Simulink | hors périmètre |
| **DO-332** | technologies orientées objet | 08 |
| **DO-333** | méthodes formelles | 05, 10 |

Les trois suppléments complètent ou modifient les objectifs de la DO-178C
quand la technologie correspondante est employée. La DO-333 est la raison
d'être de ce dépôt : c'est elle qui permet de faire valoir une preuve **SPARK**
à la place de certains tests. SPARK est un sous-ensemble d'Ada, plus des
annotations, que l'outil `gnatprove` sait prouver ; les modules 04 et 05 en
traitent.

### 1.6 Le SECI : ce que demande le §11.15

Le **SECI** — *Software Life Cycle Environment Configuration Index* —
identifie l'environnement qui a **produit et vérifié** le logiciel : système
hôte, compilateur et éditeur de liens avec leurs versions et leurs options,
outils de vérification, outils qualifiés. Il est **CC1** — le contrôle de
configuration le plus strict — aux niveaux A, B et C, et CC2 au niveau D
(table A-8). Son voisin, le **SCI** (§11.16), identifie ce qui **constitue**
le logiciel, et il est CC1 à tous les niveaux. Le
[module 11](../11-standards-qualification/) reprend les deux sous l'angle de
la gestion de configuration.

Pourquoi tant d'exigence : changer de version de compilateur peut changer le
code objet, donc invalider des résultats de vérification déjà obtenus — la
couverture structurelle en premier. Un programme certifié garde souvent le
même compilateur pendant toute la vie du produit. Ce n'est pas de la
négligence : c'est de la gestion de configuration.

### 1.7 Une image plutôt qu'un document

Un SECI écrit à la main se périme : quelqu'un met à jour le compilateur,
personne ne met à jour le document. Ce dépôt prend le problème à l'envers :
le SECI **est** [`.devcontainer/Dockerfile`](../../.devcontainer/Dockerfile).
Chaque version y est écrite une fois, et l'image qui en sort est
l'environnement dans lequel tout est compilé, exécuté, prouvé et mesuré — sur
le poste comme en CI.

Deux conséquences :

- **la CI ne réinstalle rien.** Elle construit l'image et lance la
  vérification dedans. Réinstaller la chaîne dans le workflow donnerait deux
  descriptions de l'environnement, qui divergeraient au premier oubli ;
- **le document SECI est régénéré** à chaque exécution de la CI — et à la
  demande — par [`tools/config_index.py`](../../tools/config_index.py), qui
  lit les versions déclarées dans le Dockerfile et interroge les outils
  réellement présents. Un écart de version majeure ou mineure entre les deux
  est écrit en toutes lettres dans le document — c'est l'exercice 2. Le
  correctif, lui, n'est pas comparé : `gprbuild` s'annonce 26.0.0 alors que
  la crate qui l'installe est 26.0.1, et le SECI le dit.

### 1.8 Épinglé, tracé

| | Comment | Exemples |
|---|---|---|
| **Épinglé** — la chaîne Ada et l'image de base | une valeur exacte dans le Dockerfile ; en changer est un commit à part, suivi d'une vérification complète | `ARG GNATPROVE_VERSION=16.1.0`, `FROM ubuntu:resolute@sha256:…` |
| **Tracé** — ce qui construit l'image | consigné à chaque exécution dans le journal de CI et dans le SECI | image du runner GitHub, buildx, BuildKit |
| **Pas encore épinglé** | dit dans le Dockerfile et dans [`docs/03-outils.md`](../../docs/03-outils.md) §5 | paquets apt, archive d'Alire |

Une version de crate Alire, comme `GNATPROVE_VERSION`, vaut épinglage : l'index
Alire consigne l'empreinte SHA-256 de chaque archive. Ce qu'on ne peut pas
épingler — l'image du runner GitHub — on le trace. Ce qu'on pourrait figer
sans que personne n'en surveille la version — BuildKit, dans le workflow — on
le trace aussi : une version épinglée que rien ne suit est une dette, pas une
maîtrise.

> **Une étiquette n'est pas une version.** Jusqu'au 2 octobre 2026, le
> Dockerfile commençait par `FROM ubuntu:26.04`. Les journaux de CI montrent
> que, sur cette même ligne, la CI a construit sur **trois** images
> différentes en cinq semaines : Canonical repose l'étiquette à chaque
> rafraîchissement. Le dépôt affirmait pourtant que ses versions étaient
> épinglées. L'image est désormais désignée par son **digest** — l'empreinte
> SHA-256 de son contenu —, sous le nom de code `resolute` plutôt que `26.04`
> pour que Dependabot en propose les nouveaux digests ; le commentaire du
> Dockerfile dit pourquoi.
>
> La leçon tient en une ligne : **un nom n'est pas un contenu**, et un SECI
> doit désigner des contenus.

### 1.9 La chaîne Ada, vue depuis C#

| Outil | Rôle | Équivalent C# approximatif |
|---|---|---|
| GNAT 16.1 (`gnat_native`) | compilateur Ada 2022 | Roslyn, `csc` |
| `gprbuild` | construction à partir des fichiers `.gpr` | `dotnet build`, MSBuild |
| `gnatprove` | analyse de flot et preuve SPARK | aucun — c'est ce qu'Ada apporte |
| `gnatcov` | couverture structurelle, jusqu'au MC/DC | coverlet, sans le MC/DC |
| `gnatformat` | vérification du formatage | `dotnet format --verify-no-changes` |
| Alire (`alr`) | installe la chaîne dans l'image, et s'arrête là | NuGet, mais hors de la construction |

Versions, rôle exact et statut DO-330 de chaque outil :
[`docs/03-outils.md`](../../docs/03-outils.md).

**Les fichiers de projet.** Un `.gpr` est le pendant d'un `.csproj`, et le
dépôt en compte trois sortes :

- [`shared.gpr`](../../shared.gpr) — un projet **abstrait**, qui ne produit
  rien et ne sert qu'à être hérité. Les commutateurs de compilation et de
  preuve y sont écrits **une seule fois**, comme dans un
  `Directory.Build.props` ;
- [`common/common.gpr`](../../common/common.gpr) — la bibliothèque statique du
  harnais de test ;
- un `modNN.gpr` par module, qui hérite de tout :

```ada
with "../../shared.gpr";
with "../../common/common.gpr";

project Mod00 is
   for Source_Dirs use ("src", "tests");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("main.adb", "test_fuel.adb");

   package Compiler renames Shared.Compiler;
   package Prove renames Shared.Prove;
end Mod00;
```

`package Compiler renames Shared.Compiler` ne copie pas les commutateurs : il
**désigne** ceux de `shared.gpr`. Un module ne peut pas compiler avec des
règles plus douces sans que le renommage disparaisse, ce qui se voit en revue.
Les commutateurs qui comptent : `-gnatwa -gnatwe`, tous les avertissements
utiles traités en erreurs — le pendant de `TreatWarningsAsErrors` —, `-gnata`,
les contrats vérifiés aussi à l'exécution, et, côté preuve,
`--checks-as-errors=on`, sans lequel `gnatprove` sort avec le code 0 même sur
du code non prouvé.

Pas d'`alire.toml` : les donneurs d'ordre lisent des `.gpr`, et Alire n'a pas
à être dans la boucle de construction. Il installe la chaîne dans l'image,
c'est tout.

---

## 2. Manipulation

Une fois l'image construite, lancer le protocole complet — compilation,
exécution des campagnes, preuve, traçabilité, formatage. Depuis un shell Linux
ou WSL :

```bash
docker run --rm -v "$PWD:/workspace" do178c-ada:verif ./scripts/verify.sh
```

La même ligne demande deux retouches ailleurs, vérifiées l'une et l'autre :
sous **PowerShell**, écrire `"${PWD}:/workspace"`, sans quoi PowerShell lit
`$PWD:` comme un nom de variable ; sous **Git Bash**, préfixer la commande par
`MSYS_NO_PATHCONV=1`, sans quoi le chemin `/workspace` est réécrit en chemin
Windows et le conteneur ne voit pas le dépôt. Sur un hôte Linux dont
l'utilisateur n'a pas l'uid 1000, ajouter `--user "$(id -u):$(id -g)" -e
HOME=/tmp`, comme le fait la CI.

Une étape seule se lance en la nommant : `build`, `run`, `prove`, `trace` ou
`format`, par exemple `./scripts/verify.sh prove`. La couverture se mesure à
part :

```bash
docker run --rm -v "$PWD:/workspace" do178c-ada:verif ./scripts/coverage.sh
```

VS Code ouvre le dépôt directement dans ce conteneur (*Reopen in Container*),
avec l'extension Ada d'AdaCore. C'est la façon la plus simple de travailler
les exercices : tout s'y lance depuis le terminal intégré.

Pour ce module, trois résultats suffisent : la campagne
`Fuel : 3 cas, 5 verifications, 0 echec(s).`, les quatre messages `info:` de
`gnatprove` pour `mod00.gpr` — le décompte est dans
`modules/00-environnement/obj/gnatprove/gnatprove.out` —, et la couverture de
`mod00-fuel.adb`.

---

## 3. Le code du module

Il est volontairement minuscule : un fragment du FQMS, juste assez pour que
chaque outil de la chaîne ait quelque chose de non trivial à faire. Le module
00 ne prouve pas que le code est intéressant ; il prouve que **la chaîne
fonctionne**.

| Fichier | Contenu |
|---|---|
| [`mod00.gpr`](mod00.gpr) | le projet, qui hérite des commutateurs de `shared.gpr` |
| [`src/mod00.ads`](src/mod00.ads) | le paquetage racine, vide : un espace de noms |
| [`src/mod00-fuel.ads`](src/mod00-fuel.ads) | le sous-type `Litres` et `Saturating_Add`, avec sa postcondition |
| [`src/mod00-fuel.adb`](src/mod00-fuel.adb) | le corps, et les deux contrôles de plage que la preuve décharge |
| [`src/main.adb`](src/main.adb) | l'exécutable témoin, qui passe par les deux branches |
| [`tests/test_fuel.adb`](tests/test_fuel.adb) | la campagne : trois cas, dont un de robustesse |

Une *postcondition* est un contrat : ce que la fonction garantit à son
appelant. Une *obligation de preuve* est une propriété que `gnatprove` doit
démontrer — qu'un contrôle ne peut pas échouer, qu'une postcondition est
toujours vraie. Le [module 03](../03-contrats-ada-2022/) et le
[module 05](../05-spark-preuve-do333/) les développent.

Ce que chaque outil en dit, mesuré :

| Outil | Résultat |
|---|---|
| `gprbuild` | compile sans avertissement sous `-gnatwa -gnatwe` |
| campagne | `Fuel : 3 cas, 5 verifications, 0 echec(s).` |
| `gnatprove` | 4 obligations déchargées : deux contrôles de plage, la postcondition, la terminaison |
| `gnatcov` | `mod00-fuel.adb` : 100 % des instructions, des décisions et du MC/DC — sur une décision à une seule condition, MC/DC et décisions coïncident ; le module 10 montre où ils divergent |
| `gnatformat` | conforme |

### Exigence du module

| Id | Exigence | Vérifiée par |
|---|---|---|
| LLR-M00-001 | `Saturating_Add` doit rendre la somme de ses deux opérandes si elle ne dépasse pas `Max_Litres`, et `Max_Litres` sinon. | `Fuel.saturating_add_nominal`, `Fuel.saturating_add_reaches_limit`, `Fuel.saturating_add_robustness_overflow` |

Les identifiants `LLR-Mxx` des modules d'apprentissage sont des repères :
`tools/trace_check.py` ne contrôle que les modules dotés d'un répertoire
`requirements/`, ceux où la traçabilité est le sujet — modules 09, 10 et 12.

---

## 4. Exercices

Dans le conteneur ouvert par VS Code (*Reopen in Container*), depuis le
terminal intégré, à la racine du dépôt. Hors de VS Code, un `docker run`
direct doit d'abord déclarer le dépôt monté comme sûr pour git
dans le même conteneur que la commande — la déclaration ne survit pas à un
`docker run --rm` —, faute de quoi `config_index.py` refuse, à juste titre,
de produire le SCI des exercices 2 et 3 :

```bash
docker run --rm -v "$PWD:/workspace" do178c-ada:verif bash -c 'git config --global --add safe.directory /workspace && python3 tools/config_index.py'
```

1. **Retirer la garde.** Dans `src/mod00-fuel.adb`, remplacer tout le `if`
   par `return Sum;`. Lancer `./scripts/verify.sh prove` : que dit
   `gnatprove`, et sur quelle ligne ? Puis `./scripts/verify.sh build` — la
   compilation, elle, passe —, et lancer la campagne seule :
   `modules/00-environnement/bin/test_fuel`. Que devient-elle, et pourquoi
   est-ce le cas de robustesse qui le révèle ? (`./scripts/verify.sh run` ne
   recompile pas : il exécute les binaires présents.) Annuler ensuite la
   modification : `git checkout -- modules/00-environnement/src`.
2. **Faire mentir le Dockerfile.** Remplacer `ARG GNATPROVE_VERSION=16.1.0`
   par `15.1.0`, **sans** reconstruire l'image, puis régénérer le SECI :
   `python3 tools/config_index.py`. Lire `reports/SECI.md`. Pourquoi un SECI
   qui annonce une version que la machine n'a pas est-il pire que pas de SECI
   du tout ? Annuler ensuite la modification :
   `git checkout -- .devcontainer/Dockerfile`.
3. **Retirer le digest.** Remplacer la ligne `FROM` par
   `FROM ubuntu:resolute` et régénérer le SECI. Que signale-t-il ? D'après le
   commentaire du Dockerfile, pourquoi `resolute` plutôt que `26.04` ?
   Annuler ensuite la modification : `git checkout -- .devcontainer/Dockerfile`.
4. **Un nom qui éteint un contrôle.** Sous la déclaration de `Sum`, dans
   `src/mod00-fuel.adb`, ajouter `Spare : Natural := 0;`. Lancer
   `./scripts/verify.sh build`, puis `prove`. Renommer ensuite la variable
   `Unused`, et relancer les deux. Que s'est-il passé ? La réponse est dans le
   *GNAT User's Guide*, à propos des avertissements. Que devrait en dire un
   standard de codage, et qui le vérifierait — l'outil ou la revue
   ([module 11](../11-standards-qualification/)) ? Et pourquoi `gnatprove`
   rend-il 0 sur son avertissement, malgré `--checks-as-errors=on` ?
5. **Lire un DAL.** Quel niveau attendriez-vous pour les commandes de vol
   électriques, pour un régulateur de pression cabine, et pour une
   application de préparation de vol sur tablette non certifiée ? Justifier
   chaque réponse en une phrase, à partir de l'effet de la panne — pas de la
   complexité du logiciel.

---

## 5. Pour l'entretien

> **« Qu'est-ce qu'un SECI ? »**
> L'index de configuration de l'environnement du cycle de vie, §11.15 : ce
> qui a produit et vérifié le logiciel — compilateur, version, options,
> outils, système hôte. La réponse de référence, avec sa catégorie de
> contrôle et la leçon de l'étiquette d'image, est dans la
> [fiche d'entretien](../../docs/04-entretien.md).

> **« Pourquoi garder un vieux compilateur ? »**
> Parce que changer de compilateur peut changer le code objet, donc invalider
> des résultats de vérification déjà acquis — la couverture structurelle
> d'abord. Un changement de SECI se paie d'une vérification complète ; on ne
> le fait pas pour le plaisir d'être à jour.

> **« Toutes vos versions sont-elles épinglées ? »**
> Je sais dire ce qui l'est, ce qui est seulement tracé, et pourquoi — mon
> SECI le dit lui-même. L'image de base est désignée par son digest, depuis
> que j'ai vu l'étiquette `ubuntu:26.04` désigner trois images en cinq
> semaines sans que mon dépôt change. Ce que je ne peux pas épingler — l'image
> du runner — je le trace ; ce que je pourrais figer sans que rien n'en suive
> la version — BuildKit — je le trace aussi.

> **« La DO-178C impose-t-elle une méthode ? »**
> Non. Elle impose des objectifs, l'indépendance de certaines vérifications,
> et les données qui en apportent la preuve. Cycle en V, agilité ou modèles :
> c'est au plan de développement de le dire, et à l'autorité de l'accepter.

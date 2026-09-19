# La chaîne d'outils

> Ce que fait chaque outil, ce qu'il coûte, ce qu'on peut lui faire dire, et
> son statut DO-330. Toutes les versions sont épinglées dans
> [`.devcontainer/Dockerfile`](../.devcontainer/Dockerfile), **qui est le
> SECI de ce dépôt**.

---

## 1. Vue d'ensemble

| Outil | Version | Rôle | Qualification DO-330 |
|---|---|---|---|
| GNAT (`gnat_native`) | 16.1.0 | compilateur Ada 2022 | critère 1 si la sortie n'est pas vérifiée |
| `gprbuild` | 26.0.1 | construction | — |
| `gnatprove` | 16.1.0 | preuve SPARK | **critère 2 si la preuve remplace des tests : TQL-4 au DAL B** |
| `gnatcov` | 26.2.1 | couverture, jusqu'au MC/DC | **critère 3 : TQL-5, le niveau du kit AdaCore** |
| `gnatformat` | 26.0.0 | formatage | non requise — il vérifie, il ne corrige pas en CI |
| Alire (`alr`) | 2.1.1 | installation de la chaîne | — |
| `tools/trace_check.py` | — | matrice de traçabilité | non requise — complète la revue |
| `tools/config_index.py` | — | SCI et SECI | non requise — produit une donnée relue |

---

## 2. Pourquoi le binaire Alire et non le paquet Ubuntu

`alire` **existe** dans l'univers Ubuntu 26.04 (`resolute/universe`), en
version `1.2.1-2.1build1`. Mais cette version n'accepte que la branche d'index
figée `stable-1.2.1`, datée de 2023 :

| Voie | `alr` | Index | `gnatprove` accessible |
|---|---|---|---|
| apt `universe` | 1.2.1 | `stable-1.2.1` | **13.2.1** au mieux |
| binaire amont | 2.1.1 | `stable-1.4.0` | **16.1.0** |

L'apt fournit par ailleurs GNAT 14.3 : la chaîne obtenue serait dépareillée.

Second choix, moins visible mais aussi important :
**`alr install --prefix=/opt/ada`, et non `alr toolchain --select`.** Le
second enferme la chaîne dans le cache de l'utilisateur qui a lancé la
commande ; le premier la dépose dans un préfixe partagé, utilisable par
l'utilisateur non privilégié du conteneur.

---

## 3. Deux outils annoncés qui n'existent pas librement

À savoir avant de promettre quoi que ce soit en entretien.

### `gnatcheck` n'est pas distribué en binaire libre

Ses sources sont publiques — `AdaCore/langkit-query-language`, dossier
`lkql_checker` — mais il n'existe ni *crate* Alire ni release binaire, et le
construire demande toute la chaîne Langkit / Libadalang. En pratique, il
vient avec **GNAT Pro**.

Conséquence pour ce dépôt : l'analyse statique repose sur ce que le
compilateur offre — `-gnatwa -gnatwe` et le vérificateur de style `-gnaty` —
plus `gnatprove`, qui va bien au-delà d'un linter. Le
[module 11](../modules/11-standards-qualification/) mesure ce que cela coûte :
sur un contre-exemple violant six règles, le compilateur en attrape quatre.

### `gnatpp` est remplacé par `gnatformat`

`gnatpp` n'est plus livré qu'au sein de `libadalang_tools`, à compiler depuis
les sources. `gnatformat` 26.0.0 est un binaire prêt à l'emploi.

---

## 4. Les commandes

```bash
docker build -t do178c-ada:verif .devcontainer
```

```bash
docker run --rm -v "$PWD:/workspace" do178c-ada:verif ./scripts/verify.sh
```

| Script | Ce qu'il fait | Dans la CI ? |
|---|---|---|
| `verify.sh` | compilation, exécution, preuve, traçabilité, formatage | **oui** |
| `coverage.sh` | couverture stmt + decision + MC/DC | **oui** |
| `format.sh` | **applique** le format | **non, jamais** |
| `checks-cost.sh` | coût des vérifications à l'exécution (module 02) | non |
| `stack-usage.sh` | analyse de pile (module 07) | non |
| `coding-standard.sh` | ce que le standard attrape (module 11) | non |

`verify.sh` accepte une étape isolée : `build`, `run`, `prove`, `trace`,
`format`.

> **Pourquoi `format.sh` n'est jamais dans la CI.** Un outil qui **réécrit** du
> code sous contrôle de configuration sans qu'un humain le demande serait un
> outil de *développement* au sens DO-330, donc critère 1. Vérifier n'engage
> rien ; corriger engage.

---

## 5. Pièges vérifiés

Chacun a coûté du temps une fois. Ils sont aussi dans
[`CLAUDE.md`](../CLAUDE.md).

### Outillage

- **`gnatprove -P` sans `-U` n'analyse que la clôture des unités principales.**
  Un fichier qu'aucun `main` n'atteint est ignoré **en silence** : l'outil
  affiche « all checks proved » sans l'avoir regardé. Dans un dépôt à modules,
  c'est le défaut le plus coûteux possible.
- **`gnatprove` sort avec le code 0 même avec des vérifications non prouvées.**
  Une CI qui se fie au code de retour est verte sur du code non prouvé.
  `--checks-as-errors=on` corrige.
- **`gnatformat` décode en `iso-8859-1` par défaut** et réécrit tout
  commentaire accentué en mojibake. `--charset=utf-8` n'est pas une option.
- **`gnatcov` a besoin de `GPR_PROJECT_PATH`** pointant sur le `share/gpr` du
  préfixe, sinon il ne trouve pas `gnatcov_rts.gpr`.
- **`gnatcov instrument` est incompatible avec `Abstract_State`.** Il insère
  une variable témoin devant chaque déclaration d'objet ; dans un paquetage à
  état abstrait, ces variables deviennent de l'état caché absent du
  `Refined_State`, et GNAT rejette le raffinement. `--spark-compat` n'y change
  rien. Voir [module 04 §1.7](../modules/04-spark-analyse-de-flot/).
- **`gnatformat` réécrit `=>+` en `=> +`**, forme que `-gnatyt` refuse. Deux
  outils de la chaîne se contredisent ; écrire la dépendance en toutes lettres.
- **`gnatprove` écrit ses artefacts dans `Exec_Dir`** quand le projet en
  déclare un. Un script qui parcourt `bin/*` doit filtrer les répertoires.
- **`alr exec` exige un `alire.toml`.** Sans espace de travail Alire, poser le
  `PATH` à la main.
- **`core.filemode=false` sous Windows : `chmod +x` n'entre jamais dans
  l'index.** Les scripts sont enregistrés en `100644` et la CI échoue en
  **exit 126**. Invisible en local — un montage bind depuis Windows présente
  tout en 777. Seul un `git checkout` sur un runner Linux le révèle.
  Correction : `git update-index --chmod=+x <fichier>`.

### Langage

- **`-gnatys` exige une déclaration avant tout corps de sous-programme**, y
  compris imbriqué.
- **Ada 2022 veut `[...]` pour les agrégats de tableau** ; `(...)` déclenche
  `-gnatwj`.
- **`'Old` doit nommer une entité** dès qu'il y a un `and then`. Écrire
  `Level (T'Old)`, pas `Level (T)'Old`.
- **`Type_Invariant` + `'Old` dans une conséquence de `Contract_Cases`** lève
  une **fausse** « failed invariant » sous GNAT 16.1.0. Répartir :
  `Contract_Cases` pour la table de décision, `Post` pour la condition de
  cadre.
- **SPARK veut le `Type_Invariant` sur la complétion**, pas sur la déclaration
  privée.
- **SPARK refuse un littéral réel dans une multiplication en virgule fixe.**
  Donner un type à la constante.
- **Un caractère hors Latin-1 dans un littéral de chaîne est illégal** :
  `String` est un tableau de `Character`. Le tiret cadratin passe en
  commentaire, pas dans une chaîne affichée.
- **Un attribut ne s'applique qu'à un nom** : `(X'Size / 8)'Image` est refusé.
- **SPARK exige `pragma Elaborate_Body`** quand des primitives d'un type
  étiqueté sont définies dans le corps (message E0003).

---

## 6. Ce que la chaîne Ada apporte face à la chaîne C++

| | Dépôt C++ | Ce dépôt |
|---|---|---|
| Couverture | lignes et branches (`gcovr`) | instructions, décisions, **MC/DC** |
| Absence d'erreur à l'exécution | argumentée, revue | **prouvée** |
| Couplage données/contrôle | tableau tenu à la main | `Global` / `Depends` vérifiés |
| Analyse statique | `clang-tidy`, qualifié pour rien | `gnatprove`, **kit DO-330 réel** pour `gnatcov` |
| Interdiction des exceptions | convention de codage | `pragma Restrictions`, vérifié à l'édition de liens |
| Absence d'allocation | revue | `pragma Restrictions`, vérifié |

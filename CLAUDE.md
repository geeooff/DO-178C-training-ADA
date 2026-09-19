# Contexte du projet

> Ce fichier a été rédigé **avant** la première session de travail, depuis le
> projet frère en C++, pour transmettre le contexte. Il a été **corrigé au fur
> et à mesure** : sa section « Chaîne d'outils » énonce désormais des faits
> mesurés, et « État du dépôt » dit où en est le travail.

## Ce qu'est ce dépôt

Un **support d'auto-formation**, pas un produit. Il sert à un développeur
principalement **C#** à monter en compétences sur **Ada / SPARK** et sur
l'impact de la **DO-178C** sur la façon de développer, en vue d'une
candidature dans le logiciel embarqué avionique.

**Le lecteur ne connaît ni Ada, ni C++.** Ce dépôt doit donc se tenir **seul**.
Il peut renvoyer au projet frère en C++, jamais en dépendre pour être compris.

## Le projet frère

`../DO-178C-training` en local, `github.com/geeooff/DO-178C-training` en
ligne — même démarche, même auteur, même public, en **C++17**.
17 modules, 19 campagnes de test, outillage de traçabilité, CI verte sur trois
chaînes. Il est **terminé et vérifié** : c'est la référence de qualité à
égaler, et la source des conventions ci-dessous.

Son `CLAUDE.md` contient le détail des conventions communes.

### Ce qui se réutilise

Les objectifs de processus sont **indépendants du langage** et déjà traités
là-bas : exigences et traçabilité, tests basés sur les exigences, couverture
structurelle, couplage données/contrôle, gestion de configuration et qualité
(ses modules 09 à 12 et 14), plus les gabarits de revue et les deux outils
Python. Environ **35 %** du travail du dépôt C++ est transférable sans
modification.

### La tension à trancher en début de projet

Deux contraintes tirent en sens inverse :

- ne pas réécrire ce qui existe déjà et ne change pas avec le langage ;
- rester compréhensible pour un lecteur qui n'a **pas** fait la formation C++.

**Recommandation :** traiter les modules de processus de façon **autonome mais
condensée** — l'objectif DO-178C, sa mise en œuvre en Ada, et un renvoi
explicite vers le module C++ correspondant pour le traitement long. Ne jamais
supposer le C++ connu. Décision à confirmer à la première session.

## Le marché visé

Donneurs d'ordre de l'aviation **française**. Ada y est un vrai
différenciateur, plus qu'aux États-Unis, et les candidats sont plus rares.

| Acteur | Usage d'Ada, en pratique |
|---|---|
| **Thales** | Avionique et contrôle aérien — usage établi |
| **Safran** | Contrôle moteur (FADEC) — usage établi |
| **Dassault Aviation** | Rafale, Falcon — usage établi |
| **Airbus** | Historique fort (A340, A380). Une grande part du logiciel de commandes de vol récent est du **C généré par SCADE** (DO-331), pas de l'Ada écrit à la main |
| **ATR** | Surtout intégrateur : l'avionique vient des équipementiers. Peu d'Ada écrit en interne |
| MBDA, ArianeGroup | Usage établi (défense, spatial) |

À vérifier et à actualiser sur les offres d'emploi réelles plutôt qu'à tenir
pour acquis — c'est aussi ce qui dira si l'effort doit porter sur Ada ou
plutôt sur SCADE / DO-331.

## La différence pédagogique avec le dépôt C++

**En C++, la DO-178C oblige à construire la discipline que le langage ne donne
pas. En Ada, l'essentiel est dans le langage, et le travail consiste à savoir
où ses garanties s'arrêtent.** La pédagogie s'inverse ; ne pas transposer les
modules C++ un pour un.

Concrètement :

- **Types, conversions, invariants** — les sous-types contraints, l'absence de
  conversion implicite et les bornes vérifiées d'office rendent inutile
  l'essentiel de ce que le dépôt C++ construit à la main. Le sujet devient :
  *ce qu'il reste à prouver quand le langage a déjà fait sa part*.
- **Mémoire statique et temps réel** — `pragma Restrictions (No_Allocators)`
  et le profil **Ravenscar** remplacent du code par de la **configuration**.
- **Erreurs** — Ada *a* des exceptions, mais on les interdit en DAL A/B. Le
  débat est plus riche qu'en C++, où elles sont écartées d'emblée.
- **DO-332 (orienté objet)** — types étiquetés, mêmes objectifs. Transfère
  bien.

## Ce qu'Ada permet d'enseigner et que le C++ ne permettait pas

Ce sont les deux lacunes déclarées du dépôt C++ ; elles deviennent ici le cœur
du sujet.

1. **Vérifications à l'exécution, et leur suppression.** Ada en insère par
   défaut. Les garder coûte du temps réel et produit du **code objet sans
   équivalent source** — d'où la question de la **couverture du code objet**.
   Les supprimer par `pragma Suppress` oblige à **prouver** qu'elles ne
   pouvaient pas se déclencher.
2. **SPARK et la DO-333.** Prouver l'absence d'erreur à l'exécution (AoRTE),
   puis des propriétés fonctionnelles, et faire valoir ces preuves en
   remplacement de certains objectifs de test. C'est la vraie raison
   d'apprendre Ada : **un support Ada sans SPARK passerait à côté.**
3. **Qualification d'outils concrète.** GNATcoverage dispose d'un kit de
   qualification DO-330 réel, là où clang-tidy n'est qualifié pour rien. Le
   sujet passe du concept à l'artefact. Nuance vérifiée : GNATcheck, souvent
   cité avec lui, n'est **pas** distribué librement.

## L'atout à ne pas manquer

**Reprendre le même cas d'étude FQMS que le dépôt C++** — système de jaugeage
carburant, DAL B — contre les **mêmes exigences HLR/LLR** et la **même matrice
de traçabilité**, en Ada/SPARK.

Un ingénieur qui compare les deux implémentations comprend en trente secondes
que le candidat a saisi l'essentiel du métier : **le processus est la
constante, le langage est la variable.** Cette comparaison vaut plus que les
deux dépôts pris séparément.

## Convention de langue — impérative

| En **anglais** | En **français** |
|---|---|
| Identifiants : types, sous-programmes, paramètres, variables | Commentaires de code |
| Noms de cas de test et de suites | README, `docs/`, exigences, gabarits |
| | Prose des tables de traçabilité |
| | Messages de commit |

**Pourquoi :** le code doit coller au marché ; le support de formation reste en
français parce que son lecteur lit et applique plus vite dans cette langue.

**Spécificité Ada :** la convention du langage est `Mixed_Case_With_Underscores`
style GNAT, vérifié par `gnatformat` — et non par `gnatpp` ni `gnatcheck`,
qui ne sont pas distribués librement. Ne pas transposer le style C++.

## Chaîne d'outils — vérifiée le 2026-08-28

Chaîne obtenue et **exercée de bout en bout** (compilation, exécution, preuve,
couverture, formatage) dans une image `ubuntu:26.04`. Versions épinglées dans
[`.devcontainer/Dockerfile`](.devcontainer/Dockerfile), qui tient lieu de SECI.

| Outil | Version | Obtenu par |
|---|---|---|
| GNAT (`gnat_native`) | 16.1.0 | Alire, préfixe `/opt/ada` |
| `gprbuild` | 26.0.1 | Alire |
| `gnatprove` (SPARK) | 16.1.0, Why3 1.8.2, CVC5 | Alire |
| `gnatcov` (`gnatcov_bin`) | 26.2.1 | Alire |
| `gnatformat` (`gnatformat_bin`) | 26.0.0 | Alire |
| Alire (`alr`) | 2.1.1 | binaire amont GitHub |

**Le paquet `alire` d'Ubuntu ne convient pas.** Il existe bien
(`resolute/universe`, `1.2.1-2.1build1`), mais `alr` 1.2.1 n'accepte que la
branche d'index figée `stable-1.2.1` : `gnatprove` y plafonne à **13.2.1**,
contre **16.1.0** par le binaire amont. L'apt fournit par ailleurs GNAT 14.3,
donc une chaîne dépareillée. Voie retenue : binaire amont, versions épinglées.

**`alr install --prefix=/opt/ada`, et non `alr toolchain --select`.** Le second
enferme la chaîne dans le cache de l'utilisateur qui a lancé la commande ; le
premier la dépose dans un préfixe partagé, utilisable par l'utilisateur non
privilégié du conteneur.

### Deux outils annoncés qui n'existent pas librement

- **`gnatcheck` n'est pas distribué en binaire libre.** Ses sources sont
  publiques (`AdaCore/langkit-query-language`, dossier `lkql_checker`), mais
  aucune crate Alire, aucune release binaire, et le construire demande toute
  la chaîne Langkit / Libadalang. En pratique, il vient avec GNAT Pro.
  L'analyse statique doit donc reposer ici sur ce que le compilateur
  offre — `-gnatwa -gnatwe` et le vérificateur de style `-gnaty` — plus
  `gnatprove` lui-même, qui va bien au-delà d'un linter.
- **`gnatpp` est remplacé par `gnatformat`.** `gnatpp` n'est plus livré qu'au
  sein de `libadalang_tools`, à compiler depuis les sources. `gnatformat`
  26.0.0 est un binaire prêt à l'emploi et fait le même travail.

### Pièges vérifiés, à ne pas redécouvrir

- **`gnatprove -P` sans `-U` n'analyse que la clôture des unités principales.**
  Un fichier qu'aucun `main` n'atteint est ignoré **en silence** : il affiche
  « all checks proved » sans avoir regardé. Dans un dépôt à modules, c'est le
  défaut le plus coûteux possible. Toujours `-U`.
- **`gnatprove` sort avec le code 0 même quand des vérifications ne sont pas
  prouvées.** Une CI qui se fie au code de retour est verte sur du code non
  prouvé. `--checks-as-errors=on` corrige — vérifié : 1 avec défaut, 0 sans.
- **`gnatformat` décode en `iso-8859-1` par défaut** et réécrit alors tout
  commentaire accentué en mojibake (`vérification` → `vÃ©rification`). Dans un
  dépôt dont les commentaires sont en français, `--charset=utf-8` n'est pas
  une option. Côté compilateur, le pendant est `-gnatW8`.
- **`gnatcov` a besoin de `GPR_PROJECT_PATH`** pointant sur le `share/gpr` du
  préfixe, sinon il ne trouve pas `gnatcov_rts.gpr` et l'instrumentation
  échoue. `gnatcov setup --prefix=...` doit tourner à la construction de
  l'image, en root.
- **`gnatprove` écrit ses artefacts dans `Exec_Dir`** quand le projet en
  déclare un, et non dans `Object_Dir`. Un script qui parcourt `bin/*` pour
  exécuter les programmes témoins doit filtrer les répertoires.
- **`alr exec` exige un `alire.toml`.** Sans espace de travail Alire, il faut
  poser le `PATH` à la main — ce que fait l'image.
- **`core.filemode=false` sous Windows : `chmod +x` n'entre jamais dans
  l'index.** Les scripts se retrouvent en `100644`, et la CI échoue en
  **exit 126** — commande trouvée, non exécutable. Le défaut est invisible en
  local : un montage bind depuis Windows présente tout en 777, et `docker cp`
  d'un arbre de travail aussi. Seul un vrai `git checkout` sur un runner Linux
  le révèle. Correction : `git update-index --chmod=+x <fichier>`.

- **`gnatcov instrument` est incompatible avec `Abstract_State`.** Il insère
  une variable témoin devant chaque déclaration d'objet ; dans un paquetage à
  état abstrait, ces variables deviennent de l'état caché absent du
  `Refined_State`, et GNAT rejette le raffinement. Identique en corps et en
  partie privée ; `--spark-compat` n'y change rien (gnatcov 26.2.1). Réponse
  retenue : coquille d'état mince et sans décision, logique dans un paquetage
  sans état qui, lui, est mesuré, et exclusion justifiée dans `coverage.sh`.
- **`gnatformat` réécrit `=>+` en `=> +`**, forme que `-gnatyt` refuse
  ensuite. Deux outils de la chaîne se contredisent. Écrire la dépendance en
  toutes lettres : `Depends => (State => (State, Reading))`.

### Pièges de langage, vérifiés eux aussi

- **Un caractère hors Latin-1 dans un LITTÉRAL de chaîne est illégal** :
  `String` est un tableau de `Character`. Le tiret cadratin `—` (U+2014)
  passe en commentaire mais fait échouer `gnatprove` avec « literal out of
  range of type Standard.Character ». Dans les chaînes affichées, s'en tenir
  au Latin-1 : `é à ç « »` passent, `— …` non.
- **`'Size` et compagnie ne s'appliquent qu'à un nom.** Écrire
  `(X'Size / 8)'Image` est refusé ; qualifier :
  `Natural'Image (X'Size / 8)`.
- **`-gnatys` exige une déclaration avant tout corps de sous-programme**, y
  compris pour une procédure imbriquée dans un `main`. Deux lignes de plus,
  et la signature se lit sans dérouler le corps.
- **Ada 2022 veut `[...]` pour les agrégats de tableau.** `(...)` déclenche
  `-gnatwj`, donc une erreur ici.
- **`'Old` doit nommer une entité** dès que l'expression est potentiellement
  non évaluée — c'est-à-dire dès qu'il y a un `and then`. Écrire
  `Level (T'Old)` et non `Level (T)'Old`. Ne pas suivre la suggestion du
  compilateur d'ajouter `pragma Unevaluated_Use_Of_Old (Allow)` : la forme
  correcte est plus claire et copie moins.
- **`Type_Invariant` + `'Old` dans une conséquence de `Contract_Cases` lève
  une fausse « failed invariant »** à l'exécution sous GNAT 16.1.0, alors que
  l'invariant est respecté. Vérifié sur un cas minimal : le même énoncé écrit
  dans un `Post` fonctionne, et sans `Type_Invariant` le `Contract_Cases`
  fonctionne aussi. Répartir : `Contract_Cases` pour la table de décision,
  `Post` pour la condition de cadre.
- **SPARK refuse un `Type_Invariant` sur la déclaration privée** : il le veut
  sur la complétion, dans la partie privée.
- **SPARK refuse un littéral réel dans une multiplication en virgule fixe.**
  Donner un type à la constante — ce qui rend l'échelle explicite.

## Discipline de vérification — non négociable

C'est ce qui donne au dépôt C++ sa crédibilité, et ce qui devra être reproduit
ici avec les outils Ada :

- compilation **sans le moindre avertissement**, avertissements traités en
  erreurs ;
- **toutes** les campagnes de test au vert ;
- formatage propre (`gnatformat --check --charset=utf-8`) ;
- traçabilité vérifiée par outil, pas à la main ;
- couverture mesurée (`gnatcov`), jusqu'au **MC/DC** ;
- preuves SPARK au niveau visé, sans régression.

Aucune modification n'est terminée avant que tout cela passe. Ne jamais
commiter « en attendant ». Un exemple qui ne compile pas n'a aucune valeur
dans un support de formation.

## Règles de rédaction

- Le lecteur est un développeur **C# expérimenté, débutant en Ada**. Expliciter
  les écarts avec C#, pas seulement la syntaxe Ada. Le dépôt C++ a un document
  `docs/02-csharp-vers-cpp.md` ; prévoir l'équivalent.
- Les commentaires font partie du cours : ils expliquent le *pourquoi* — quel
  objectif DO-178C, quel accident historique — jamais seulement le *quoi*.
- La formation prépare aussi l'**entretien d'embauche**.

## Conventions Git

- Messages de commit **en français**, à l'impératif ou au présent descriptif,
  expliquant le **pourquoi** et le prix payé.
- **Un sujet par commit** : `git blame` doit rester exploitable.
- Adresse d'auteur : l'adresse *noreply* GitHub
  (`10533139+geeooff@users.noreply.github.com`), déjà configurée globalement.
- Ne rien pousser sans demande explicite.

## État du dépôt — 2026-08-28

**Les treize modules sont écrits, et tout est vert.** Chiffres obtenus par
exécution, pas estimés :

| | |
|---|---|
| Campagnes | 106 cas, 222 vérifications, 0 échec |
| Preuve SPARK | 253 obligations déchargées, 1 justifiée |
| Couverture | 47 mesures à 100 %, une seule volontairement partielle |
| Traçabilité | 0 défaut, 25 exigences, 2 dérivées |
| Avertissements | 0, traités en erreurs |

L'unique chiffre de couverture inférieur à 100 % est celui de
`modules/10-couverture-et-preuve/decision-seule/` — une campagne délibérément
faible, dont l'écart avec la campagne complète **est** le sujet du module.

### Noms de répertoires réels

Ils diffèrent légèrement de la table des décisions ci-dessous :

```
00-environnement            07-memoire-statique
01-types-et-contraintes     08-objet-do332
02-verifications-execution  09-exigences-tracabilite
03-contrats-ada-2022        10-couverture-et-preuve
04-spark-analyse-de-flot    11-standards-qualification
05-spark-preuve-do333       12-projet-integre
06-erreurs-sans-exceptions
```

### Conventions établies en écrivant

- **Un paquetage racine `ModNN` par module**, avec des enfants
  `ModNN.Composant`. Pendant Ada des namespaces `modNN::` du dépôt frère.
- **Sous-projets pour ce qui doit être construit autrement** :
  `06/restreint/` (profil sans exceptions), `07/ravenscar/` (profil temps
  réel), `10/decision-seule/` (campagne faible), `11/nonconforme/`
  (contre-exemple du standard). Chacun pointe sur les sources du module,
  aucun ne les duplique.
- **`11/nonconforme/` est exclu** de `verify.sh` et `format.sh` : il viole le
  standard à dessein. Son seul point d'entrée est `scripts/coding-standard.sh`,
  qui vérifie qu'il ne compile PAS.
- **Six scripts** : `verify.sh` (build, run, prove, trace, format),
  `coverage.sh`, `format.sh` — jamais en CI — plus trois scripts de mesure,
  `checks-cost.sh`, `stack-usage.sh`, `coding-standard.sh`.

### Publication — 2026-09-19

Le dépôt est sur GitHub (`geeooff/DO-178C-training-ADA`), CI verte dans le
SECI, actions épinglées par SHA, Dependabot configuré. Une revue de
publication a corrigé ce qu'un lecteur du métier aurait relevé : numéros
d'objectifs A-n.m et de paragraphes de la DO-178C, critères DO-330,
attribution des CAST, une référence bibliographique inventée, la
terminologie « type dérivé », et les liens vers le dépôt frère. Le protocole
de cette revue est simple et à rejouer avant tout passage en public :
chaque référence normative vérifiée contre la norme, chaque lien vérifié
par outil, chaque chiffre du README recompté depuis un journal d'exécution.

### Ce qui reste ouvert

- Pas de tag de version.
- Le tableau du marché français (`docs/05-ressources.md`) est à réactualiser
  sur des offres réelles.
- Les versions des crates Alire du Dockerfile ne sont suivies par personne :
  point de revue manuel, à faire à chaque proposition Dependabot.

## Décisions arrêtées — 2026-08-28

Les cinq questions de première session sont tranchées. Ce qui suit est la
référence ; ne pas les rouvrir sans raison neuve.

**1. Chaîne d'outils.** Alire binaire amont, versions épinglées dans l'image.
Voir « Chaîne d'outils » plus haut.

**2. Autonomie vis-à-vis du dépôt C++ — autonome pour la prose, dupliqué pour
l'outillage.** Les modules de processus (09 à 11) sont rédigés de façon
autonome mais condensée, avec renvoi explicite au module C++ correspondant
pour le traitement long. En revanche les **artefacts et l'outillage** —
exigences, matrice de traçabilité, `trace_check.py` — sont physiquement ici et
s'exécutent ici. Un renvoi casserait la règle « vérifié pour de vrai », et le
projet intégré en dépend pour tourner.

**3. Découpage — 13 modules**, contre 17 en C++ :

| # | Module | # | Module |
|---|---|---|---|
| 00 | environnement | 07 | mémoire statique et déterminisme |
| 01 | types et contraintes | 08 | objet et DO-332 |
| 02 | vérifications à l'exécution | 09 | exigences, traçabilité, tests |
| 03 | contrats Ada 2022 | 10 | couverture et crédit de preuve |
| 04 | SPARK — analyse de flot | 11 | standards, qualification, configuration |
| 05 | SPARK — preuve, DO-333 | 12 | projet intégré FQMS |
| 06 | erreurs sans exceptions | | |

Disparus par rapport au C++ : pointeurs et `const`, RAII, templates. Nouveaux :
02, 04 et 05 — c'est là qu'est la valeur qu'Ada seul permet d'enseigner.

**4. Construction — `gprbuild` seul.** Un `.gpr` par module, `shared.gpr` pour
les commutateurs, `common/common.gpr` pour le harnais. **Pas d'`alire.toml`** :
les donneurs d'ordre lisent des `.gpr`, pas des manifestes Alire, et `alr exec`
exigerait un espace de travail. Alire installe la chaîne dans l'image, et
s'arrête là.

**5. CI — un seul job, dans l'image.** Il construit le SECI puis lance
`verify.sh` et `coverage.sh` dedans. Réinstaller la chaîne dans le workflow
créerait deux vérités sur l'environnement, ce que le §11.15 cherche justement
à empêcher.

**6. Tests — harnais maison, pas AUnit.** AUnit existe comme crate Alire, mais
trois raisons l'écartent : il exigerait un `alire.toml` (voir 4), il repose sur
des types étiquetés et de l'allocation dynamique — ce que le module 07 apprend
justement à bannir — et il ne sait rien des exigences. Le harnais de
`common/src/testing.ads` tient en deux cents lignes, n'alloue rien, et porte
l'identifiant d'exigence dans l'appel, ce qui rend la traçabilité vérifiable
par outil. AUnit est présenté et comparé au module 09.

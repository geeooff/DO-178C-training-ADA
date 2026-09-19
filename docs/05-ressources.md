# Ressources

> Ce qui sert vraiment, et à quel moment. Les liens sont donnés sans garantie
> de pérennité ; les documents normatifs, eux, s'achètent.

---

## 1. Les normes

Elles ne sont **pas** gratuites, et il n'existe pas d'exemplaire légal en
ligne. Une équipe qui travaille en certification les a ; un candidat n'est pas
censé les posséder.

| Document | Éditeur | Prix indicatif |
|---|---|---|
| DO-178C / ED-12C | RTCA / EUROCAE | quelques centaines d'euros |
| DO-330, DO-331, DO-332, DO-333 | RTCA / EUROCAE | idem, chacun |
| ARP4754A, ARP4761 | SAE | idem |

**Ce qui est gratuit et utile** : les *position papers* du **CAST**
(*Certification Authorities Software Team*), publiés par la FAA. Trois à
connaître : CAST-6 (le MC/DC masqué), CAST-10 (ce qu'est une décision) et
CAST-32A (le multicœur — repris et remplacé depuis par l'AC 20-193 de la FAA
et l'AMC 20-193 de l'EASA, qu'il faut citer aujourd'hui).

---

## 2. Ada et SPARK

### Références

- **Ada Reference Manual (ARM)** — la norme du langage, librement consultable
  en ligne. Les paragraphes cités dans ce dépôt (RM 6.1.1(27), RM 11.5, RM
  7.3.2) y renvoient.
- **SPARK Reference Manual** — publié par AdaCore, en ligne.
- **GNAT User's Guide** et **GNAT Reference Manual** — pour les commutateurs,
  les `pragma Restrictions` et les aspects propres à GNAT.

### Livres

- **John Barnes, *Programming in Ada 2012* (ou 2022)** — la référence
  d'apprentissage. Long, mais c'est le seul livre qui couvre le langage
  entier.
- **John McCormick, Frank Singhoff, Jérôme Hugues, *Building Parallel,
  Embedded, and Real-Time Applications with Ada*** — le livre à lire pour
  Ravenscar et le temps réel.
- **AdaCore, *Implementation Guidance for Safety-Critical Ada*** — court, et
  directement utile.

### En ligne

- **learn.adacore.com** — cours interactifs, dont un parcours *Introduction to
  SPARK* qui vaut la journée qu'il prend.
- **Le blog d'AdaCore** — les articles sur la preuve de bibliothèques réelles
  sont les meilleurs exemples publics de ce que SPARK permet.

---

## 3. Certification et pratique

- **Leanna Rierson, *Developing Safety-Critical Software*** — le livre à lire
  si on n'en lit qu'un. Écrit par une ancienne de la FAA ; il explique ce que
  les objectifs veulent dire en pratique.
- **Les rapports d'accident.** Le rapport de la commission **Lions** sur
  Ariane 501 fait vingt pages et vaut n'importe quel cours sur la réutilisation
  logicielle. Le rapport du **Mars Climate Orbiter Mishap Investigation
  Board** de la NASA est du même calibre.

---

## 4. Le marché français

Ce dépôt vise les donneurs d'ordre de l'aviation **française**, où Ada reste
un vrai différenciateur — davantage qu'aux États-Unis, et avec moins de
candidats.

| Acteur | Usage d'Ada, en pratique |
|---|---|
| **Thales** | avionique et contrôle aérien — usage établi |
| **Safran** | contrôle moteur (FADEC) — usage établi |
| **Dassault Aviation** | Rafale, Falcon — usage établi |
| **Airbus** | historique fort (A340, A380). Une grande part du logiciel de commandes de vol récent est du **C généré par SCADE** (DO-331), pas de l'Ada écrit à la main |
| **ATR** | surtout intégrateur : l'avionique vient des équipementiers. Peu d'Ada écrit en interne |
| **MBDA, ArianeGroup** | usage établi (défense, spatial) |

> **À vérifier plutôt qu'à croire.** Ce tableau reflète une situation
> générale ; les offres d'emploi réelles disent mieux si l'effort doit porter
> sur Ada ou plutôt sur **SCADE / DO-331**. Le relire tous les six mois.

---

## 5. Communauté

- **comp.lang.ada** — encore actif, et le niveau y est élevé.
- **Le forum Alire / la communauté Ada sur GitHub** — pour l'outillage.
- **Ada-Europe** et **AEiC** (conférence annuelle) — pour ce qui se fait en
  recherche appliquée et en industrie.

---

## 6. Le dépôt frère

[`geeooff/DO-178C-training`](https://github.com/geeooff/DO-178C-training) — la même démarche en
**C++17**, avec le **même cas d'étude FQMS** et les **mêmes exigences de haut
niveau**.

C'est la ressource la plus directement utile de cette liste : lire les deux
SDD du FQMS côte à côte montre, en dix minutes, ce que le langage change et
ce qu'il ne change pas.

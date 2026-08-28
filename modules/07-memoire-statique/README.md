# Module 07 — Mémoire statique et déterminisme

> **Durée estimée** : 1,5 journée
> **Prérequis** : modules 00 à 06

---

Deux sujets que le dépôt frère en C++ traite en écrivant du code, et qu'Ada
traite en écrivant de la **configuration** : l'absence d'allocation dynamique,
et le modèle temps réel. Le module montre les deux, et mesure ce qui reste à
surveiller — la pile.

---

## Objectifs pédagogiques

1. Écrire une structure de données à capacité fixe, sans allocation, prouvée.
2. Savoir ce qu'apporte `Ghost` : une spécification riche qui ne coûte rien
   au code embarqué.
3. Connaître `pragma Restrictions (No_Allocators, No_Dependence => …)` et
   `pragma Profile (Ravenscar)`, et savoir ce que chacun interdit.
4. Lire une analyse de pile `-fstack-usage` et comprendre pourquoi une trame
   *dynamic* est un signal d'alarme.
5. Situer l'analyse **WCET** : ce qu'on peut faire sans cible, et ce qu'on ne
   peut pas.

---

## 1. Le cours

### 1.1 Pas de tas, et le dire au compilateur

En C#, tout objet vit sur le tas et le ramasse-miettes s'en occupe — avec des
pauses non bornées, ce qui suffit à l'exclure du temps réel dur. En C++, on
peut éviter le tas, mais rien ne l'interdit : le dépôt frère y consacre un
`StaticVector` avec placement `new`, alignement manuel et destruction
explicite.

En Ada, deux lignes :

```ada
pragma Restrictions (No_Allocators);
pragma Restrictions (No_Dependence => Ada.Unchecked_Deallocation);
```

Ce ne sont pas des conventions : le compilateur refuse de compiler un `new`,
et l'éditeur de liens refuse une partition qui dépend de la libération. La
règle de codage devient une propriété vérifiée.

Et la structure de données elle-même n'a besoin de rien de spécial :

```ada
type Element_Array is array (Index_Type) of Litres;

type Buffer is record
   Items : Element_Array := [others => 0];
   First : Index_Type    := 0;
   Count : Count_Type    := 0;
end record;
```

Un tableau contraint dans un enregistrement privé. Taille connue à la
compilation, initialisation par défaut garantie, aucune ressource à libérer.

### 1.2 `Ghost` : spécifier sans payer

La file circulaire a une postcondition qui dit l'ordre FIFO :

```ada
procedure Push (B : in out Buffer; Value : Litres)
with
  Pre  => not Is_Full (B),
  Post =>
    Length (B) = Length (B'Old) + 1
    and then Element (B, Length (B) - 1) = Value
    and then (for all K in 0 .. Length (B'Old) - 1 =>
                Element (B, K) = Element (B'Old, K));
```

`Element` est déclarée `Ghost` : elle n'existe **que** pour les contrats, et
le compilateur l'élimine du code de production. On écrit donc une
spécification aussi riche qu'on veut sans ajouter une ligne au binaire
embarqué.

C'est un point à connaître pour l'entretien : la richesse de la spécification
formelle n'est pas payée en mémoire programme.

> Les 27 obligations de ce module sont déchargées, y compris les `for all`
> sur un tableau circulaire — c'est-à-dire avec de l'arithmétique modulaire
> sous le quantificateur. Ce n'est pas gratuit à écrire, mais c'est faisable.

### 1.3 Le profil Ravenscar

`pragma Profile (Ravenscar)` est un jeu de restrictions destiné à rendre le
comportement temps réel **analysable**. Ce qu'il interdit, et pourquoi :

| Interdit | Pourquoi |
|---|---|
| Objets protégés locaux | leur durée de vie ne s'analyse pas |
| Hiérarchie de tâches | une tâche créée au fond d'une procédure n'entre dans aucun modèle |
| `delay` relatif | une durée relative dérive ; une échéance absolue s'analyse |
| Plus d'une entrée par tâche, `select` | l'ordonnancement redevient indécidable |
| Priorités dynamiques | l'analyse d'ordonnançabilité suppose des priorités fixes |
| Terminaison de tâche | un système embarqué tourne tant qu'il est alimenté |

Ce qui reste est exactement le modèle que les théorèmes d'ordonnançabilité
savent traiter : tâches périodiques à priorité fixe, objets protégés à
plafond de priorité. **Les restrictions ne sont pas là pour punir : elles sont
là pour que le calcul existe.**

Le motif canonique, dans [`ravenscar/src/cyclic.adb`](ravenscar/src/cyclic.adb) :

```ada
Next : Time := Clock;
...
loop
   Next := Next + Period;
   delay until Next;
   ...
end loop;
```

L'échéance suivante se calcule depuis la précédente, jamais depuis l'heure
courante. Un cycle qui déborde ne décale pas les suivants.

> **Vérifié en écrivant ce module.** La première version plaçait l'objet
> protégé et la tâche dans le corps du programme principal. Trois erreurs :
> `No_Local_Protected_Objects`, `No_Task_Hierarchy`, `No_Relative_Delay`. Le
> profil ne se contourne pas par distraction.

### 1.4 L'analyse de pile — ce qui reste à surveiller

Sans tas, la seule mémoire qui varie à l'exécution est la **pile**. Un
débordement y est catastrophique et silencieux. La DO-178C ne la nomme pas
explicitement, mais §6.3.3.f — *les ressources sont suffisantes* — en dépend
directement.

`-fstack-usage` fait écrire au compilateur, pour chaque sous-programme, la
taille de sa trame et sa nature :

```bash
./scripts/stack-usage.sh
```

Sur ce dépôt, à ce jour :

```
239 sous-programmes, 25800 octets de trames cumulés
```

Et surtout, ceci :

| Nature | Ce que ça veut dire | Où on en trouve ici |
|---|---|---|
| `static` | taille fixe, connue à la compilation | **tout le code sous test** |
| `dynamic` | taille calculée à l'exécution | uniquement dans les démonstrations et le harnais |
| `bounded` | variable mais majorée | idem |

**Aucune unité `mod0*` — c'est-à-dire aucun code « embarqué » de ce dépôt —
n'a de trame non statique.** Toutes les trames dynamiques viennent de
`Ada.Text_IO` et de la concaténation de chaînes :

```ada
Ada.Text_IO.Put_Line ("Total :" & Value'Image & " L");
```

`Value'Image` produit une chaîne de longueur calculée à l'exécution, qui vit
sur la pile secondaire. C'est parfaitement acceptable dans un programme de
démonstration, et proscrit dans du code de vol — d'où la règle usuelle : **pas
de `Ada.Text_IO`, pas de chaînes de longueur variable** dans les unités
embarquées.

La plus grosse trame du dépôt, 1 776 octets, est celle du `main` de
démonstration du module 01. Le code sous test le plus gourmand tient en
quelques dizaines d'octets.

> **Limite honnête.** Ce script n'est pas une analyse de pile. Il donne les
> trames, pas le **chemin d'appel le plus profond**, qui est ce qu'il faut
> réellement borner. Cela se fait avec GNATstack — non distribué librement —
> ou par une mesure sur cible avec motif de remplissage.

### 1.5 WCET : ce qu'on peut dire sans cible

Le pire temps d'exécution ne se calcule pas depuis le source : il dépend du
cache, du pipeline, de la prédiction de branchement, de la contention du bus.
Ce qu'on peut faire **sans** cible, et que ce module fait :

- **Supprimer les sources de non-déterminisme** : pas de tas, pas
  d'exceptions (module 06), pas de récursion, bornes de boucle statiques.
- **Rendre les boucles bornées visibles.** `for I in Values'Range` a une borne
  lisible ; un `while` demande un `Loop_Variant` (module 05) et, pour le WCET,
  une borne explicite.
- **Choisir un modèle d'exécution analysable** : Ravenscar.

Le reste — mesure sur cible, analyse statique du pipeline, marge de 20 % —
demande le matériel, et reste hors périmètre de ce dépôt. C'est dit, pas
survolé.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod07-ring_buffer.ads`](src/mod07-ring_buffer.ads) | File à capacité fixe, contrats FIFO avec `Ghost` |
| [`src/mod07-ring_buffer.adb`](src/mod07-ring_buffer.adb) | Trois corps, aucune allocation |
| [`tests/test_ring_buffer.adb`](tests/test_ring_buffer.adb) | Quatre cas, dont le tour complet du tampon |
| [`ravenscar/profile.adc`](ravenscar/profile.adc) | Le profil, avec ce qu'il interdit et pourquoi |
| [`ravenscar/src/cyclic.adb`](ravenscar/src/cyclic.adb) | Tâche périodique et objet protégé, au niveau bibliothèque |
| [`../../scripts/stack-usage.sh`](../../scripts/stack-usage.sh) | L'analyse de pile, rejouable |

---

## 3. Exercices

1. Ajouter `X : access Integer := new Integer'(0);` dans `Cyclic` et
   reconstruire. Quel message, et de quelle restriction vient-il ?
2. Remplacer `delay until Next;` par `delay 0.010;` dans la tâche périodique.
   Que dit le compilateur ? Et si le profil Ravenscar était absent, quel
   défaut de conception resterait ?
3. Retirer l'aspect `Ghost` de `Element` et comparer la taille du binaire
   avant/après. Qu'est-ce que cela dit du coût d'une spécification formelle ?
4. Lancer `stack-usage.sh` après avoir ajouté un `Put_Line` dans
   `Ring_Buffer`. Quelle trame change de nature, et pourquoi est-ce
   inacceptable dans du code de vol ?
5. Écrire la boucle de `Push` de façon récursive, et expliquer pourquoi
   l'analyse de pile devient impossible.

---

## 4. Pour l'entretien

> **« Comment garantissez-vous l'absence d'allocation dynamique ? »**
> Par `pragma Restrictions (No_Allocators)` et `No_Dependence =>
> Ada.Unchecked_Deallocation`, vérifiées à la compilation et à l'édition de
> liens. La règle de codage devient une propriété du programme, pas une
> consigne. Les structures à capacité fixe s'écrivent alors avec des tableaux
> contraints ordinaires — il n'y a rien à construire.

> **« Ravenscar, c'est quoi exactement ? »**
> Un profil de restrictions qui réduit le modèle de tâches à ce que les
> théorèmes d'ordonnançabilité savent traiter : tâches périodiques de priorité
> fixe au niveau bibliothèque, objets protégés à plafond de priorité, délais
> absolus. Ce n'est pas une bibliothèque, c'est un `pragma` vérifié par le
> compilateur.

> **« Comment bornez-vous la pile ? »**
> `-fstack-usage` donne la trame de chaque sous-programme et signale les
> trames non statiques ; sur ce dépôt, aucune unité embarquée n'en a. Mais les
> trames ne suffisent pas : il faut le chemin d'appel le plus profond, ce qui
> demande GNATstack ou une mesure sur cible avec motif de remplissage. Je sais
> distinguer ce que j'ai mesuré de ce que je n'ai pas mesuré.

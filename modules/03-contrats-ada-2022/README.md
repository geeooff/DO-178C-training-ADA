# Module 03 — Contrats Ada 2022

> **Durée estimée** : 1 journée
> **Prérequis** : modules 00 à 02

---

## Objectifs pédagogiques

1. Écrire `Pre`, `Post`, `Type_Invariant`, `Static_Predicate` et
   `Contract_Cases`, et savoir lequel dit quoi.
2. Remplacer la **programmation défensive** par un contrat, et comprendre
   pourquoi c'est un gain de certification et pas seulement d'élégance.
3. Savoir ce que `-gnata` change, et ce qu'il ne change pas.
4. Comprendre en quoi un contrat peut **être** une exigence de bas niveau, et
   à quelles conditions.
5. Connaître deux pièges vérifiés qui coûtent une demi-journée si on ne les
   connaît pas.

---

## 1. Le cours

### 1.1 Le contrat remplace la défense

Voici du code C# ordinaire, et parfaitement raisonnable :

```csharp
public void Fill(int amount)
{
    if (amount < 0) throw new ArgumentOutOfRangeException(nameof(amount));
    if (_level + amount > _capacity) throw new InvalidOperationException();
    _level += amount;
}
```

Deux tests, dans le corps, exécutés à chaque appel, y compris quand l'appelant
vient de vérifier la même chose. En Ada :

```ada
procedure Fill (T : in out Fuel_Tank; Amount : Litres)
with
  Pre  => Amount <= Ullage (T),
  Post => Level (T) = Level (T'Old) + Amount
          and then Capacity (T) = Capacity (T'Old);
```

et le corps est d'une ligne :

```ada
T.Content := T.Content + Amount;
```

Trois choses ont changé, et chacune compte en certification :

- **La responsabilité est nommée.** `Pre` est ce que l'appelant doit garantir,
  `Post` ce que l'appelé rend. Le contrat dit *qui* a tort quand ça casse.
- **Le test défensif disparaît.** Un test que rien n'exige est du code sans
  exigence, que le §6.4.4 demande de justifier ou de supprimer.
- **Le même texte sert deux fois.** Compilé avec `-gnata`, le contrat
  s'exécute. Analysé par `gnatprove`, il se démontre — **chez chaque
  appelant**. Aucun commentaire, aucun `Debug.Assert`, aucune annotation
  XML-doc ne fait cela.

> **Écart C# à retenir** : les *Code Contracts* de .NET existaient, faisaient
> à peu près cela… et ont été abandonnés. Il ne reste que `Debug.Assert`, qui
> disparaît en *Release* et ne prouve rien. En Ada, le contrat fait partie de
> la spécification du sous-programme, pas de son implémentation.

### 1.2 Les cinq formes, et ce qu'elles disent

| Aspect | Portée | Vérifié quand |
|---|---|---|
| `Pre` | un appel | à l'entrée, à la charge de l'appelant |
| `Post` | un appel | à la sortie, à la charge de l'appelé |
| `Type_Invariant` | un type privé | aux frontières du paquetage |
| `Static_Predicate` | un sous-type | à toute affectation ou conversion |
| `Contract_Cases` | un appel | table de décision : gardes **exhaustives et disjointes** |

`Contract_Cases` mérite d'être connu, parce qu'il ressemble beaucoup à ce
qu'un rédacteur d'exigences écrit spontanément :

```ada
Contract_Cases =>
  (Amount <= Level (From) and then Amount <= Ullage (To) => Done,
   others                                                => not Done)
```

`gnatprove` vérifie que les gardes couvrent tous les cas et ne se recouvrent
pas. Une exigence de bas niveau incomplète ou contradictoire devient donc une
**erreur d'outil**, pas une remarque de revue.

### 1.3 L'invariant : l'encapsulation qui se prouve

```ada
type Fuel_Tank is private;

private
   type Fuel_Tank is record
      Max     : Litres := 0;
      Content : Litres := 0;
   end record
   with Type_Invariant => Fuel_Tank.Content <= Fuel_Tank.Max;
```

Personne, hors du paquetage, ne peut fabriquer un réservoir dont le contenu
dépasse la capacité. Ce n'est ni une convention ni une revue : c'est le
langage. Et l'invariant étant écrit **une fois**, il ne peut pas se
désynchroniser des huit sous-programmes qui manipulent le type.

Conséquence directe sur le code : `Ullage` s'écrit

```ada
function Ullage (T : Fuel_Tank) return Litres is (Capacity (T) - Level (T));
```

sans garde. La soustraction ne peut pas passer sous zéro, non parce qu'on l'a
testé, mais parce que l'invariant l'interdit — et `gnatprove` s'en sert pour
décharger la vérification de plage.

### 1.4 `-gnata`, et ce qu'il ne change pas

`-gnata` active l'évaluation des assertions à l'exécution. Sans lui, les
contrats sont **ignorés par le compilateur** — mais toujours analysés par
`gnatprove`. C'est un point de configuration important :

| | Contrat exécuté | Contrat prouvé |
|---|---|---|
| `-gnata` seul | oui | non |
| `gnatprove` seul | non | oui |
| Les deux (ce dépôt) | oui | oui |
| Ni l'un ni l'autre | non | non — le contrat est un commentaire |

En projet réel, on compile souvent **sans** `-gnata` pour la cible — les
contrats coûteraient du temps réel — et **avec** pour les campagnes de test.
Cela s'appelle du code différent entre vérification et production, et il faut
le justifier. La sortie de secours est de prouver les contrats, et alors de ne
plus avoir besoin de les exécuter du tout.

### 1.5 Deux pièges vérifiés

**`'Old` doit nommer une entité.** Écrire `Level (T)'Old` est refusé dès que
l'expression est potentiellement non évaluée — c'est-à-dire dès qu'il y a un
`and then`. La forme correcte est `Level (T'Old)` : on prend la copie de
l'objet, puis on l'interroge. Le message du compilateur cite RM 6.1.1(27) et
propose `pragma Unevaluated_Use_Of_Old (Allow)` — à ne pas suivre : la forme
correcte est plus claire **et** copie moins.

**`Type_Invariant` + `'Old` dans `Contract_Cases` = fausse alerte.** Avec
GNAT 16.1.0, mettre un `'Old` dans une *conséquence* de `Contract_Cases`, sur
un type porteur d'un `Type_Invariant`, fait lever une `failed invariant` à
l'exécution alors que l'invariant est respecté. Le même énoncé écrit dans un
`Post` fonctionne. Le module répartit donc les rôles :

```ada
Contract_Cases => (...)   --  la table de décision
Post           => (...)   --  la condition de cadre, avec 'Old
```

Ce qui, au passage, se lit mieux.

**Et un troisième, côté SPARK** : un `Type_Invariant` ne peut pas être posé
sur la déclaration privée, seulement sur la **complétion**. `gnatprove`
refuse la première forme avec un message clair. La raison est saine : un
invariant doit s'exprimer sur la représentation réelle, sinon il dépendrait
de fonctions qu'il faudrait elles-mêmes prouver terminantes et sans effet.

### 1.6 Un contrat est-il une exigence de bas niveau ?

Il peut l'être, et c'est un vrai sujet de discussion en projet.

**Pour** : une LLR doit être vérifiable et traçable. Un `Post` est vérifiable
par preuve ou par test, il est écrit dans le même fichier que le code — donc
il ne peut pas diverger — et l'annotation `@satisfies` de ce dépôt le relie à
la HLR.

**Contre** : la DO-178C attend des LLR qu'elles soient produites par le
processus de *conception* (§5.2), **avant** le code, et revues comme telles
(A-4). Un contrat écrit en même temps que le corps n'a pas été revu contre les
exigences de haut niveau ; il décrit ce que le code fait, pas ce qu'il devait
faire.

En pratique, les projets qui font ce choix rédigent les contrats **à partir**
des LLR, dans un ordre qui préserve l'indépendance, et l'écrivent dans leur
plan de développement logiciel. C'est admissible : la DO-333 prévoit
explicitement qu'une exigence, de haut ou de bas niveau, soit exprimée en
notation formelle (chapitre FM.5, processus de développement), à condition
que la notation ait une sémantique définie sans ambiguïté — ce qui est le
cas des aspects Ada 2022 tels que SPARK les interprète.

---

## 2. Le code du module

| Fichier | Contenu |
|---|---|
| [`src/mod03-tank.ads`](src/mod03-tank.ads) | Les cinq formes de contrat, et les trois pièges annotés |
| [`src/mod03-tank.adb`](src/mod03-tank.adb) | Des corps sans une seule ligne défensive |
| [`src/main.adb`](src/main.adb) | Les contrats à l'exécution, y compris une précondition violée |
| [`tests/test_tank.adb`](tests/test_tank.adb) | Neuf cas, dix-neuf vérifications |

Résultat : compilation sans avertissement, preuve complète, 100 % MC/DC.

---

## 3. Exercices

1. Supprimer la précondition de `Fill` et relancer la preuve. Que dit
   `gnatprove`, et **où** le dit-il — dans `Fill`, ou chez l'appelant ?
2. Rendre les gardes de `Contract_Cases` non exhaustives (retirer `others`).
   Le compilateur accepte-t-il ? Et `gnatprove` ?
3. Compiler le module sans `-gnata` et relancer la campagne. Le cas
   `precondition_rejects_bad_call` passe-t-il encore ? Que faut-il en
   conclure sur la valeur d'un test de contrat ?
4. Remettre le `'Old` dans une conséquence de `Contract_Cases` et reproduire
   la fausse alerte du §1.5. Écrire la fiche d'anomalie correspondante.

---

## 4. Pour l'entretien

> **« Un contrat, ça remplace les tests ? »**
> Non — ça remplace la programmation *défensive*, et ça permet de remplacer
> certains tests par de la preuve, ce que la DO-333 encadre. Un `Post` prouvé
> vaut pour **toutes** les entrées ; un test vaut pour celles qu'on a écrites.
> Mais la preuve ne dit rien de l'adéquation aux exigences de haut niveau :
> il reste des tests à faire.

> **« Pre ou Post, qui a la charge ? »**
> `Pre` est une obligation de l'appelant, `Post` une obligation de l'appelé.
> C'est ce qui rend le contrat utile en revue : quand un appel casse, le
> contrat dit lequel des deux est en faute, sans discussion.

> **« Vous compilez avec les assertions actives en production ? »**
> Non — elles coûtent du temps réel. On les active pour la vérification, et
> on prouve les contrats pour la cible. C'est un écart entre l'exécutable
> vérifié et l'exécutable livré : il se justifie dans le plan, et la preuve
> est ce qui rend la justification tenable.

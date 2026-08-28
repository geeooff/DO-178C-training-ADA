# De C# à Ada — ce qui change vraiment

> Ce document ne vise pas à enseigner la syntaxe Ada : les modules le font.
> Il vise les endroits où un réflexe C# **produit du code faux ou non
> certifiable** en Ada, et ceux où Ada rend inutile un travail que C# impose.

---

## 1. Le renversement de fond

Une phrase à retenir avant tout le reste :

> **En C#, on écrit du code puis on ajoute des contrôles. En Ada, on écrit des
> contraintes puis le code qui les respecte.**

C'est le même déplacement que celui que la DO-178C demande au processus : la
charge de la preuve passe de « démontrer qu'on a pensé à tout » à « démontrer
qu'aucune violation n'est possible ».

---

## 2. Les types

### 2.1 `int` n'est pas une réponse

```csharp
public void SetFuel(int litres)
{
    if (litres < 0 || litres > 10_000)
        throw new ArgumentOutOfRangeException(nameof(litres));
    _litres = litres;
}
```

```ada
subtype Litres is Natural range 0 .. 10_000;

procedure Set_Fuel (Value : Litres);
```

La contrainte est écrite **une fois**, dans le type. Toute affectation, tout
passage de paramètre, toute conversion la vérifie. Voir [module 01](../modules/01-types-et-contraintes/).

### 2.2 Sous-type ou type dérivé — la distinction que C# n'a pas

| | Ada | Équivalent C# |
|---|---|---|
| **Sous-type** | `subtype Celsius is Integer range -60 .. 90;` | aucun ; un `int` avec des gardes |
| **Type dérivé** | `type Litres is delta 0.25 range 0.0 .. 1_024.0;` | un `struct` enveloppant, à la main |

Un sous-type **est** son type de base : il s'additionne avec lui sans
conversion. Un type dérivé ne l'est pas : `Volume + Masse` ne compile pas.

C# 10 a bien les *record structs*, mais rien n'empêche d'écrire
`new Litres(kilos.Value)`. En Ada, la conversion doit nommer le facteur.

### 2.3 Énumérations

```csharp
var id = (SensorId)200;      // compile, produit une valeur invalide
```

```ada
Id := Sensor_Id'Val (200);   --  lève Constraint_Error
```

`Enum.IsDefined` existe en C#, mais il est optionnel, coûteux, et personne ne
l'appelle. En Ada, il n'y a pas de conversion implicite : le contrôle est le
chemin par défaut.

### 2.4 Virgule fixe plutôt que `decimal` ou `double`

C# a `decimal` pour la finance et `double` pour le reste. L'embarqué utilise
la **virgule fixe** : un entier mis à l'échelle, sans exposant, sans `NaN`,
sans mode d'arrondi. Voir [module 01 §1.4](../modules/01-types-et-contraintes/).

> **Piège vérifié** : sans clause `Small` explicite, GNAT prend la puissance
> de deux inférieure au `delta`, et `0.804` devient `0,8037109375`.

---

## 3. Les contrats

### 3.1 Ce que C# a perdu

Les *Code Contracts* de .NET faisaient à peu près ce que fait Ada 2022… et
ont été abandonnés. Il reste `Debug.Assert`, qui disparaît en *Release* et ne
prouve rien.

```ada
procedure Fill (T : in out Fuel_Tank; Amount : Litres)
with
  Pre  => Amount <= Ullage (T),
  Post => Level (T) = Level (T'Old) + Amount;
```

Ce texte sert **deux fois** : compilé avec `-gnata`, il s'exécute ; analysé
par `gnatprove`, il se démontre — **chez chaque appelant**. Aucun
`Debug.Assert`, aucune annotation XML-doc ne fait cela.

### 3.2 Conséquence pratique : la programmation défensive disparaît

Le corps de `Fill` tient en une ligne. Le test d'entrée n'est pas « oublié » :
il est **exigé de l'appelant** et vérifié chez lui. Voir
[module 03](../modules/03-contrats-ada-2022/).

### 3.3 `Type_Invariant` : l'encapsulation qui se prouve

C# a `private` et de la discipline. Ada a `private` **et** un invariant que
personne ne peut violer depuis l'extérieur du paquetage, vérifié à
l'exécution et démontré par la preuve.

---

## 4. Les erreurs

| | C# | Ada en DAL A/B |
|---|---|---|
| Mécanisme normal | exception | **statut de retour** |
| Chemin d'erreur | invisible dans la signature | un paramètre `out` |
| Coût | non borné (déroulement de pile) | un `elsif` |
| Couverture | chemins invisibles au source | chemins ordinaires, mesurables |

Ada **a** des exceptions, et de bonnes. On les interdit quand même, et
`pragma Restrictions (No_Exception_Handlers, No_Exception_Propagation)` le
rend vérifiable. Voir [module 06](../modules/06-erreurs-sans-exceptions/).

> Le réflexe C# le plus coûteux à désapprendre : *« je lève une exception, le
> code appelant s'en occupera »*. En avionique, personne ne s'en occupe — le
> calculateur s'arrête.

---

## 5. La mémoire

| | C# | Ada embarqué |
|---|---|---|
| Allocation | tas + ramasse-miettes | **aucune** |
| Durée de vie | non déterministe | statique |
| Structures dynamiques | `List<T>` | tableau contraint à capacité fixe |
| Garantie | aucune | `pragma Restrictions (No_Allocators)` |

Le ramasse-miettes suffit à exclure C# du temps réel dur : ses pauses ne sont
pas bornées. En Ada, l'absence d'allocation n'est pas une convention, c'est
une erreur de compilation. Voir [module 07](../modules/07-memoire-statique/).

Ce qui reste à surveiller est la **pile**, et `-fstack-usage` la rend
mesurable.

---

## 6. L'objet

| Ada | C# |
|---|---|
| `type T is tagged record …` | `class T` |
| `type U is new T with record …` | `class U : T` |
| `T'Class` | `T` (référence) |
| `overriding function F …` | `override` |
| **`Post'Class`** | **rien** |

Deux différences qui comptent :

- **Le dispatching est visible dans le type.** `Instrument` est un type
  ordinaire (appel statique), `Instrument'Class` accepte n'importe quelle
  extension (appel dispatchant). En C#, tout est potentiellement virtuel sans
  que la signature le dise.
- **`Pre'Class` et `Post'Class` transforment Liskov en obligation de preuve.**
  C'est ce que la DO-332 appelle la *cohérence locale de type*, et ce qu'il
  faudrait sinon re-tester extension par extension. Voir
  [module 08](../modules/08-objet-do332/).

---

## 7. La concurrence

| | C# | Ada / Ravenscar |
|---|---|---|
| Unité | `Task`, `Thread` | `task`, au niveau bibliothèque |
| Exclusion mutuelle | `lock`, `Monitor` | `protected` — c'est un **type** |
| Ordonnancement | pool de threads, priorités indicatives | priorités fixes, plafond de priorité |
| Analysable ? | non | **oui, c'est le but du profil** |

Un objet `protected` n'est pas un mutex qu'on pense à prendre : l'exclusion
est dans le type. Et `pragma Profile (Ravenscar)` interdit tout ce qui rendrait
l'ordonnancement indécidable. Voir [module 07 §1.3](../modules/07-memoire-statique/).

---

## 8. Ce qui n'a pas d'équivalent, dans un sens ou dans l'autre

**En Ada et pas en C# :**

- les sous-types contraints et les types dérivés ;
- `Pre` / `Post` / `Type_Invariant` / `Contract_Cases` prouvables ;
- `Global` / `Depends` — le couplage de données déclaré et vérifié ;
- les représentations mémoire spécifiées (`for X'Size use …`, clauses de
  représentation d'enregistrement) ;
- SPARK, et la preuve d'absence d'erreur à l'exécution.

**En C# et pas en Ada embarqué :**

- LINQ, `async`/`await`, la réflexion, les *delegates* — tous exclus, non par
  purisme mais parce qu'ils allouent ou rendent le flot de contrôle
  indécidable ;
- l'écosystème NuGet — en avionique, chaque bibliothèque tierce devrait être
  certifiée avec le produit.

---

## 9. Sept réflexes à désapprendre

1. **« Je prends un `int` et je valide. »** → déclarer un sous-type.
2. **« Je lève une exception. »** → rendre un statut.
3. **« Je fais un `List<T>`. »** → tableau contraint à capacité fixe.
4. **« Je documente la précondition en XML-doc. »** → l'écrire en `Pre`.
5. **« Le GC s'en occupe. »** → il n'y a pas de GC, ni de tas.
6. **« Je mets `virtual` partout, c'est plus souple. »** → chaque site
   dispatchant coûte des cas de couverture, à chaque extension.
7. **« Je teste, donc c'est bon. »** → le test échantillonne, la preuve
   couvre le domaine, et la couverture structurelle trouve ce que ni l'un ni
   l'autre n'a demandé.

---

## 10. Un réflexe à garder

C# a appris à écrire des **API qui rendent l'usage incorrect difficile** :
types non nullables, immutabilité, constructeurs qui valident. C'est
exactement l'état d'esprit d'Ada, avec des outils plus tranchants.

La bonne nouvelle pour un développeur C# : ce n'est pas un changement de
philosophie, c'est la même philosophie avec un langage qui la fait respecter.

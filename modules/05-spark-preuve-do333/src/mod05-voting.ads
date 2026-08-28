--  ---------------------------------------------------------------------------
--  Vote de capteurs et parcours prouvés — module 05.
--
--  Le module 04 a montré ce que l'analyse de FLOT démontre sans prouveur.
--  Celui-ci passe à la PREUVE : gnatprove transforme chaque contrat en
--  obligations de vérification, les envoie à CVC5, et ne rend la main que
--  si toutes sont déchargées.
--
--  Le vote à trois voies est le bon exemple : c'est un vrai motif avionique
--  (trois capteurs, on retient la valeur médiane pour éliminer un capteur en
--  panne), sa spécification formelle demande un vrai effort de rédaction, et
--  c'est précisément là que se trouve la valeur — écrire le contrat, c'est
--  faire le travail de conception que la relecture ferait mal.
--  ---------------------------------------------------------------------------

package Mod05.Voting
  with SPARK_Mode => On
is

   subtype Litres is Natural range 0 .. 10_000;

   Low_Level_Threshold : constant Litres := 500;

   type Reading_Array is array (Positive range <>) of Litres;

   --  --- 1. Vote médian à trois voies

   --  Combien des trois mesures sont inférieures ou égales à Value.
   --  Fonction auxiliaire de spécification : elle n'existe que pour rendre
   --  la postcondition lisible.
   --
   --  @satisfies LLR-M05-001
   function Count_At_Most (A, B, C, Value : Litres) return Natural
   is (Boolean'Pos (A <= Value)
       + Boolean'Pos (B <= Value)
       + Boolean'Pos (C <= Value))
   with Global => null;

   --  @satisfies LLR-M05-001
   function Count_At_Least (A, B, C, Value : Litres) return Natural
   is (Boolean'Pos (A >= Value)
       + Boolean'Pos (B >= Value)
       + Boolean'Pos (C >= Value))
   with Global => null;

   --  Valeur médiane des trois mesures.
   --
   --  La postcondition est la DÉFINITION de la médiane, pas une description
   --  du corps : le résultat est l'une des trois entrées, au moins deux
   --  entrées lui sont inférieures ou égales, et au moins deux lui sont
   --  supérieures ou égales. Un capteur en panne, isolé haut ou bas, ne peut
   --  donc pas être retenu.
   --
   --  @satisfies LLR-M05-002
   function Mid_Value (A, B, C : Litres) return Litres
   with
     Global => null,
     Post   =>
       (Mid_Value'Result = A
        or else Mid_Value'Result = B
        or else Mid_Value'Result = C)
       and then Count_At_Most (A, B, C, Mid_Value'Result) >= 2
       and then Count_At_Least (A, B, C, Mid_Value'Result) >= 2;

   --  --- 2. Parcours avec invariant quantifié

   --  Cherche le premier réservoir sous le seuil bas.
   --
   --  La postcondition dit deux choses que le test ne pourrait vérifier que
   --  sur les cas écrits : quand un réservoir est trouvé, AUCUN de ceux qui
   --  le précèdent n'était bas ; quand aucun ne l'est, AUCUN de tous ne
   --  l'était. Le « pour tout » est ici démontré, pas échantillonné.
   --
   --  @satisfies LLR-M05-003
   procedure Find_First_Low
     (Values : Reading_Array; Index : out Natural; Found : out Boolean)
   with
     Global => null,
     Post   =>
       (if Found
        then
          Index in Values'Range
          and then Values (Index) < Low_Level_Threshold
          and then (for all K in Values'First .. Index - 1 =>
                      Values (K) >= Low_Level_Threshold)
        else
          Index = 0
          and then (for all K in Values'Range =>
                      Values (K) >= Low_Level_Threshold));

   --  --- 3. Terminaison d'une boucle non bornée

   --  Nombre de charges de `Step` litres pour atteindre `Target`.
   --
   --  Une division ferait l'affaire. La boucle est ici pour montrer
   --  Loop_Variant : sur un `while`, rien ne garantit a priori qu'on sorte,
   --  et c'est le variant qui l'établit. En DAL A/B, une boucle dont la
   --  terminaison n'est pas démontrée est un défaut, pas une élégance
   --  manquante.
   --
   --  @satisfies LLR-M05-004
   function Refuel_Steps (Target : Litres; Step : Positive) return Natural
   with Global => null, Post => Refuel_Steps'Result <= Target;

end Mod05.Voting;

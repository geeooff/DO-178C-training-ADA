--  ---------------------------------------------------------------------------
--  Un réservoir, et son contrat — module 03.
--
--  Le type est PRIVÉ : personne hors de ce paquetage ne peut fabriquer un
--  réservoir dont le niveau dépasse la capacité. Ce n'est pas une convention
--  de nommage, ni une revue de code : c'est le langage.
--
--  Et ce qui est vrai de l'état est écrit une fois, dans Type_Invariant, au
--  lieu d'être revérifié au début de chaque sous-programme. En DO-178C, un
--  contrat de ce genre est un candidat naturel à l'expression d'une exigence
--  de bas niveau (LLR) : il est lisible par un humain, vérifiable par un
--  outil, et il ne peut pas diverger du code puisqu'il en fait partie.
--  ---------------------------------------------------------------------------

package Mod03.Tank
  with SPARK_Mode => On
is

   subtype Litres is Natural range 0 .. 10_000;

   --  --- Prédicats : restreindre un domaine par une propriété

   type Tank_Id is (Left_Wing, Right_Wing, Centre, Trim);

   --  Les réservoirs de voilure. Un prédicat STATIQUE se résout à la
   --  compilation : il autorise les `case` exhaustifs, contrairement au
   --  prédicat dynamique.
   subtype Wing_Tank_Id is Tank_Id
   with Static_Predicate => Wing_Tank_Id in Left_Wing | Right_Wing;

   --  --- Invariant de type : ce qui est vrai de tout réservoir, toujours

   --  L'invariant lui-même est écrit sur la COMPLÉTION, dans la partie
   --  privée : SPARK refuse un Type_Invariant posé sur la déclaration
   --  privée. La raison est saine — l'invariant doit pouvoir s'exprimer sur
   --  la représentation réelle, sinon il dépendrait de fonctions qu'il
   --  faudrait elles-mêmes prouver terminantes et sans effet.
   type Fuel_Tank is private;

   function Capacity (T : Fuel_Tank) return Litres;

   function Level (T : Fuel_Tank) return Litres;

   --  Le volume encore disponible. La soustraction ne peut pas passer sous
   --  zéro — non parce qu'on l'a testé, mais parce que l'invariant l'interdit.
   --
   --  @satisfies LLR-M03-001
   function Ullage (T : Fuel_Tank) return Litres
   is (Capacity (T) - Level (T));

   --  @satisfies LLR-M03-002
   function Create (Max : Litres) return Fuel_Tank
   with
     Post => Capacity (Create'Result) = Max and then Level (Create'Result) = 0;

   --  La précondition dit ce que l'APPELANT doit garantir. Elle remplace la
   --  programmation défensive : pas de test redondant en tête de corps, pas
   --  de code d'erreur à propager, et une obligation vérifiable par preuve.
   --
   --  Note d'écriture : `Level (T'Old)` et non `Level (T)'Old`. Le préfixe
   --  de 'Old doit nommer une entité dès que l'expression est potentiellement
   --  non évaluée — ce qu'un `and then` rend vrai. Le compilateur le refuse
   --  avec un message explicite (RM 6.1.1(27)) ; l'ignorer coûterait une
   --  copie inutile de l'objet avant chaque appel.
   --
   --  @satisfies LLR-M03-003
   procedure Fill (T : in out Fuel_Tank; Amount : Litres)
   with
     Pre  => Amount <= Ullage (T),
     Post =>
       Level (T) = Level (T'Old) + Amount
       and then Capacity (T) = Capacity (T'Old);

   --  @satisfies LLR-M03-004
   procedure Drain (T : in out Fuel_Tank; Amount : Litres)
   with
     Pre  => Amount <= Level (T),
     Post =>
       Level (T) = Level (T'Old) - Amount
       and then Capacity (T) = Capacity (T'Old);

   --  Contract_Cases est une table de décision exécutable : les gardes
   --  doivent être exhaustives et mutuellement exclusives, et gnatprove le
   --  vérifie. C'est la forme la plus proche d'une exigence de bas niveau
   --  écrite en français qu'offre le langage.
   --
   --  PIÈGE VÉRIFIÉ (GNAT 16.1.0) : mettre un 'Old dans une CONSÉQUENCE de
   --  Contract_Cases, sur un type porteur d'un Type_Invariant, fait lever une
   --  fausse « failed invariant » à l'exécution dès que -gnata est actif. Le
   --  même énoncé écrit dans un Post fonctionne, et le retirer de l'un pour
   --  le mettre dans l'autre ne change rien à ce qui est vérifié. D'où la
   --  répartition ci-dessous : Contract_Cases porte la table de décision,
   --  Post porte la condition de cadre (« ce qui n'a pas bougé »).
   --
   --  @satisfies LLR-M03-005
   procedure Transfer
     (From   : in out Fuel_Tank;
      To     : in out Fuel_Tank;
      Amount : Litres;
      Done   : out Boolean)
   with
     Contract_Cases =>
       (Amount <= Level (From) and then Amount <= Ullage (To) => Done,
        others                                                => not Done),
     Post           =>
       (if Done
        then
          Level (From) = Level (From'Old) - Amount
          and then Level (To) = Level (To'Old) + Amount
        else
          Level (From) = Level (From'Old)
          and then Level (To) = Level (To'Old));

private

   --  Invariant : un réservoir ne contient jamais plus que sa capacité.
   --  Écrit ici une fois, il rend inutile tout test défensif ailleurs.
   type Fuel_Tank is record
      Max     : Litres := 0;
      Content : Litres := 0;
   end record
   with Type_Invariant => Fuel_Tank.Content <= Fuel_Tank.Max;

   function Capacity (T : Fuel_Tank) return Litres
   is (T.Max);

   function Level (T : Fuel_Tank) return Litres
   is (T.Content);

end Mod03.Tank;

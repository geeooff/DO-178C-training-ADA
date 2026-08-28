--  ---------------------------------------------------------------------------
--  Jaugeage multi-réservoirs — module 02.
--
--  Ce paquetage existe pour une raison précise : chacun de ses
--  sous-programmes provoque une vérification que GNAT insère TOUT SEUL dans
--  le code objet. Contrôle d'indice, contrôle de plage, contrôle de
--  débordement. Le module mesure ce qu'elles coûtent, montre le code qu'elles
--  produisent, et explique à quelles conditions on a le droit de les enlever.
--  ---------------------------------------------------------------------------

package Mod02.Fuel_Gauge
  with SPARK_Mode => On
is

   Tank_Count : constant := 4;

   subtype Tank_Index is Positive range 1 .. Tank_Count;

   subtype Litres is Natural range 0 .. 10_000;

   type Tank_Array is array (Tank_Index) of Litres;

   --  Le total de quatre réservoirs peut atteindre 40 000 litres : il ne
   --  tient PAS dans Litres. Le dire dans un type distinct évite le
   --  débordement au lieu de le rattraper.
   subtype Total_Litres is Natural range 0 .. Tank_Count * 10_000;

   --  Somme des réservoirs.
   --
   --  Trois vérifications ici : le contrôle d'indice à chaque accès au
   --  tableau, le contrôle de débordement sur l'addition, et le contrôle de
   --  plage à l'affectation dans Total_Litres. Aucune n'apparaît dans le
   --  source — toutes apparaissent dans le code objet.
   --
   --  @satisfies LLR-M02-001
   function Total (Tanks : Tank_Array) return Total_Litres
   with Post => Total'Result <= Tank_Count * Litres'Last;

   --  Lecture par un indice VENU DE L'EXTÉRIEUR : d'une trame, d'un
   --  paramètre de configuration, d'un opérateur. Le type ne peut rien
   --  garantir sur lui, donc le contrôle est inévitable — et c'est ici qu'il
   --  doit être écrit une fois pour toutes, plutôt que laissé à
   --  Constraint_Error.
   --
   --  @satisfies LLR-M02-002
   procedure Read_Tank
     (Tanks : Tank_Array;
      Index : Integer;
      Value : out Litres;
      Valid : out Boolean)
   with
     Post =>
       Valid = (Index in Tank_Index)
       and then (if Valid then Value = Tanks (Index))
       and then (if not Valid then Value = 0);

   --  Moyenne des réservoirs. La division par Tank_Count ne peut pas être
   --  une division par zéro — mais GNAT insère quand même le contrôle si
   --  rien ne le lui démontre. Voir le module 05.
   --
   --  @satisfies LLR-M02-003
   function Average (Tanks : Tank_Array) return Litres
   with Post => Average'Result <= Litres'Last;

end Mod02.Fuel_Gauge;

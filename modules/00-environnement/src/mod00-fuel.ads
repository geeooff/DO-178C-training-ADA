--  Un fragment minuscule du cas d'étude FQMS (jaugeage carburant, DAL B),
--  repris du dépôt frère en C++. Il est ici pour une seule raison : donner
--  à la chaîne d'outils quelque chose de non trivial à prouver.

package Mod00.Fuel
  with SPARK_Mode => On
is

   Max_Litres : constant := 10_000;

   --  En C#, `int` accepte 10_001 litres et c'est au code de le refuser.
   --  En Ada, la borne fait partie du type : toute affectation hors plage
   --  est un défaut détecté par le compilateur, par une vérification à
   --  l'exécution, ou par la preuve. Trois filets, un seul énoncé.
   subtype Litres is Natural range 0 .. Max_Litres;

   --  Addition saturante. La postcondition énonce *tout* le comportement :
   --  c'est elle, et non le corps, qui fait foi pour l'appelant et pour
   --  gnatprove.
   function Saturating_Add (Left, Right : Litres) return Litres
   with
     Post =>
       Saturating_Add'Result
       = (if Left + Right > Max_Litres then Max_Litres else Left + Right);

end Mod00.Fuel;

with Ada.Command_Line;
with Ada.Text_IO;
with Mod02.Fuel_Gauge;

--  Démonstration du COMPORTEMENT des vérifications.
--
--  Ce programme se compile de deux façons, sans changer une ligne :
--
--     gprbuild -P modules/02-verifications-execution/mod02.gpr
--     gprbuild -P ... --subdirs=sans-controles -cargs -gnatp
--
--  Avec les contrôles, le dépassement lève Constraint_Error et le programme
--  le dit. Sans, il rend un résultat faux et continue. Toute la question du
--  module tient dans cet écart.

procedure Main is

   package Gauge renames Mod02.Fuel_Gauge;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   Tanks : constant Gauge.Tank_Array := [2_500, 3_000, 1_200, 800];

   --  Non statique : le compilateur ne peut pas décider à l'avance de ce qui
   --  va se passer. C'est le cas réel — une valeur venue d'un bus.
   Nearly_Max : constant Integer :=
     Integer'Last - Ada.Command_Line.Argument_Count;

   Value   : Gauge.Litres;
   Valid   : Boolean;
   Overrun : Integer;

begin
   Titre ("Ce que le code fait quand tout va bien");
   Ada.Text_IO.Put_Line ("Total   :" & Gauge.Total (Tanks)'Image & " L");
   Ada.Text_IO.Put_Line ("Moyenne :" & Gauge.Average (Tanks)'Image & " L");

   Titre ("Indice hors bornes : traité, pas subi");
   Gauge.Read_Tank (Tanks, 2, Value, Valid);
   Ada.Text_IO.Put_Line
     ("Indice 2 :" & Value'Image & " L, valide = " & Valid'Image);
   Gauge.Read_Tank (Tanks, 9, Value, Valid);
   Ada.Text_IO.Put_Line
     ("Indice 9 :" & Value'Image & " L, valide = " & Valid'Image);

   Titre ("Débordement : avec contrôles, ou sans");
   begin
      Overrun := Nearly_Max + 1;
      Ada.Text_IO.Put_Line
        ("Aucune exception. Integer'Last + 1 =" & Overrun'Image);
      Ada.Text_IO.Put_Line
        ("Les contrôles sont SUPPRIMÉS : le résultat est faux et le");
      Ada.Text_IO.Put_Line ("programme continue comme si de rien n'était.");
   exception
      when Constraint_Error =>
         Ada.Text_IO.Put_Line
           ("Constraint_Error levée : les contrôles sont ACTIFS.");
   end;
end Main;

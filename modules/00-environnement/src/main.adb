with Ada.Text_IO;
with Fuel;

--  Exécutable témoin : il couvre les deux branches de Saturating_Add, ce qui
--  donne à gnatcov de quoi mesurer autre chose que 0 %.

procedure Main is
   Saturated : constant Fuel.Litres := Fuel.Saturating_Add (7_500, 4_000);
   Exact     : constant Fuel.Litres := Fuel.Saturating_Add (1_200, 300);
begin
   Ada.Text_IO.Put_Line ("Saturé :" & Saturated'Image);
   Ada.Text_IO.Put_Line ("Exact  :" & Exact'Image);
end Main;

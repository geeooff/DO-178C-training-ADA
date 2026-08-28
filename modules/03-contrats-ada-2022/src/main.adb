with Ada.Assertions;
with Ada.Command_Line;
with Ada.Text_IO;
with Mod03.Tank;

--  Démonstration : un contrat n'est pas un commentaire. Compilé avec -gnata,
--  il s'exécute ; analysé par gnatprove, il se démontre. Le même texte sert
--  aux deux, ce qu'aucun commentaire ne peut faire.

procedure Main is

   package Tank renames Mod03.Tank;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   procedure Montrer (Nom : String; T : Tank.Fuel_Tank);

   procedure Montrer (Nom : String; T : Tank.Fuel_Tank) is
   begin
      Ada.Text_IO.Put_Line
        (Nom
         & " : niveau"
         & Tank.Level (T)'Image
         & " L, creux"
         & Tank.Ullage (T)'Image
         & " L, capacité"
         & Tank.Capacity (T)'Image
         & " L");
   end Montrer;

   Left  : Tank.Fuel_Tank := Tank.Create (5_000);
   Right : Tank.Fuel_Tank := Tank.Create (5_000);

   --  Non statique : le compilateur ne peut pas anticiper la violation.
   Too_Much : constant Tank.Litres :=
     9_000 - Tank.Litres (Ada.Command_Line.Argument_Count);

   Done : Boolean;

begin
   Titre ("Un type privé et son invariant");
   Tank.Fill (Left, 3_200);
   Montrer ("Gauche", Left);
   Montrer ("Droit ", Right);

   Titre ("Contract_Cases : une table de décision exécutable");
   Tank.Transfer (Left, Right, 1_200, Done);
   Ada.Text_IO.Put_Line ("Transfert de 1 200 L : " & Done'Image);
   Montrer ("Gauche", Left);
   Montrer ("Droit ", Right);

   Tank.Transfer (Left, Right, 9_999, Done);
   Ada.Text_IO.Put_Line ("Transfert de 9 999 L : " & Done'Image);
   Ada.Text_IO.Put_Line
     ("Rien n'a bougé : la seconde garde de Contract_Cases l'exige.");
   Montrer ("Gauche", Left);

   Titre ("Prédicat statique");
   for Each in Tank.Tank_Id loop
      Ada.Text_IO.Put_Line
        (Each'Image
         & " est un réservoir de voilure : "
         & Boolean'Image (Each in Tank.Wing_Tank_Id));
   end loop;

   Titre ("Une précondition violée");
   begin
      --  Left ne contient pas 9 000 L de creux : la précondition de Fill
      --  n'est pas tenue. Avec -gnata, le contrat se retourne contre
      --  l'appelant, à l'endroit exact de la faute.
      Tank.Fill (Left, Too_Much);
      Ada.Text_IO.Put_Line ("Aucune exception : les assertions sont OFF.");
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line
           ("Assertion_Error : la précondition de Fill a refusé l'appel.");
   end;
end Main;

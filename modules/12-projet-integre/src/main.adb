with Ada.Text_IO;
with Mod12.Fqms;

--  Démonstration : un profil de vol de quinze cycles, joué sur le FQMS.
--  Le même scénario que la démonstration du module 16 du dépôt frère.

procedure Main is

   package Fqms renames Mod12.Fqms;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   procedure Afficher (Cycle : Natural; Result : Fqms.Cycle_Outputs);

   procedure Afficher (Cycle : Natural; Result : Fqms.Cycle_Outputs) is
      Alarme : constant String :=
        (if Result.Imbalance and Result.Low_Level
         then "DESEQ+BAS"
         elsif Result.Imbalance
         then "DESEQUILIBRE"
         elsif Result.Low_Level
         then "BAS NIVEAU"
         else "-");
   begin
      Ada.Text_IO.Put_Line
        ("  cycle"
         & Cycle'Image
         & " | total"
         & Result.Total'Image
         & " kg"
         & " | "
         & Result.Status'Image
         & " | "
         & Alarme);
   end Afficher;

   S      : Fqms.State := Fqms.Initial;
   Result : Fqms.Cycle_Outputs;

   --  Points de jauge : 4 095 points valent la capacité du réservoir.
   Equilibre  : constant Fqms.Raw_Inputs := [2_000, 2_000, 2_000];
   Desequilib : constant Fqms.Raw_Inputs := [3_000, 2_000, 1_000];
   Presque_Vi : constant Fqms.Raw_Inputs := [200, 200, 200];
   Panne_Aile : constant Fqms.Raw_Inputs := [9_999, 2_000, 2_000];

begin
   Titre ("Croisière équilibrée");
   for Cycle in 1 .. 3 loop
      Fqms.Run_Cycle (S, Equilibre, Result);
      Afficher (Cycle, Result);
   end loop;

   Titre ("Déséquilibre : cinq cycles avant que l'alerte ne se lève");
   for Cycle in 4 .. 9 loop
      Fqms.Run_Cycle (S, Desequilib, Result);
      Afficher (Cycle, Result);
   end loop;

   Titre ("Panne de jauge d'aile : l'alerte est CONSERVÉE, pas réévaluée");
   for Cycle in 10 .. 11 loop
      Fqms.Run_Cycle (S, Panne_Aile, Result);
      Afficher (Cycle, Result);
   end loop;
   Ada.Text_IO.Put_Line
     ("  rejets sur l'aile gauche :" & Fqms.Rejects (S, Fqms.Left_Wing)'Image);

   Titre ("Retour équilibré : cinq cycles avant effacement");
   for Cycle in 12 .. 17 loop
      Fqms.Run_Cycle (S, Equilibre, Result);
      Afficher (Cycle, Result);
   end loop;

   Titre ("Bas niveau");
   for Cycle in 18 .. 23 loop
      Fqms.Run_Cycle (S, Presque_Vi, Result);
      Afficher (Cycle, Result);
   end loop;
end Main;

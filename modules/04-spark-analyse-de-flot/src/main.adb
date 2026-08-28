with Ada.Text_IO;
with Mod04.Alarm_Logic;
with Mod04.Fuel_Monitor;

--  Démonstration : ce que l'analyse de flot rend visible.

procedure Main is

   package Monitor renames Mod04.Fuel_Monitor;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   procedure Etat;

   procedure Etat is
   begin
      Ada.Text_IO.Put_Line
        ("  dernière mesure :"
         & Monitor.Last_Reading'Image
         & " L, alarme = "
         & Monitor.Alarm_Active'Image
         & ", mesures ="
         & Monitor.Sample_Count'Image);
   end Etat;

begin
   Titre ("État initial, garanti par Initializes");
   Etat;

   Titre ("Trois mesures");
   Monitor.Update (4_200);
   Etat;
   Monitor.Update (900);
   Etat;
   Monitor.Update (310);
   Etat;
   Ada.Text_IO.Put_Line
     ("  seuil bas :" & Mod04.Alarm_Logic.Low_Level_Threshold'Image & " L");

   Titre ("Reset : Depends => (State => null)");
   Monitor.Reset;
   Etat;
   Ada.Text_IO.Put_Line
     ("  aucune information de l'état précédent n'a traversé le Reset ;");
   Ada.Text_IO.Put_Line
     ("  ce n'est pas une intention, c'est ce que gnatprove a vérifié.");
end Main;

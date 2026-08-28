with Ada.Text_IO;
with Mod06.Sensor_Io;

--  Démonstration : quatre trames, quatre statuts, aucune exception.

procedure Main is

   package Io renames Mod06.Sensor_Io;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   procedure Essayer (Etiquette : String; Input : Io.Frame);

   procedure Essayer (Etiquette : String; Input : Io.Frame) is
      Value  : Io.Litres;
      Status : Io.Status_Code;
   begin
      Io.Decode (Input, Value, Status);
      Ada.Text_IO.Put_Line
        ("  "
         & Etiquette
         & " -> statut "
         & Status'Image
         & ", valeur"
         & Value'Image
         & " L");
   end Essayer;

   function Bonne (Raw : Io.Raw_Value; Age : Io.Age_Ms) return Io.Frame
   is (Raw => Raw, Age => Age, Checksum => Io.Expected_Checksum (Raw, Age));

begin
   Titre ("Quatre trames, quatre statuts");
   Essayer ("trame saine     ", Bonne (3_200, 20));
   Essayer ("trame périmée   ", Bonne (3_200, 900));
   Essayer ("valeur hors plage", Bonne (60_000, 20));
   Essayer ("checksum faux   ", (Raw => 3_200, Age => 20, Checksum => 7));

   Titre ("Agrégation de statuts");
   Ada.Text_IO.Put_Line
     ("  Worst (Ok, Stale_Data)          = "
      & Io.Worst (Io.Ok, Io.Stale_Data)'Image);
   Ada.Text_IO.Put_Line
     ("  Worst (Out_Of_Range, Stale_Data) = "
      & Io.Worst (Io.Out_Of_Range, Io.Stale_Data)'Image);
   Ada.Text_IO.Put_Line
     ("  l'ordre des littéraux du type EST l'ordre de gravité.");
end Main;

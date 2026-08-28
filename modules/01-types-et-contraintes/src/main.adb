with Ada.Text_IO;
with Mod01.Sensors;

--  Démonstration : ce que les types racontent d'eux-mêmes. Les attributs ne
--  sont pas de la curiosité — ils sont la façon Ada d'écrire une borne une
--  seule fois puis de la relire partout, au lieu de la recopier.

procedure Main is

   package Sensors renames Mod01.Sensors;

   --  -gnatys impose une déclaration avant tout corps de sous-programme,
   --  y compris imbriqué : la signature se lit alors sans dérouler le corps.
   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   Full   : constant Sensors.Raw_Count := Sensors.Raw_Count'Last;
   Volume : constant Sensors.Litres := Sensors.To_Litres (Full);
   Mass   : constant Sensors.Kilograms := Sensors.To_Kilograms (Volume);

   Id      : Sensors.Sensor_Id;
   Known   : Boolean;
   Degrees : Sensors.Celsius;
   Clamped : Boolean;

begin
   Titre ("Type modulaire");
   Ada.Text_IO.Put_Line
     ("Raw_Count'Modulus ="
      & Sensors.Raw_Count'Modulus'Image
      & ", 'Last ="
      & Sensors.Raw_Count'Last'Image);
   Ada.Text_IO.Put_Line
     ("4095 + 1 ="
      & Sensors.Next_Count (Full)'Image
      & "  (bouclage défini, pas un débordement)");

   Titre ("Virgule fixe");
   Ada.Text_IO.Put_Line
     ("Litres'Delta ="
      & Sensors.Litres'Delta'Image
      & ", 'Small ="
      & Sensors.Litres'Small'Image);
   Ada.Text_IO.Put_Line
     ("Pleine échelle :" & Volume'Image & " L, soit" & Mass'Image & " kg");

   Titre ("Énumération");
   for Each in Sensors.Sensor_Id loop
      Ada.Text_IO.Put_Line
        (Sensors.Sensor_Id'Pos (Each)'Image & " -> " & Each'Image);
   end loop;

   Sensors.Decode_Sensor_Id (2, Id, Known);
   Ada.Text_IO.Put_Line
     ("Octet 2 décodé : " & Id'Image & ", valide = " & Known'Image);

   Sensors.Decode_Sensor_Id (200, Id, Known);
   Ada.Text_IO.Put_Line
     ("Octet 200 décodé : " & Id'Image & ", valide = " & Known'Image);

   Titre ("Sous-type contraint");
   Ada.Text_IO.Put_Line
     ("Celsius'First ="
      & Sensors.Celsius'First'Image
      & ", 'Last ="
      & Sensors.Celsius'Last'Image);
   Sensors.Clamp_Temperature (150, Degrees, Clamped);
   Ada.Text_IO.Put_Line
     ("150 °C ramené à" & Degrees'Image & ", écrêté = " & Clamped'Image);
end Main;

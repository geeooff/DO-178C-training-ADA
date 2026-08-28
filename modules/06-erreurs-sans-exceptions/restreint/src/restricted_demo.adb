with Ada.Text_IO;
with Mod06.Sensor_Io;

--  Ce programme n'a rien de remarquable — et c'est exactement le propos.
--  Il est construit sous `No_Exception_Handlers` et
--  `No_Exception_Propagation`, avec les vérifications supprimées par -gnatp.
--  S'il se lie, c'est que Mod06.Sensor_Io ne repose sur aucune exception.

procedure Restricted_Demo is

   package Io renames Mod06.Sensor_Io;

   Input  : constant Io.Frame :=
     (Raw => 3_200, Age => 20, Checksum => Io.Expected_Checksum (3_200, 20));
   Value  : Io.Litres;
   Status : Io.Status_Code;

begin
   Io.Decode (Input, Value, Status);
   Ada.Text_IO.Put_Line
     ("Profil sans exceptions : statut "
      & Status'Image
      & ", valeur"
      & Value'Image
      & " L");
end Restricted_Demo;

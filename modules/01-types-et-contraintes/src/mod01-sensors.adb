package body Mod01.Sensors
  with SPARK_Mode => On
is

   function To_Litres (Raw : Raw_Count) return Litres
   is
      --  fixe * entier reste du fixe : le résultat garde le pas de 0,25.
      --  Maximum atteignable : 0,25 x 4095 = 1023,75 L, dans la plage.
      (Litres_Per_Count * Integer (Raw));

   function To_Kilograms (Volume : Litres) return Kilograms
   is
      --  fixe x fixe donne `universal_fixed`, que le langage REFUSE de
      --  convertir implicitement : il faut nommer le type d'arrivée. C'est
      --  précisément le point de contrôle qui a manqué au Mars Climate
      --  Orbiter — la conversion existe toujours, mais elle est écrite,
      --  donc relisible et vérifiable.
      --
      --  Le résultat est tronqué au pas de Kilograms, soit 0,25 kg :
      --  100 L x 0,804 = 80,4 kg devient 80,25 kg. Une troncature n'est pas
      --  un défaut tant qu'elle est SPÉCIFIÉE ; c'est la DO-178C §6.3.4.f
      --  (« accuracy ») qui demande de la justifier, pas de l'éviter.
      (Kilograms (Volume * Density_Jet_A1));

   procedure Decode_Sensor_Id
     (Octet : Natural; Id : out Sensor_Id; Valid : out Boolean) is
   begin
      if Octet <= Sensor_Id'Pos (Sensor_Id'Last) then
         Id := Sensor_Id'Val (Octet);
         Valid := True;
      else
         --  Id reçoit tout de même une valeur : laisser un paramètre `out`
         --  non initialisé sur un chemin est un défaut que l'analyse de flot
         --  de SPARK signale (module 04).
         Id := Sensor_Id'First;
         Valid := False;
      end if;
   end Decode_Sensor_Id;

   procedure Clamp_Temperature
     (Raw : Integer; Value : out Celsius; Clamped : out Boolean) is
   begin
      if Raw < Celsius'First then
         Value := Celsius'First;
         Clamped := True;
      elsif Raw > Celsius'Last then
         Value := Celsius'Last;
         Clamped := True;
      else
         Value := Raw;
         Clamped := False;
      end if;
   end Clamp_Temperature;

end Mod01.Sensors;

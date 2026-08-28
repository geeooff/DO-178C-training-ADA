package body Mod06.Sensor_Io
  with SPARK_Mode => On
is

   procedure Decode
     (Input : Frame; Value : out Litres; Status : out Status_Code) is
   begin
      --  L'ordre des tests est celui de la gravité décroissante : une trame
      --  au checksum faux ne dit rien de son âge ni de sa valeur, il serait
      --  faux de rapporter Stale_Data sur une trame corrompue.
      if Input.Checksum /= Expected_Checksum (Input.Raw, Input.Age) then
         Value := 0;
         Status := Bad_Checksum;
      elsif Input.Raw > Litres'Last then
         Value := 0;
         Status := Out_Of_Range;
      elsif Input.Age > Max_Age then
         Value := 0;
         Status := Stale_Data;
      else
         Value := Input.Raw;
         Status := Ok;
      end if;
   end Decode;

end Mod06.Sensor_Io;

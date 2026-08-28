package body Mod10.Warning
  with SPARK_Mode => On
is

   function Alarm
     (Low_Fuel : Boolean; Imbalance : Boolean; Sensor_Fault : Boolean)
      return Boolean is
   begin
      --  Écrit en `if` plutôt qu'en expression booléenne rendue directement :
      --  gnatcov rapporte alors la décision et ses conditions ligne par
      --  ligne, ce qui rend le rapport lisible par un humain.
      if Low_Fuel or else (Imbalance and then Sensor_Fault) then
         return True;
      else
         return False;
      end if;
   end Alarm;

end Mod10.Warning;

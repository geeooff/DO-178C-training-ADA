package body Mod04.Alarm_Logic
  with SPARK_Mode => On
is

   function Alarm_For (Value : Litres) return Boolean is
   begin
      --  Écrit en `if` plutôt qu'en expression booléenne unique : la
      --  couverture de décision et MC/DC se lisent alors directement dans
      --  le rapport de gnatcov, ligne par ligne.
      if Is_Low (Value) or else Is_Implausible (Value) then
         return True;
      else
         return False;
      end if;
   end Alarm_For;

   function Next_Sample_Count (Current : Natural) return Natural is
   begin
      if Current = Natural'Last then
         return Natural'Last;
      else
         return Current + 1;
      end if;
   end Next_Sample_Count;

end Mod04.Alarm_Logic;

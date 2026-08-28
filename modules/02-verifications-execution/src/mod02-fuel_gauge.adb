package body Mod02.Fuel_Gauge
  with SPARK_Mode => On
is

   function Total (Tanks : Tank_Array) return Total_Litres is
      Sum : Total_Litres := 0;
   begin
      for I in Tank_Index loop
         Sum := Sum + Tanks (I);

         --  L'invariant de boucle est ce qui permet à gnatprove de
         --  démontrer que l'addition ne déborde jamais. Sans lui, le
         --  prouveur ne sait rien de Sum d'un tour à l'autre et la
         --  vérification reste non prouvée — donc non supprimable.
         pragma Loop_Invariant (Sum <= I * Litres'Last);
      end loop;

      return Sum;
   end Total;

   procedure Read_Tank
     (Tanks : Tank_Array;
      Index : Integer;
      Value : out Litres;
      Valid : out Boolean) is
   begin
      if Index in Tank_Index then
         Value := Tanks (Index);
         Valid := True;
      else
         Value := 0;
         Valid := False;
      end if;
   end Read_Tank;

   function Average (Tanks : Tank_Array) return Litres
   is (Total (Tanks) / Tank_Count);

end Mod02.Fuel_Gauge;

package body Mod09.Calibration
  with SPARK_Mode => On
is

   procedure Convert
     (Raw : Natural; Volume : out Litres; Status : out Probe_Status) is
   begin
      if Raw <= Raw_Count'Last then
         Volume := Raw * Gain;
         Status := Valid;
      else
         Volume := 0;
         Status := Out_Of_Domain;
      end if;
   end Convert;

   procedure Consolidate
     (Left     : Litres;
      Right    : Litres;
      Left_Ok  : Boolean;
      Right_Ok : Boolean;
      Volume   : out Litres;
      Mode     : out Consolidation) is
   begin
      if Left_Ok and then Right_Ok then
         Mode := Both_Probes;
         Volume := (Left + Right) / 2;
      elsif Left_Ok then
         Mode := Left_Only;
         Volume := Left;
      elsif Right_Ok then
         Mode := Right_Only;
         Volume := Right;
      else
         Mode := No_Probe;
         Volume := 0;
      end if;

      --  Saturation à la capacité physique. Une sonde peut indiquer plus que
      --  ce que le réservoir contient ; l'indication, elle, ne le doit pas.
      if Volume > Capacity then
         Volume := Capacity;
      end if;
   end Consolidate;

end Mod09.Calibration;

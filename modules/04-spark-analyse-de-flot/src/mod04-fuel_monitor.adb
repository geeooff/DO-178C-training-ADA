package body Mod04.Fuel_Monitor
  with SPARK_Mode => On, Refined_State => (State => (Current, Alarm, Samples))
is

   --  Les trois variables que l'abstraction `State` cache. Elles sont
   --  initialisées à la déclaration : c'est ce qui permet à `Initializes`
   --  d'être tenu, et donc au premier appel de Last_Reading d'être défini.
   Current : Litres := 0;
   Alarm   : Boolean := False;
   Samples : Natural := 0;

   procedure Update (Reading : Litres)
   with
     Refined_Global  => (Output => (Current, Alarm), In_Out => Samples),
     Refined_Depends =>
       (Current => Reading, Alarm => Reading, Samples => Samples)
   is
   begin
      Current := Reading;
      Alarm := Alarm_Logic.Alarm_For (Reading);
      Samples := Alarm_Logic.Next_Sample_Count (Samples);
   end Update;

   procedure Reset
   with
     Refined_Global  => (Output => (Current, Alarm, Samples)),
     Refined_Depends => ((Current, Alarm, Samples) => null)
   is
   begin
      Current := 0;
      Alarm := False;
      Samples := 0;
   end Reset;

   function Last_Reading return Litres
   is (Current)
   with Refined_Global => (Input => Current);

   function Alarm_Active return Boolean
   is (Alarm)
   with Refined_Global => (Input => Alarm);

   function Sample_Count return Natural
   is (Samples)
   with Refined_Global => (Input => Samples);

end Mod04.Fuel_Monitor;

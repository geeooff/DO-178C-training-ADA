package body Mod07.Ring_Buffer
  with SPARK_Mode => On
is

   procedure Clear (B : out Buffer) is
   begin
      B := (Items => [others => 0], First => 0, Count => 0);
   end Clear;

   procedure Push (B : in out Buffer; Value : Litres) is
      Slot : constant Index_Type := (B.First + B.Count) mod Capacity;
   begin
      B.Items (Slot) := Value;
      B.Count := B.Count + 1;
   end Push;

   procedure Pop (B : in out Buffer; Value : out Litres) is
   begin
      Value := B.Items (B.First);
      B.First := (B.First + 1) mod Capacity;
      B.Count := B.Count - 1;
   end Pop;

end Mod07.Ring_Buffer;

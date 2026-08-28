package body Fuel
  with SPARK_Mode => On
is

   function Saturating_Add (Left, Right : Litres) return Litres is
      --  Litres'Last + Litres'Last tient dans Natural : pas de débordement
      --  possible ici, et gnatprove le démontre plutôt que de le supposer.
      Sum : constant Natural := Left + Right;
   begin
      if Sum > Max_Litres then
         return Max_Litres;
      else
         --  Conversion implicite Natural -> Litres : le compilateur insère
         --  un contrôle de plage. gnatprove le décharge grâce au test
         --  ci-dessus, ce qui autorisera plus tard de le supprimer.
         return Sum;
      end if;
   end Saturating_Add;

end Fuel;

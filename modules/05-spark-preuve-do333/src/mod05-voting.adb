package body Mod05.Voting
  with SPARK_Mode => On
is

   function Mid_Value (A, B, C : Litres) return Litres is
   begin
      if (A <= B and then B <= C) or else (C <= B and then B <= A) then
         return B;
      elsif (B <= A and then A <= C) or else (C <= A and then A <= B) then
         return A;
      else
         return C;
      end if;
   end Mid_Value;

   procedure Find_First_Low
     (Values : Reading_Array; Index : out Natural; Found : out Boolean) is
   begin
      Index := 0;
      Found := False;

      for I in Values'Range loop
         if Values (I) < Low_Level_Threshold then
            Index := I;
            Found := True;
            return;
         end if;

         --  L'invariant porte sur tout ce qui a DÉJÀ été examiné. Sans lui,
         --  le prouveur n'a aucune mémoire d'un tour à l'autre et la
         --  postcondition du cas « rien trouvé » reste non prouvée.
         pragma
           Loop_Invariant
             (for all K in Values'First .. I =>
                Values (K) >= Low_Level_Threshold);
      end loop;
   end Find_First_Low;

   function Refuel_Steps (Target : Litres; Step : Positive) return Natural is
      Remaining : Natural := Target;
      Count     : Natural := 0;
   begin
      while Remaining > 0 loop
         --  Deux invariants et un variant. Les invariants bornent le
         --  résultat ; le variant démontre la TERMINAISON, qui est une
         --  propriété distincte et qu'aucun invariant n'implique.
         pragma Loop_Invariant (Remaining <= Target);
         pragma Loop_Invariant (Count <= Target - Remaining);
         pragma Loop_Variant (Decreases => Remaining);

         if Remaining >= Step then
            Remaining := Remaining - Step;
         else
            Remaining := 0;
         end if;

         Count := Count + 1;
      end loop;

      return Count;
   end Refuel_Steps;

end Mod05.Voting;

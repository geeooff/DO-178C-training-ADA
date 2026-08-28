package body Mod03.Tank
  with SPARK_Mode => On
is

   function Create (Max : Litres) return Fuel_Tank
   is (Fuel_Tank'(Max => Max, Content => 0));

   procedure Fill (T : in out Fuel_Tank; Amount : Litres) is
   begin
      --  Aucun test défensif ici. La précondition l'a déjà exigé, et
      --  gnatprove vérifie chez CHAQUE appelant qu'elle est tenue. Réécrire
      --  le test serait du code non justifié par une exigence — donc à
      --  supprimer au titre du §6.4.4.
      T.Content := T.Content + Amount;
   end Fill;

   procedure Drain (T : in out Fuel_Tank; Amount : Litres) is
   begin
      T.Content := T.Content - Amount;
   end Drain;

   procedure Transfer
     (From   : in out Fuel_Tank;
      To     : in out Fuel_Tank;
      Amount : Litres;
      Done   : out Boolean) is
   begin
      if Amount <= Level (From) and then Amount <= Ullage (To) then
         Drain (From, Amount);
         Fill (To, Amount);
         Done := True;
      else
         Done := False;
      end if;
   end Transfer;

end Mod03.Tank;

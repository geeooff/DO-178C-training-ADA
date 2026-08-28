--  Campagne témoin du module 00. Elle vérifie le fragment FQMS, mais sa
--  vraie fonction est ailleurs : c'est elle qui donne à gnatcov quelque
--  chose à mesurer, et qui démontre que le harnais tourne dans le SECI.
with Mod00.Fuel;
with Testing;

procedure Test_Fuel is

   package Fuel renames Mod00.Fuel;

   Suite : constant String := "Fuel";

begin
   Testing.Start (Suite, "saturating_add_nominal", "LLR-M00-001");
   Testing.Check
     (Fuel.Saturating_Add (1_200, 300) = 1_500,
      "une somme sous la borne est rendue telle quelle");
   Testing.Check (Fuel.Saturating_Add (0, 0) = 0, "zéro plus zéro reste zéro");

   Testing.Start (Suite, "saturating_add_reaches_limit", "LLR-M00-001");
   Testing.Check
     (Fuel.Saturating_Add (9_000, 1_000) = Fuel.Max_Litres,
      "une somme égale à la borne n'est pas écrêtée");

   Testing.Start (Suite, "saturating_add_robustness_overflow", "LLR-M00-001");
   Testing.Check
     (Fuel.Saturating_Add (7_500, 4_000) = Fuel.Max_Litres,
      "une somme au-dessus de la borne sature au lieu de déborder");
   Testing.Check
     (Fuel.Saturating_Add (Fuel.Litres'Last, Fuel.Litres'Last)
      = Fuel.Max_Litres,
      "le pire cas reste dans le domaine du type");

   Testing.Summary (Suite);
end Test_Fuel;

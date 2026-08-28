--  Module 02 — campagne basée sur les exigences.
with Mod02.Fuel_Gauge;
with Testing;

procedure Test_Fuel_Gauge is

   package Gauge renames Mod02.Fuel_Gauge;

   Suite : constant String := "Fuel_Gauge";

   Nominal : constant Gauge.Tank_Array := [2_500, 3_000, 1_200, 800];
   Empty   : constant Gauge.Tank_Array := [others => 0];
   Full    : constant Gauge.Tank_Array := [others => Gauge.Litres'Last];

   Value : Gauge.Litres;
   Valid : Boolean;

begin
   Testing.Start (Suite, "total_nominal", "LLR-M02-001");
   Testing.Check_Equal
     (Gauge.Total (Nominal), 7_500, "la somme des quatre réservoirs");
   Testing.Check_Equal (Gauge.Total (Empty), 0, "quatre réservoirs vides");

   Testing.Start (Suite, "total_worst_case_stays_in_range", "LLR-M02-001");
   Testing.Check_Equal
     (Gauge.Total (Full),
      40_000,
      "le pire cas atteint la borne du type sans la dépasser");

   Testing.Start (Suite, "read_tank_nominal", "LLR-M02-002");
   Gauge.Read_Tank (Nominal, 1, Value, Valid);
   Testing.Check (Valid, "l'indice 1 est dans les bornes");
   Testing.Check_Equal (Value, 2_500, "l'indice 1 rend le premier réservoir");

   Gauge.Read_Tank (Nominal, 4, Value, Valid);
   Testing.Check (Valid and then Value = 800, "l'indice 4 est la borne haute");

   Testing.Start (Suite, "read_tank_robustness_below_range", "LLR-M02-002");
   Gauge.Read_Tank (Nominal, 0, Value, Valid);
   Testing.Check (not Valid, "l'indice 0 est refusé");
   Testing.Check_Equal (Value, 0, "la valeur rendue reste définie");

   Testing.Start (Suite, "read_tank_robustness_above_range", "LLR-M02-002");
   Gauge.Read_Tank (Nominal, 9, Value, Valid);
   Testing.Check (not Valid, "l'indice 9 est refusé");

   Gauge.Read_Tank (Nominal, Integer'Last, Value, Valid);
   Testing.Check (not Valid, "l'indice extrême est refusé sans déborder");

   Testing.Start (Suite, "average_nominal", "LLR-M02-003");
   Testing.Check_Equal (Gauge.Average (Nominal), 1_875, "moyenne nominale");
   Testing.Check_Equal
     (Gauge.Average (Empty), 0, "moyenne de réservoirs vides");

   Testing.Start (Suite, "average_worst_case", "LLR-M02-003");
   Testing.Check_Equal
     (Gauge.Average (Full),
      10_000,
      "la moyenne du pire cas reste dans le domaine de Litres");

   Testing.Summary (Suite);
end Test_Fuel_Gauge;

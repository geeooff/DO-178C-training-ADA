--  Module 03 — campagne basée sur les exigences.
with Ada.Command_Line;
with Mod03.Tank;
with Testing;

procedure Test_Tank is

   package Tank renames Mod03.Tank;

   Suite : constant String := "Tank";

   Too_Much : constant Tank.Litres :=
     9_000 - Tank.Litres (Ada.Command_Line.Argument_Count);

   procedure Violate_Precondition;

   procedure Violate_Precondition is
      T : Tank.Fuel_Tank := Tank.Create (5_000);
   begin
      Tank.Fill (T, Too_Much);
      raise Program_Error with Tank.Level (T)'Image;
   end Violate_Precondition;

   procedure Check_Precondition is new
     Testing.Check_Raises_Assertion_Error (Violate_Precondition);

   Left  : Tank.Fuel_Tank := Tank.Create (5_000);
   Right : Tank.Fuel_Tank := Tank.Create (2_000);
   Done  : Boolean;

begin
   Testing.Start (Suite, "create_starts_empty", "LLR-M03-002");
   Testing.Check_Equal (Tank.Level (Left), 0, "un réservoir neuf est vide");
   Testing.Check_Equal
     (Tank.Capacity (Left), 5_000, "la capacité est celle demandée");
   Testing.Check_Equal
     (Tank.Ullage (Left), 5_000, "le creux d'un réservoir vide est total");

   Testing.Start (Suite, "fill_nominal", "LLR-M03-003");
   Tank.Fill (Left, 1_500);
   Testing.Check_Equal (Tank.Level (Left), 1_500, "le niveau monte");
   Testing.Check_Equal (Tank.Ullage (Left), 3_500, "le creux baisse d'autant");

   Testing.Start (Suite, "fill_to_capacity", "LLR-M03-003");
   Tank.Fill (Left, 3_500);
   Testing.Check_Equal
     (Tank.Level (Left), 5_000, "remplir jusqu'au creux exact est permis");
   Testing.Check_Equal (Tank.Ullage (Left), 0, "le creux tombe à zéro");

   Testing.Start (Suite, "drain_nominal", "LLR-M03-004");
   Tank.Drain (Left, 2_000);
   Testing.Check_Equal (Tank.Level (Left), 3_000, "le niveau baisse");

   Testing.Start (Suite, "transfer_succeeds", "LLR-M03-005");
   Tank.Transfer (Left, Right, 1_000, Done);
   Testing.Check (Done, "le transfert est accepté");
   Testing.Check_Equal (Tank.Level (Left), 2_000, "la source a été vidée");
   Testing.Check_Equal (Tank.Level (Right), 1_000, "la cible a été remplie");

   Testing.Start (Suite, "transfer_refused_source_too_low", "LLR-M03-005");
   Tank.Transfer (Left, Right, 9_000, Done);
   Testing.Check (not Done, "un transfert impossible est refusé");
   Testing.Check_Equal (Tank.Level (Left), 2_000, "la source est intacte");
   Testing.Check_Equal (Tank.Level (Right), 1_000, "la cible est intacte");

   Testing.Start (Suite, "transfer_refused_target_too_full", "LLR-M03-005");
   Tank.Fill (Right, 1_000);
   Tank.Transfer (Left, Right, 500, Done);
   Testing.Check (not Done, "une cible pleine refuse le transfert");
   Testing.Check_Equal (Tank.Level (Right), 2_000, "la cible reste pleine");

   Testing.Start (Suite, "static_predicate_selects_wing_tanks", "LLR-M03-001");
   Testing.Check
     (Tank.Left_Wing in Tank.Wing_Tank_Id, "Left_Wing est une voilure");
   Testing.Check (Tank.Trim not in Tank.Wing_Tank_Id, "Trim n'en est pas une");

   Testing.Start (Suite, "precondition_rejects_bad_call", "LLR-M03-003");
   Check_Precondition ("remplir au-delà du creux disponible");

   Testing.Summary (Suite);
end Test_Tank;

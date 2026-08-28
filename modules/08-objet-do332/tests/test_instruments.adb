--  Module 08 — campagne basée sur les exigences.
--
--  La DO-332 §OO.6.4.4.2 demande que CHAQUE site d'appel dispatchant soit
--  exercé pour CHAQUE cible possible. Ici, un site — Reading — et deux
--  cibles. Les deux blocs `dispatch_*` ci-dessous sont donc obligatoires,
--  et leur absence serait un défaut de couverture, pas un oubli de zèle.
with Mod08.Instruments;
with Testing;

procedure Test_Instruments is

   package Ins renames Mod08.Instruments;

   Suite : constant String := "Instruments";

   Cap : constant Ins.Capacitive := (Serial => 1, Gain => 10);
   Ult : constant Ins.Ultrasonic := (Serial => 2, Dead_Zone => 300);

begin
   Testing.Start (Suite, "capacitive_is_linear", "LLR-M08-004");
   Testing.Check_Equal
     (Ins.To_Litres (Cap, 0), 0, "zéro compte vaut zéro litre");
   Testing.Check_Equal
     (Ins.To_Litres (Cap, 1_000), 10_000, "la pleine échelle vaut 10 000 L");
   Testing.Check
     (Ins.To_Litres (Cap, 500) = 5_000,
      "le milieu d échelle vaut la moitié, exactement");

   Testing.Start (Suite, "ultrasonic_offsets_by_dead_zone", "LLR-M08-005");
   Testing.Check_Equal
     (Ins.To_Litres (Ult, 0), 300, "zéro compte rend la zone morte");
   Testing.Check_Equal
     (Ins.To_Litres (Ult, 1_000),
      9_300,
      "la pleine échelle est amputée de la zone morte");

   Testing.Start (Suite, "dispatch_to_capacitive", "LLR-M08-003");
   Testing.Check_Equal
     (Ins.Reading (Cap, 0),
      0,
      "le site d'appel dispatchant atteint la cible capacitive");

   Testing.Start (Suite, "dispatch_to_ultrasonic", "LLR-M08-003");
   Testing.Check_Equal
     (Ins.Reading (Ult, 0),
      300,
      "le même site d'appel atteint la cible ultrasons");

   Testing.Start (Suite, "class_wide_postcondition_holds", "LLR-M08-001");
   Testing.Check
     (Ins.Reading (Cap, 1_000) <= 10_000,
      "la postcondition de classe tient sur la capacitive");
   Testing.Check
     (Ins.Reading (Ult, 1_000) <= 10_000,
      "et sur les ultrasons, sans avoir été réécrite");

   Testing.Start (Suite, "plausibility_differs_by_type", "LLR-M08-002");
   Testing.Check
     (Ins.Is_Plausible (Cap, 100), "100 L est plausible pour la capacitive");
   Testing.Check
     (not Ins.Is_Plausible (Ult, 100),
      "100 L ne l'est pas sous la zone morte des ultrasons");
   Testing.Check (Ins.Is_Plausible (Ult, 500), "500 L l'est de nouveau");

   Testing.Summary (Suite);
end Test_Instruments;

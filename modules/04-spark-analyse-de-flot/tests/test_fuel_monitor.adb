--  Module 04 — campagne basée sur les exigences.
--
--  Deux paquetages, deux façons de vérifier. Alarm_Logic n'a pas d'état :
--  ses cas sont exhaustifs sur les bornes et se mesurent en MC/DC.
--  Fuel_Monitor a de l'état : ses cas portent sur les SÉQUENCES d'appels,
--  ce qu'aucune couverture structurelle ne saurait révéler à leur place.
with Mod04.Alarm_Logic;
with Mod04.Fuel_Monitor;
with Testing;

procedure Test_Fuel_Monitor is

   package Logic renames Mod04.Alarm_Logic;
   package Monitor renames Mod04.Fuel_Monitor;

   Suite : constant String := "Fuel_Monitor";

begin
   Testing.Start (Suite, "low_threshold_boundary", "LLR-M04-006");
   Testing.Check
     (Logic.Is_Low (Logic.Low_Level_Threshold - 1),
      "un litre sous le seuil est bas");
   Testing.Check
     (not Logic.Is_Low (Logic.Low_Level_Threshold),
      "le seuil exact n'est PAS bas : la borne est exclusive");
   Testing.Check (Logic.Is_Low (0), "un réservoir vide est bas");

   Testing.Start (Suite, "high_threshold_boundary", "LLR-M04-007");
   Testing.Check
     (Logic.Is_Implausible (Logic.High_Level_Threshold + 1),
      "un litre au-dessus du seuil haut est invraisemblable");
   Testing.Check
     (not Logic.Is_Implausible (Logic.High_Level_Threshold),
      "le seuil haut exact reste vraisemblable");

   --  Les quatre combinaisons de la décision `Is_Low or else Is_Implausible`.
   --  C'est ce qui donne MC/DC : chaque condition doit à elle seule faire
   --  basculer le résultat.
   Testing.Start (Suite, "alarm_for_covers_both_conditions", "LLR-M04-008");
   Testing.Check (Logic.Alarm_For (100), "niveau bas seul : alarme");
   Testing.Check (Logic.Alarm_For (9_900), "niveau invraisemblable : alarme");
   Testing.Check
     (not Logic.Alarm_For (5_000), "niveau nominal : aucune alarme");

   Testing.Start (Suite, "sample_count_saturates", "LLR-M04-009");
   Testing.Check_Equal
     (Logic.Next_Sample_Count (0), 1, "l'incrément nominal avance de un");
   Testing.Check_Equal
     (Logic.Next_Sample_Count (Natural'Last),
      Natural'Last,
      "le compteur sature au lieu de déborder");

   Testing.Start (Suite, "initial_state_is_defined", "LLR-M04-003");
   Testing.Check_Equal
     (Monitor.Last_Reading, 0, "la mesure initiale est définie");
   Testing.Check
     (not Monitor.Alarm_Active, "aucune alarme avant la première mesure");
   Testing.Check_Equal (Monitor.Sample_Count, 0, "aucune mesure comptée");

   Testing.Start (Suite, "update_records_reading", "LLR-M04-001");
   Monitor.Update (4_200);
   Testing.Check_Equal
     (Monitor.Last_Reading, 4_200, "la mesure est mémorisée");
   Testing.Check_Equal (Monitor.Sample_Count, 1, "le compteur avance");
   Testing.Check
     (not Monitor.Alarm_Active, "4 200 L ne déclenche pas l'alarme");

   Testing.Start (Suite, "update_raises_alarm", "LLR-M04-004");
   Monitor.Update (310);
   Testing.Check (Monitor.Alarm_Active, "310 L déclenche l'alarme");
   Testing.Check_Equal (Monitor.Sample_Count, 2, "le compteur avance encore");

   Testing.Start (Suite, "alarm_clears_when_level_recovers", "LLR-M04-004");
   Monitor.Update (2_000);
   Testing.Check
     (not Monitor.Alarm_Active, "l'alarme retombe, elle n'est pas latchée");

   Testing.Start (Suite, "reset_clears_everything", "LLR-M04-002");
   Monitor.Update (100);
   Monitor.Reset;
   Testing.Check_Equal (Monitor.Sample_Count, 0, "le compteur repart de zéro");
   Testing.Check (not Monitor.Alarm_Active, "l'alarme est retombée");
   Testing.Check_Equal (Monitor.Last_Reading, 0, "la mesure est effacée");

   Testing.Summary (Suite);
end Test_Fuel_Monitor;

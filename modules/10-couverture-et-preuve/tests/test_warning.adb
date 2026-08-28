--  ---------------------------------------------------------------------------
--  Campagne COMPLÈTE — celle qui atteint MC/DC.
--
--  MC/DC exige que chaque condition démontre, à elle seule, qu'elle peut
--  faire basculer le résultat de la décision. Il faut pour cela, par
--  condition, une PAIRE de cas ne différant que par elle et donnant des
--  résultats opposés.
--  ---------------------------------------------------------------------------
with Mod10.Warning;
with Testing;

procedure Test_Warning is

   package Warn renames Mod10.Warning;

   Suite : constant String := "Warning";

begin
   Testing.Start (Suite, "hlr_alarm_on_low_fuel", "HLR-FQMSWRN-001");
   Testing.Check
     (Warn.Alarm (True, False, False), "un niveau bas suffit à alarmer");

   Testing.Start (Suite, "hlr_no_alarm_when_nominal", "HLR-FQMSWRN-002");
   Testing.Check
     (not Warn.Alarm (False, False, False),
      "aucune alarme quand tout est nominal");

   --  Paire pour Low_Fuel : (T,F,F) vrai contre (F,F,F) faux.
   Testing.Start (Suite, "mcdc_pair_low_fuel", "LLR-FQMSWRN-010");
   Testing.Check (Warn.Alarm (True, False, False), "Low_Fuel seul : alarme");
   Testing.Check
     (not Warn.Alarm (False, False, False), "sans lui : pas d'alarme");

   --  Paire pour Imbalance : (F,T,T) vrai contre (F,F,T) faux.
   Testing.Start (Suite, "mcdc_pair_imbalance", "LLR-FQMSWRN-010");
   Testing.Check
     (Warn.Alarm (False, True, True),
      "déséquilibre avec panne de sonde : alarme");
   Testing.Check
     (not Warn.Alarm (False, False, True),
      "panne de sonde seule : pas d'alarme");

   --  Paire pour Sensor_Fault : (F,T,T) vrai contre (F,T,F) faux.
   Testing.Start (Suite, "mcdc_pair_sensor_fault", "LLR-FQMSWRN-010");
   Testing.Check
     (Warn.Alarm (False, True, True), "avec la panne de sonde : alarme");
   Testing.Check
     (not Warn.Alarm (False, True, False),
      "déséquilibre seul, sonde saine : pas d'alarme (virage normal)");

   Testing.Start (Suite, "condition_count_is_documented", "LLR-FQMSWRN-020");
   Testing.Check_Equal
     (Warn.Condition_Count,
      3,
      "trois conditions, donc au moins quatre cas pour MC/DC");

   Testing.Summary (Suite);
end Test_Warning;

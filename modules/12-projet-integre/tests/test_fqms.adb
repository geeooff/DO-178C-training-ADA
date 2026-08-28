--  ---------------------------------------------------------------------------
--  FQMS — campagne de vérification, DAL B.
--
--  Les cas `hlr_*` sont écrits depuis le SRD, ceux qui ne le sont pas depuis
--  le SDD. Les cas de SÉQUENCE sont ici la famille la plus importante : une
--  hystérésis et une confirmation sur cinq cycles ne se vérifient pas sur un
--  appel isolé, et aucune couverture structurelle ne les révélerait.
--  ---------------------------------------------------------------------------
with Mod12.Fqms;
with Testing;

procedure Test_Fqms is

   package Fqms renames Mod12.Fqms;
   use type Fqms.Quantity_Status;

   Suite : constant String := "Fqms";

   Equilibre  : constant Fqms.Raw_Inputs := [2_000, 2_000, 2_000];
   Desequilib : constant Fqms.Raw_Inputs := [3_000, 2_000, 1_000];
   Presque_Vi : constant Fqms.Raw_Inputs := [200, 200, 200];
   Panne_Aile : constant Fqms.Raw_Inputs := [9_999, 2_000, 2_000];
   Panne_Drte : constant Fqms.Raw_Inputs := [2_000, 2_000, 9_999];
   Tout_Panne : constant Fqms.Raw_Inputs := [-1, 9_999, 100_000];

   S      : Fqms.State := Fqms.Initial;
   Result : Fqms.Cycle_Outputs;

   procedure Jouer (Raw : Fqms.Raw_Inputs; Cycles : Positive);

   procedure Jouer (Raw : Fqms.Raw_Inputs; Cycles : Positive) is
   begin
      for Each in 1 .. Cycles loop
         Fqms.Run_Cycle (S, Raw, Result);
      end loop;
   end Jouer;

begin
   --  --- Acquisition

   Testing.Start (Suite, "hlr_converts_gauge_linearly", "HLR-FQMS-001");
   Testing.Check_Equal
     (Fqms.To_Mass (0, Fqms.Left_Wing), 0, "zéro point vaut zéro kilo");
   Testing.Check_Equal
     (Fqms.To_Mass (4_095, Fqms.Left_Wing),
      5_000,
      "pleine échelle vaut la capacité de l'aile");
   Testing.Check_Equal
     (Fqms.To_Mass (4_095, Fqms.Centre), 8_000, "et celle du caisson central");

   Testing.Start (Suite, "hlr_rejects_out_of_domain", "HLR-FQMS-002");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, Panne_Aile, Result);
   Testing.Check_Equal
     (Result.Per_Tank (Fqms.Left_Wing),
      0,
      "aucune quantité n'est produite pour une jauge hors domaine");
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing), 1, "et le rejet est comptabilisé");

   --  --- Totalisation et statut

   Testing.Start (Suite, "hlr_totalises_valid_gauges", "HLR-FQMS-010");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, Equilibre, Result);
   Testing.Check_Equal
     (Result.Total,
      Fqms.To_Mass (2_000, Fqms.Left_Wing)
      + Fqms.To_Mass (2_000, Fqms.Centre)
      + Fqms.To_Mass (2_000, Fqms.Right_Wing),
      "le total est la somme des trois réservoirs valides");

   Testing.Start (Suite, "hlr_status_valid", "HLR-FQMS-011");
   Testing.Check
     (Result.Status = Fqms.Valid, "trois jauges valides : statut valide");

   Testing.Start (Suite, "hlr_status_degraded", "HLR-FQMS-011");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, Panne_Aile, Result);
   Testing.Check
     (Result.Status = Fqms.Degraded, "une jauge en panne : statut dégradé");
   Testing.Check
     (Result.Total > 0, "le total reste calculé sur les jauges valides");

   Testing.Start (Suite, "hlr_status_unavailable", "HLR-FQMS-011");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, Tout_Panne, Result);
   Testing.Check
     (Result.Status = Fqms.Unavailable,
      "trois jauges en panne : quantité indisponible");
   Testing.Check_Equal (Result.Total, 0, "et le total est nul");

   --  --- Alerte de déséquilibre

   Testing.Start (Suite, "hlr_imbalance_needs_five_cycles", "HLR-FQMS-020");
   S := Fqms.Initial;
   Jouer (Desequilib, 4);
   Testing.Check (not Result.Imbalance, "quatre cycles ne suffisent pas");
   Jouer (Desequilib, 1);
   Testing.Check (Result.Imbalance, "le cinquième lève l'alerte");

   Testing.Start (Suite, "hlr_imbalance_hysteresis", "HLR-FQMS-021");
   Jouer (Equilibre, 4);
   Testing.Check
     (Result.Imbalance, "quatre cycles équilibrés n'effacent pas l'alerte");
   Jouer (Equilibre, 1);
   Testing.Check (not Result.Imbalance, "le cinquième l'efface");

   Testing.Start
     (Suite, "hlr_imbalance_frozen_on_gauge_fault", "HLR-FQMS-022");
   S := Fqms.Initial;
   Jouer (Desequilib, 5);
   Testing.Check (Result.Imbalance, "l'alerte est levée");
   Jouer (Panne_Aile, 10);
   Testing.Check
     (Result.Imbalance,
      "une jauge d'aile en panne CONSERVE l'alerte au lieu de la réévaluer");

   --  --- Alerte bas niveau

   Testing.Start (Suite, "hlr_low_level_needs_five_cycles", "HLR-FQMS-030");
   S := Fqms.Initial;
   Jouer (Presque_Vi, 4);
   Testing.Check (not Result.Low_Level, "quatre cycles ne suffisent pas");
   Jouer (Presque_Vi, 1);
   Testing.Check (Result.Low_Level, "le cinquième lève l'alerte bas niveau");

   Testing.Start (Suite, "hlr_low_level_hysteresis", "HLR-FQMS-031");
   Jouer (Equilibre, 5);
   Testing.Check (not Result.Low_Level, "le retour en quantité l'efface");

   Testing.Start
     (Suite, "hlr_low_level_frozen_on_gauge_fault", "HLR-FQMS-032");
   S := Fqms.Initial;
   Jouer (Presque_Vi, 5);
   Testing.Check (Result.Low_Level, "l'alerte bas niveau est levée");
   Jouer (Panne_Aile, 10);
   Testing.Check
     (Result.Low_Level,
      "une jauge en panne ne doit pas lever d'alerte injustifiée, "
      & "ni effacer celle qui l'est");

   --  --- Maintenance et mise sous tension

   Testing.Start (Suite, "hlr_counts_rejects_per_tank", "HLR-FQMS-040");
   S := Fqms.Initial;
   Jouer (Panne_Aile, 3);
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing), 3, "trois rejets sur l'aile gauche");
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Centre), 0, "aucun sur le caisson central");

   Testing.Start (Suite, "hlr_no_alert_at_power_up", "HLR-FQMS-042");
   S := Fqms.Initial;
   Testing.Check
     (not Fqms.Imbalance_Alert (S), "aucune alerte de déséquilibre au départ");
   Testing.Check
     (not Fqms.Low_Level_Alert (S), "aucune alerte bas niveau au départ");
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Right_Wing), 0, "aucun rejet au départ");

   --  --- Exigences de bas niveau

   Testing.Start (Suite, "to_mass_is_linear_per_tank", "LLR-FQMS-010");
   Testing.Check_Equal
     (Fqms.To_Mass (2_048, Fqms.Centre),
      4_000,
      "la moitié de l'échelle vaut la moitié de la capacité");
   Testing.Check
     (Fqms.To_Mass (4_095, Fqms.Right_Wing)
      = Fqms.To_Mass (4_095, Fqms.Left_Wing),
      "deux réservoirs de même capacité convertissent pareil");
   Testing.Check
     (Fqms.To_Mass (4_095, Fqms.Centre) > Fqms.To_Mass (4_095, Fqms.Left_Wing),
      "le caisson central a une capacité plus grande");

   Testing.Start (Suite, "acquire_zeroes_and_counts", "LLR-FQMS-020");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, [-1, 2_000, 2_000], Result);
   Testing.Check_Equal
     (Result.Per_Tank (Fqms.Left_Wing),
      0,
      "une mesure négative rend zéro, pas une valeur plausible");
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing), 1, "et incrémente le compteur");
   Fqms.Run_Cycle (S, [4_096, 2_000, 2_000], Result);
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing),
      2,
      "un point au-dessus du domaine est rejeté aussi");

   Testing.Start (Suite, "total_excludes_invalid_tanks", "LLR-FQMS-030");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, Panne_Aile, Result);
   Testing.Check_Equal
     (Result.Total,
      Fqms.To_Mass (2_000, Fqms.Centre)
      + Fqms.To_Mass (2_000, Fqms.Right_Wing),
      "le réservoir invalide contribue pour zéro");

   Testing.Start (Suite, "alert_frozen_resets_confirmation", "LLR-FQMS-070");
   S := Fqms.Initial;
   Jouer (Desequilib, 3);
   Jouer (Panne_Aile, 2);
   Jouer (Desequilib, 4);
   Testing.Check
     (not Result.Imbalance,
      "la panne rompt la séquence : quatre cycles ne suffisent plus");
   Jouer (Desequilib, 1);
   Testing.Check (Result.Imbalance, "cinq cycles consécutifs la lèvent");

   Testing.Start (Suite, "reject_counter_is_per_tank", "LLR-FQMS-040");
   S := Fqms.Initial;
   Jouer (Tout_Panne, 2);
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing), 2, "aile gauche comptée");
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Right_Wing), 2, "aile droite comptée séparément");

   Testing.Start (Suite, "imbalance_gap_is_absolute", "LLR-FQMS-050");
   S := Fqms.Initial;
   Jouer ([1_000, 2_000, 3_000], 5);
   Testing.Check
     (Result.Imbalance, "l'écart se mesure en valeur absolue, aile droite");

   Testing.Start (Suite, "confirmation_resets_on_break", "LLR-FQMS-060");
   S := Fqms.Initial;
   Jouer (Desequilib, 3);
   Jouer (Equilibre, 1);
   Jouer (Desequilib, 4);
   Testing.Check
     (not Result.Imbalance,
      "un cycle équilibré rompt la séquence : le compteur repart de zéro");
   Jouer (Desequilib, 1);
   Testing.Check (Result.Imbalance, "et cinq cycles consécutifs la lèvent");

   --  La panne de l'aile DROITE, et pas seulement de la gauche. Sans ce cas,
   --  la condition `Ok (Right_Wing)` de la garde d'évaluation du
   --  déséquilibre n'est jamais celle qui fait basculer la décision, et
   --  MC/DC reste incomplet. Trouvé par la mesure, pas par relecture.
   Testing.Start (Suite, "imbalance_frozen_on_right_gauge", "LLR-FQMS-070");
   S := Fqms.Initial;
   Jouer (Desequilib, 5);
   Testing.Check (Result.Imbalance, "l'alerte est levée");
   Jouer (Panne_Drte, 10);
   Testing.Check
     (Result.Imbalance,
      "une panne de l'aile DROITE conserve l'alerte, comme la gauche");

   --  Saturation du compteur de maintenance. Ce cas n'existerait pas si le
   --  compteur saturait à Natural'Last : 2**31 cycles ne se jouent pas dans
   --  une campagne. Le domaine 16 bits rend la borne ATTEIGNABLE, donc
   --  vérifiable — c'est la conception qui s'est adaptée à la vérification.
   Testing.Start (Suite, "reject_counter_saturates", "LLR-FQMS-020");
   S := Fqms.Initial;
   for Each in 1 .. 65_535 loop
      Fqms.Run_Cycle (S, Panne_Aile, Result);
   end loop;
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing),
      65_535,
      "le compteur atteint sa borne");
   Fqms.Run_Cycle (S, Panne_Aile, Result);
   Testing.Check_Equal
     (Fqms.Rejects (S, Fqms.Left_Wing),
      65_535,
      "et il y reste au lieu de déborder");

   Testing.Start (Suite, "power_up_state_is_defined", "LLR-FQMS-100");
   S := Fqms.Initial;
   Fqms.Run_Cycle (S, Equilibre, Result);
   Testing.Check
     (not Result.Imbalance and then not Result.Low_Level,
      "le premier cycle après mise sous tension n'alerte pas");

   Testing.Summary (Suite);
end Test_Fqms;

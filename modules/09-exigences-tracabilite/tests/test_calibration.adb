--  ---------------------------------------------------------------------------
--  FQMS-CAL — campagne de vérification.
--
--  Deux familles de cas, et la distinction n'est pas cosmétique :
--
--    * les cas `hlr_*` vérifient les exigences de HAUT niveau. Ils sont écrits
--      depuis le SRD, sans regarder le code : c'est ce que la table A-6
--      objectifs 1 et 2 demande.
--    * les autres vérifient les exigences de BAS niveau, écrites depuis le
--      SDD, et exercent les chemins internes (table A-6 objectifs 3 et 4).
--
--  Un projet réel confie souvent ces deux familles à des personnes
--  différentes, pour l'indépendance exigée au DAL A et B (table A-7 note 1).
--  ---------------------------------------------------------------------------
with Mod09.Calibration;
with Testing;

procedure Test_Calibration is

   package Cal renames Mod09.Calibration;
   use type Cal.Probe_Status;
   use type Cal.Consolidation;

   Suite : constant String := "Calibration";

   Volume : Cal.Litres;
   Status : Cal.Probe_Status;
   Mode   : Cal.Consolidation;

begin
   --  --- Exigences de haut niveau

   Testing.Start (Suite, "hlr_converts_probe_reading", "HLR-FQMSCAL-001");
   Cal.Convert (1_000, Volume, Status);
   Testing.Check (Status = Cal.Valid, "une mesure du domaine est convertie");
   Testing.Check_Equal (Volume, 2_000, "1 000 comptes valent 2 000 litres");

   Testing.Start
     (Suite, "hlr_rejects_reading_out_of_domain", "HLR-FQMSCAL-002");
   Cal.Convert (9_999, Volume, Status);
   Testing.Check
     (Status = Cal.Out_Of_Domain, "une mesure hors domaine est signalée");

   Testing.Start (Suite, "hlr_consolidates_two_probes", "HLR-FQMSCAL-003");
   Cal.Consolidate (2_000, 2_400, True, True, Volume, Mode);
   Testing.Check_Equal (Volume, 2_200, "la moyenne des deux sondes");
   Testing.Check (Mode = Cal.Both_Probes, "le mode indique deux sondes");

   Testing.Start (Suite, "hlr_never_exceeds_capacity", "HLR-FQMSCAL-004");
   Cal.Consolidate (9_500, 9_900, True, True, Volume, Mode);
   Testing.Check
     (Volume <= Cal.Capacity, "l'indication ne dépasse jamais la capacité");

   --  --- Exigences de bas niveau

   Testing.Start (Suite, "convert_nominal", "LLR-FQMSCAL-010");
   Cal.Convert (0, Volume, Status);
   Testing.Check_Equal (Volume, 0, "zéro compte vaut zéro litre");
   Cal.Convert (500, Volume, Status);
   Testing.Check_Equal
     (Volume, 1_000, "le gain est de deux litres par compte");

   Testing.Start (Suite, "convert_domain_boundary", "LLR-FQMSCAL-020");
   Cal.Convert (4_000, Volume, Status);
   Testing.Check (Status = Cal.Valid, "la borne exacte est dans le domaine");
   Testing.Check_Equal (Volume, 8_000, "et vaut la capacité du réservoir");
   Cal.Convert (4_001, Volume, Status);
   Testing.Check
     (Status = Cal.Out_Of_Domain, "un compte de plus sort du domaine");
   Testing.Check_Equal (Volume, 0, "la valeur rendue reste définie");

   Testing.Start (Suite, "consolidate_both_probes", "LLR-FQMSCAL-030");
   Cal.Consolidate (1_000, 2_000, True, True, Volume, Mode);
   Testing.Check_Equal (Volume, 1_500, "moyenne de deux sondes valides");

   Testing.Start (Suite, "consolidate_clamps_to_capacity", "LLR-FQMSCAL-030");
   Cal.Consolidate (10_000, 10_000, True, True, Volume, Mode);
   Testing.Check_Equal (Volume, 8_000, "la saturation ramène à la capacité");

   Testing.Start (Suite, "consolidate_left_only", "LLR-FQMSCAL-040");
   Cal.Consolidate (1_200, 9_999, True, False, Volume, Mode);
   Testing.Check_Equal (Volume, 1_200, "la sonde droite est ignorée");
   Testing.Check (Mode = Cal.Left_Only, "et le mode le dit");

   Testing.Start (Suite, "consolidate_right_only", "LLR-FQMSCAL-040");
   Cal.Consolidate (9_999, 800, False, True, Volume, Mode);
   Testing.Check_Equal (Volume, 800, "la sonde gauche est ignorée");
   Testing.Check (Mode = Cal.Right_Only, "et le mode le dit");

   Testing.Start (Suite, "consolidate_no_probe", "LLR-FQMSCAL-040");
   Cal.Consolidate (5_000, 5_000, False, False, Volume, Mode);
   Testing.Check (Mode = Cal.No_Probe, "aucune sonde valide");
   Testing.Check_Equal
     (Volume, 0, "aucune indication n'est fabriquée à partir de rien");

   Testing.Summary (Suite);
end Test_Calibration;

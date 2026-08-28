--  Module 06 — campagne basée sur les exigences.
--
--  Chaque statut a son cas. C'est la conséquence directe du choix de
--  conception : un chemin d'erreur qui est un chemin ORDINAIRE se teste et
--  se mesure comme les autres. Avec des exceptions, ces mêmes chemins
--  seraient invisibles à la couverture structurelle du source.
with Mod06.Sensor_Io;
with Testing;

procedure Test_Sensor_Io is

   package Io renames Mod06.Sensor_Io;
   use type Io.Status_Code;

   Suite : constant String := "Sensor_Io";

   function Bonne (Raw : Io.Raw_Value; Age : Io.Age_Ms) return Io.Frame
   is (Raw => Raw, Age => Age, Checksum => Io.Expected_Checksum (Raw, Age));

   Value  : Io.Litres;
   Status : Io.Status_Code;

begin
   Testing.Start (Suite, "decode_nominal", "LLR-M06-002");
   Io.Decode (Bonne (3_200, 20), Value, Status);
   Testing.Check (Status = Io.Ok, "une trame saine est acceptée");
   Testing.Check_Equal (Value, 3_200, "la valeur traverse intacte");

   Testing.Start (Suite, "decode_boundary_age", "LLR-M06-002");
   Io.Decode (Bonne (3_200, Io.Max_Age), Value, Status);
   Testing.Check (Status = Io.Ok, "l'âge maximal exact reste acceptable");
   Io.Decode (Bonne (3_200, Io.Max_Age + 1), Value, Status);
   Testing.Check
     (Status = Io.Stale_Data,
      "une milliseconde de plus et la trame est périmée");

   Testing.Start (Suite, "decode_boundary_value", "LLR-M06-002");
   Io.Decode (Bonne (Io.Litres'Last, 20), Value, Status);
   Testing.Check (Status = Io.Ok, "la pleine échelle exacte est acceptée");
   Io.Decode (Bonne (Io.Litres'Last + 1, 20), Value, Status);
   Testing.Check (Status = Io.Out_Of_Range, "un litre de plus est hors plage");
   Testing.Check_Equal (Value, 0, "la valeur rendue reste définie");

   Testing.Start (Suite, "decode_bad_checksum_wins", "LLR-M06-002");
   Io.Decode ((Raw => 60_000, Age => 9_000, Checksum => 7), Value, Status);
   Testing.Check
     (Status = Io.Bad_Checksum,
      "une trame corrompue est signalée comme telle, pas comme périmée");

   Testing.Start (Suite, "expected_checksum_is_bounded", "LLR-M06-001");
   Testing.Check_Equal
     (Io.Expected_Checksum (0, 0), 0, "checksum de la trame nulle");
   Testing.Check
     (Io.Expected_Checksum (Io.Raw_Value'Last, Io.Age_Ms'Last) <= 255,
      "le checksum reste sur un octet quel que soit l'entrée");

   Testing.Start (Suite, "worst_keeps_the_worst", "LLR-M06-003");
   Testing.Check
     (Io.Worst (Io.Ok, Io.Stale_Data) = Io.Stale_Data,
      "un statut dégradé l'emporte sur Ok");
   Testing.Check
     (Io.Worst (Io.Out_Of_Range, Io.Stale_Data) = Io.Out_Of_Range,
      "le plus grave des deux l'emporte");
   Testing.Check (Io.Worst (Io.Ok, Io.Ok) = Io.Ok, "deux Ok restent Ok");

   Testing.Summary (Suite);
end Test_Sensor_Io;

--  ---------------------------------------------------------------------------
--  Module 01 — tests basés sur les exigences.
--
--  Deux familles obligatoires en DO-178C (§6.4.2) :
--    * cas NOMINAUX      : le domaine d'entrée normal ;
--    * cas de ROBUSTESSE : les bornes, et les entrées qui ne devraient pas
--                          arriver — celles qu'on oublie, et qui trouvent les
--                          vrais défauts.
--
--  L'identifiant d'exigence passé à Testing.Start n'est pas décoratif :
--  tools/trace_check.py s'en sert pour reconstruire la matrice.
--  ---------------------------------------------------------------------------
with Ada.Command_Line;
with Mod01.Sensors;
with Testing;

procedure Test_Sensors is

   package Sensors renames Mod01.Sensors;
   use type Sensors.Raw_Count;
   use type Sensors.Sensor_Id;
   use type Sensors.Litres;
   use type Sensors.Kilograms;

   Suite : constant String := "Sensors";

   --  Non statique : le compilateur ne peut donc pas décider à l'avance que
   --  la conversion échouera. C'est le cas réel — une valeur venue d'un bus.
   Out_Of_Domain : constant Integer := 200 + Ada.Command_Line.Argument_Count;

   procedure Force_Bad_Conversion;

   procedure Force_Bad_Conversion is
      Degrees : Sensors.Celsius;
   begin
      Degrees := Sensors.Celsius (Out_Of_Domain);
      raise Program_Error with Degrees'Image;
   end Force_Bad_Conversion;

   procedure Check_Bad_Conversion is new
     Testing.Check_Raises_Constraint_Error (Force_Bad_Conversion);

   Id      : Sensors.Sensor_Id;
   Known   : Boolean;
   Degrees : Sensors.Celsius;
   Clamped : Boolean;

begin
   Testing.Start (Suite, "modular_type_wraps_to_zero", "LLR-M01-001");
   Testing.Check
     (Sensors.Next_Count (Sensors.Raw_Count'Last) = 0,
      "4095 + 1 revient à 0 sans lever d'exception");
   Testing.Check
     (Sensors.Next_Count (0) = 1, "l'incrément nominal reste un incrément");

   Testing.Start (Suite, "to_litres_nominal", "LLR-M01-002");
   Testing.Check (Sensors.To_Litres (0) = 0.0, "zéro compte vaut zéro litre");
   Testing.Check
     (Sensors.To_Litres (4) = 1.0, "quatre comptes valent un litre");

   Testing.Start (Suite, "to_litres_full_scale", "LLR-M01-002");
   Testing.Check
     (Sensors.To_Litres (Sensors.Raw_Count'Last) = 1_023.75,
      "la pleine échelle reste dans la plage du type");

   Testing.Start (Suite, "to_kilograms_applies_density", "LLR-M01-003");
   Testing.Check
     (Sensors.To_Kilograms (100.0) = 80.25,
      "100 L de Jet A-1 pèsent 80,4 kg, arrondis au pas de 0,25");
   Testing.Check
     (Sensors.To_Kilograms (0.0) = 0.0, "un réservoir vide ne pèse rien");

   Testing.Start (Suite, "decode_sensor_id_nominal", "LLR-M01-004");
   Sensors.Decode_Sensor_Id (0, Id, Known);
   Testing.Check (Known, "l'octet 0 est un identifiant connu");
   Testing.Check (Id = Sensors.Left_Tank, "l'octet 0 désigne Left_Tank");

   Sensors.Decode_Sensor_Id (3, Id, Known);
   Testing.Check
     (Known and then Id = Sensors.Trim_Tank, "l'octet 3 désigne Trim_Tank");

   Testing.Start
     (Suite, "decode_sensor_id_robustness_out_of_domain", "LLR-M01-004");
   Sensors.Decode_Sensor_Id (200, Id, Known);
   Testing.Check (not Known, "l'octet 200 est refusé, pas converti");
   Testing.Check
     (Id = Sensors.Sensor_Id'First,
      "l'identifiant reste défini même quand le décodage échoue");

   Testing.Start (Suite, "clamp_temperature_nominal", "LLR-M01-005");
   Sensors.Clamp_Temperature (20, Degrees, Clamped);
   Testing.Check (not Clamped, "20 °C est dans le domaine");
   Testing.Check_Equal (Degrees, 20, "20 °C traverse sans modification");

   Testing.Start
     (Suite, "clamp_temperature_robustness_below_range", "LLR-M01-005");
   Sensors.Clamp_Temperature (-273, Degrees, Clamped);
   Testing.Check (Clamped, "-273 °C est signalé comme écrêté");
   Testing.Check_Equal (Degrees, -60, "l'écrêtage ramène à la borne basse");

   Testing.Start
     (Suite, "clamp_temperature_robustness_above_range", "LLR-M01-005");
   Sensors.Clamp_Temperature (150, Degrees, Clamped);
   Testing.Check (Clamped, "150 °C est signalé comme écrêté");
   Testing.Check_Equal (Degrees, 90, "l'écrêtage ramène à la borne haute");

   Testing.Start
     (Suite, "subtype_conversion_out_of_range_raises", "LLR-M01-005");
   Check_Bad_Conversion ("Integer 200 converti en Celsius");

   Testing.Summary (Suite);
end Test_Sensors;

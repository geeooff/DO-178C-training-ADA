--  ---------------------------------------------------------------------------
--  FQMS-CAL — étalonnage et consolidation de sondes carburant.
--
--  Ce composant est petit à dessein. Le sujet du module n'est pas le code :
--  c'est la chaîne exigences -> code -> tests, et le fait qu'elle soit
--  vérifiée par un outil plutôt que par une relecture.
--
--  Chaque sous-programme porte une annotation @satisfies. Elle n'est ni un
--  commentaire ni une décoration : tools/trace_check.py la lit pour
--  reconstruire la matrice de traçabilité, et signale toute exigence sans
--  code, tout code sans exigence, et toute référence vers une exigence
--  inexistante.
--
--  Exigences : requirements/srd.md (HLR) et requirements/sdd.md (LLR).
--  ---------------------------------------------------------------------------

package Mod09.Calibration
  with SPARK_Mode => On
is

   subtype Litres is Natural range 0 .. 10_000;

   --  Domaine étalonné de la sonde : au-delà, la conversion n'a pas de sens.
   subtype Raw_Count is Natural range 0 .. 4_000;

   --  Deux litres par compte. Facteur entier : la conversion est exacte.
   Gain : constant := 2;

   --  Capacité physique du réservoir. Distincte de Litres'Last, pour que la
   --  saturation de la consolidation ait un effet observable.
   Capacity : constant Litres := 8_000;

   type Probe_Status is (Valid, Out_Of_Domain);

   --  Mode de consolidation effectivement retenu. Le rendre explicite est une
   --  exigence dérivée : l'équipage doit savoir sur combien de sondes repose
   --  l'indication qu'il lit.
   type Consolidation is (Both_Probes, Left_Only, Right_Only, No_Probe);

   --  @satisfies LLR-FQMSCAL-010, LLR-FQMSCAL-020
   procedure Convert
     (Raw : Natural; Volume : out Litres; Status : out Probe_Status)
   with
     Post =>
       (Status = Valid) = (Raw <= Raw_Count'Last)
       and then (if Status = Valid then Volume = Raw * Gain else Volume = 0);

   --  @satisfies LLR-FQMSCAL-030, LLR-FQMSCAL-040
   procedure Consolidate
     (Left     : Litres;
      Right    : Litres;
      Left_Ok  : Boolean;
      Right_Ok : Boolean;
      Volume   : out Litres;
      Mode     : out Consolidation)
   with
     Post =>
       Volume <= Capacity
       and then Mode
                = (if Left_Ok and then Right_Ok
                   then Both_Probes
                   elsif Left_Ok
                   then Left_Only
                   elsif Right_Ok
                   then Right_Only
                   else No_Probe)
       and then (if Mode = No_Probe then Volume = 0);

end Mod09.Calibration;

--  ---------------------------------------------------------------------------
--  FQMS — Fuel Quantity Management System, DAL B.
--
--  Ce composant est l'aboutissement du dépôt, et sa raison d'être tient en
--  une phrase : il implémente EXACTEMENT les mêmes exigences que le module 16
--  du dépôt frère en C++. Mêmes HLR, mêmes seuils, même hystérésis, même
--  matrice de traçabilité. Seul le langage change.
--
--  Un ingénieur qui ouvre les deux implémentations côte à côte voit en trente
--  secondes ce qui relève du processus — et qui ne bouge pas — et ce qui
--  relève du langage.
--
--  DÉCISION D'ARCHITECTURE MAJEURE : l'état est un PARAMÈTRE, pas un
--  Abstract_State de paquetage. Ce n'est pas une préférence de style, c'est
--  une conséquence mesurée. Le module 04 §1.7 a établi que `gnatcov
--  instrument` ne sait pas instrumenter un paquetage à état abstrait : les
--  variables témoins qu'il insère deviennent de l'état caché absent du
--  Refined_State. Un état passé en paramètre est mesurable, testable en
--  séquence, et réentrant. Le composant DAL B du dépôt paie donc, dans sa
--  conception, une contrainte d'outillage — et la trace.
--  ---------------------------------------------------------------------------

package Mod12.Fqms
  with SPARK_Mode => On
is

   --  --- Domaines

   subtype Kilograms is Natural range 0 .. 20_000;

   --  Domaine de la jauge, identique au dépôt frère.
   subtype Raw_Count is Natural range 0 .. 4_095;

   type Tank_Id is (Left_Wing, Centre, Right_Wing);

   type Capacity_Table is array (Tank_Id) of Kilograms;

   Capacity : constant Capacity_Table :=
     [Left_Wing => 5_000, Centre => 8_000, Right_Wing => 5_000];

   Total_Capacity : constant Kilograms :=
     Capacity (Left_Wing) + Capacity (Centre) + Capacity (Right_Wing);

   --  --- Seuils, tous issus du SRD

   Imbalance_Set   : constant Kilograms := 500;
   Imbalance_Clear : constant Kilograms := 400;
   Low_Level_Set   : constant Kilograms := 1_500;
   Low_Level_Clear : constant Kilograms := 1_700;

   Confirm_Cycles : constant := 5;

   --  --- Entrées et sorties d'un cycle

   --  La mesure brute est un Integer, pas un Raw_Count : elle vient d'un bus
   --  et peut valoir n'importe quoi. C'est tout l'objet de HLR-FQMS-002.
   type Raw_Inputs is array (Tank_Id) of Integer;

   type Quantities is array (Tank_Id) of Kilograms;

   type Quantity_Status is (Valid, Degraded, Unavailable);

   type Cycle_Outputs is record
      Per_Tank  : Quantities := [others => 0];
      Total     : Kilograms := 0;
      Status    : Quantity_Status := Unavailable;
      Imbalance : Boolean := False;
      Low_Level : Boolean := False;
   end record;

   --  --- État persistant entre cycles

   type State is private;

   --  @satisfies LLR-FQMS-100
   function Initial return State;

   --  Compteur de maintenance, saturant. Le domaine est celui d'un mot de
   --  16 bits, comme les compteurs BITE réels — et, contrairement à
   --  Natural'Last, sa saturation est ATTEIGNABLE PAR UN TEST. Le choix
   --  vient de la mesure de couverture : voir le README du module, §3.
   subtype Reject_Count is Natural range 0 .. 65_535;

   function Rejects (S : State; Tank : Tank_Id) return Reject_Count;

   function Imbalance_Alert (S : State) return Boolean;

   function Low_Level_Alert (S : State) return Boolean;

   --  --- Acquisition

   --  Loi linéaire du SRD : 0 à 4 095 points vers 0 à la capacité.
   --
   --  @satisfies LLR-FQMS-010
   function To_Mass (Raw : Raw_Count; Tank : Tank_Id) return Kilograms
   is (Raw * Capacity (Tank) / Raw_Count'Last)
   with Post => To_Mass'Result <= Capacity (Tank);

   --  --- Le cycle

   --  Un cycle complet : acquisition des trois jauges, totalisation, statut,
   --  puis les deux alertes avec leur confirmation et leur hystérésis.
   --
   --  @satisfies LLR-FQMS-020, LLR-FQMS-030, LLR-FQMS-040
   --  @satisfies LLR-FQMS-050, LLR-FQMS-060, LLR-FQMS-070
   --  @satisfies LLR-FQMS-110
   procedure Run_Cycle
     (S : in out State; Raw : Raw_Inputs; Result : out Cycle_Outputs)
   with
     Post =>
       Result.Total <= Total_Capacity
       and then Result.Status
                = (if (for all T in Tank_Id => Raw (T) in Raw_Count)
                   then Valid
                   elsif (for some T in Tank_Id => Raw (T) in Raw_Count)
                   then Degraded
                   else Unavailable)
       and then Result.Imbalance = Imbalance_Alert (S)
       and then Result.Low_Level = Low_Level_Alert (S)
       and then (for all T in Tank_Id =>
                   (if Raw (T) in Raw_Count
                    then Rejects (S, T) = Rejects (S'Old, T)))
       and then (for all T in Tank_Id =>
                   (if Raw (T) not in Raw_Count then Result.Per_Tank (T) = 0));

private

   --  Le compteur ne peut plus atteindre Confirm_Cycles : la transition a
   --  lieu au dernier cycle et le remet à zéro. Le domaine le dit.
   subtype Confirm_Count is Natural range 0 .. Confirm_Cycles - 1;

   type Reject_Counters is array (Tank_Id) of Reject_Count;

   type State is record
      Rejected        : Reject_Counters := [others => 0];
      Imbalance_On    : Boolean := False;
      Low_Level_On    : Boolean := False;
      Imbalance_Ticks : Confirm_Count := 0;
      Low_Level_Ticks : Confirm_Count := 0;
   end record;

   function Rejects (S : State; Tank : Tank_Id) return Reject_Count
   is (S.Rejected (Tank));

   function Imbalance_Alert (S : State) return Boolean
   is (S.Imbalance_On);

   function Low_Level_Alert (S : State) return Boolean
   is (S.Low_Level_On);

end Mod12.Fqms;

package body Mod12.Fqms
  with SPARK_Mode => On
is

   --  Acquisition d'une jauge. Séparée du cycle pour deux raisons : elle se
   --  prouve seule, et elle évite au corps de Run_Cycle une boucle dont
   --  l'invariant coûterait plus cher que les trois appels qu'elle remplace.
   procedure Acquire
     (S     : in out State;
      Tank  : Tank_Id;
      Raw   : Integer;
      Mass  : out Kilograms;
      Valid : out Boolean)
   with
     Post =>
       Valid = (Raw in Raw_Count)
       and then Mass <= Capacity (Tank)
       and then (if not Valid then Mass = 0)
       and then (if Valid then Rejects (S, Tank) = Rejects (S'Old, Tank))
       and then (for all T in Tank_Id =>
                   (if T /= Tank then Rejects (S, T) = Rejects (S'Old, T)))
       and then Imbalance_Alert (S) = Imbalance_Alert (S'Old)
       and then Low_Level_Alert (S) = Low_Level_Alert (S'Old);

   procedure Acquire
     (S     : in out State;
      Tank  : Tank_Id;
      Raw   : Integer;
      Mass  : out Kilograms;
      Valid : out Boolean) is
   begin
      if Raw in Raw_Count then
         Mass := To_Mass (Raw, Tank);
         Valid := True;
      else
         --  HLR-FQMS-002 : aucune quantité n'est produite. Rendre zéro
         --  plutôt qu'une valeur plausible est le point de sécurité du
         --  composant : une quantité fausse est indiscernable d'une bonne.
         Mass := 0;
         Valid := False;

         --  HLR-FQMS-040 : comptage de maintenance, saturant.
         if S.Rejected (Tank) < Reject_Count'Last then
            S.Rejected (Tank) := S.Rejected (Tank) + 1;
         end if;
      end if;
   end Acquire;

   --  Machine à confirmation commune aux deux alertes. Le motif est
   --  identique — n cycles consécutifs pour lever, n pour effacer, avec deux
   --  seuils différents — donc il s'écrit une fois.
   --
   --  Écriture issue de la MESURE de couverture. La première version gardait
   --  l'incrément par `if Ticks < Confirm_Cycles`, ce qui produisait une
   --  branche inatteignable : le compteur est remis à zéro à chaque
   --  transition, donc il n'atteint jamais Confirm_Cycles au moment d'être
   --  incrémenté. La forme ci-dessous n'a plus de garde morte, et le domaine
   --  de Confirm_Count s'est resserré d'autant.
   procedure Confirm
     (Active         : in out Boolean;
      Ticks          : in out Confirm_Count;
      Transition_Now : Boolean)
   with Post => (if not Transition_Now then Active = Active'Old);

   procedure Confirm
     (Active         : in out Boolean;
      Ticks          : in out Confirm_Count;
      Transition_Now : Boolean) is
   begin
      if not Transition_Now then
         --  La séquence est rompue : la confirmation repart de zéro. C'est
         --  ce qui donne son sens à « cycles CONSÉCUTIFS ».
         Ticks := 0;
      elsif Ticks = Confirm_Cycles - 1 then
         Active := not Active;
         Ticks := 0;
      else
         Ticks := Ticks + 1;
      end if;
   end Confirm;

   function Initial return State
   is (Rejected        => [others => 0],
       Imbalance_On    => False,
       Low_Level_On    => False,
       Imbalance_Ticks => 0,
       Low_Level_Ticks => 0);

   procedure Run_Cycle
     (S : in out State; Raw : Raw_Inputs; Result : out Cycle_Outputs)
   is
      Mass  : Quantities := [others => 0];
      Ok    : array (Tank_Id) of Boolean := [others => False];
      Total : Kilograms;
      Count : Natural range 0 .. 3;
      Gap   : Kilograms;
   begin
      --  --- Acquisition (HLR-FQMS-001, HLR-FQMS-002, HLR-FQMS-040)
      for Tank in Tank_Id loop
         Acquire (S, Tank, Raw (Tank), Mass (Tank), Ok (Tank));
         pragma
           Loop_Invariant (for all T in Tank_Id => Mass (T) <= Capacity (T));
         pragma
           Loop_Invariant
             (for all T in Tank_Id =>
                (if Raw (T) not in Raw_Count then Mass (T) = 0));
         pragma
           Loop_Invariant
             (for all T in Tank_Id range Tank_Id'First .. Tank =>
                Ok (T) = (Raw (T) in Raw_Count));
         pragma
           Loop_Invariant
             (for all T in Tank_Id =>
                (if Raw (T) in Raw_Count
                 then Rejects (S, T) = Rejects (S'Loop_Entry, T)));
         pragma
           Loop_Invariant
             (Imbalance_Alert (S) = Imbalance_Alert (S'Loop_Entry));
         pragma
           Loop_Invariant
             (Low_Level_Alert (S) = Low_Level_Alert (S'Loop_Entry));
      end loop;

      --  --- Totalisation (HLR-FQMS-010)
      --
      --  La somme est écrite sans boucle : trois termes, une borne évidente,
      --  et aucun invariant à écrire. Sur une architecture figée à trois
      --  réservoirs, c'est plus simple ET plus facile à prouver.
      Total :=
        (if Ok (Left_Wing) then Mass (Left_Wing) else 0)
        + (if Ok (Centre) then Mass (Centre) else 0)
        + (if Ok (Right_Wing) then Mass (Right_Wing) else 0);

      Count :=
        Boolean'Pos (Ok (Left_Wing))
        + Boolean'Pos (Ok (Centre))
        + Boolean'Pos (Ok (Right_Wing));

      --  --- Statut (HLR-FQMS-011)
      Result.Per_Tank := Mass;
      Result.Total := Total;
      Result.Status :=
        (if Count = 3
         then Valid
         elsif Count = 0
         then Unavailable
         else Degraded);

      --  --- Alerte de déséquilibre (HLR-FQMS-020/021/022)
      --
      --  Non évaluée si l'une des deux jauges d'aile est en panne : un écart
      --  calculé sur une seule jauge n'a aucun sens. L'alerte est CONSERVÉE,
      --  et la confirmation en cours est remise à zéro — la séquence de
      --  cycles consécutifs est rompue, la reprendre serait faux.
      if Ok (Left_Wing) and then Ok (Right_Wing) then
         Gap :=
           (if Mass (Left_Wing) >= Mass (Right_Wing)
            then Mass (Left_Wing) - Mass (Right_Wing)
            else Mass (Right_Wing) - Mass (Left_Wing));

         Confirm
           (Active         => S.Imbalance_On,
            Ticks          => S.Imbalance_Ticks,
            Transition_Now =>
              (if S.Imbalance_On
               then Gap < Imbalance_Clear
               else Gap > Imbalance_Set));
      else
         S.Imbalance_Ticks := 0;
      end if;

      --  --- Alerte bas niveau (HLR-FQMS-030/031/032)
      --
      --  Non évaluée si UNE SEULE des trois jauges est en panne : une
      --  quantité partielle est nécessairement inférieure à la quantité
      --  réelle, et l'évaluer lèverait une alerte bas niveau injustifiée.
      if Count = 3 then
         Confirm
           (Active         => S.Low_Level_On,
            Ticks          => S.Low_Level_Ticks,
            Transition_Now =>
              (if S.Low_Level_On
               then Total > Low_Level_Clear
               else Total < Low_Level_Set));
      else
         S.Low_Level_Ticks := 0;
      end if;

      Result.Imbalance := S.Imbalance_On;
      Result.Low_Level := S.Low_Level_On;
   end Run_Cycle;

end Mod12.Fqms;

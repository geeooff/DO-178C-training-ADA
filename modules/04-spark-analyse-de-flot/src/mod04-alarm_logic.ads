--  ---------------------------------------------------------------------------
--  La logique de décision, sans état — module 04.
--
--  Pourquoi séparer ce paquetage de Fuel_Monitor ? Parce que l'état et la
--  décision ne se vérifient pas de la même façon.
--
--  Ici, `Global => null` sur chaque sous-programme : aucune variable touchée,
--  aucun couplage de données, un résultat qui ne dépend que des arguments.
--  Conséquence pratique : ces sous-programmes se testent exhaustivement, se
--  prouvent en quelques secondes, et leur couverture MC/DC se mesure sans
--  difficulté.
--
--  C'est un motif de conception classique en avionique, et pas seulement une
--  commodité d'outillage : on garde la coquille d'état MINCE, pour que la
--  vérification porte sur la logique.
--  ---------------------------------------------------------------------------

package Mod04.Alarm_Logic
  with SPARK_Mode => On
is

   subtype Litres is Natural range 0 .. 10_000;

   --  Seuil d'alarme bas. Une constante, donc pas de couplage de données.
   Low_Level_Threshold : constant Litres := 500;

   --  Seuil d'alarme haut : au-delà, la jauge est jugée incohérente.
   High_Level_Threshold : constant Litres := 9_500;

   --  @satisfies LLR-M04-006
   function Is_Low (Value : Litres) return Boolean
   is (Value < Low_Level_Threshold)
   with Global => null;

   --  @satisfies LLR-M04-007
   function Is_Implausible (Value : Litres) return Boolean
   is (Value > High_Level_Threshold)
   with Global => null;

   --  L'alarme se lève dans les deux cas. Deux conditions dans une décision :
   --  c'est ce qui donne à MC/DC quelque chose à mesurer, là où une condition
   --  unique ne se distingue pas de la couverture de décision.
   --
   --  @satisfies LLR-M04-008
   function Alarm_For (Value : Litres) return Boolean
   with
     Global => null,
     Post   =>
       Alarm_For'Result = (Is_Low (Value) or else Is_Implausible (Value));

   --  Incrément saturant du compteur de mesures. Sans saturation, le
   --  compteur déborderait après 2**31 mesures — soit environ 68 ans à
   --  1 Hz, ce qui n'est PAS une raison de l'ignorer sur un calculateur qui
   --  vole trente ans.
   --
   --  @satisfies LLR-M04-009
   function Next_Sample_Count (Current : Natural) return Natural
   with
     Global => null,
     Post   =>
       (if Current = Natural'Last
        then Next_Sample_Count'Result = Natural'Last
        else Next_Sample_Count'Result = Current + 1);

end Mod04.Alarm_Logic;

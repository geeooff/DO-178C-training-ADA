--  ---------------------------------------------------------------------------
--  Alarme carburant — module 10.
--
--  Une seule décision, trois conditions. C'est le plus petit code sur lequel
--  la différence entre couverture de DÉCISION et couverture MC/DC se mesure
--  au lieu de se raconter.
--
--  Deux campagnes exercent ce même code :
--    * tests/test_warning.adb          : atteint MC/DC ;
--    * decision-seule/…/test_decision_only.adb : atteint 100 % de décision,
--      et s'arrête là.
--
--  Les deux rapports sont produits côte à côte par scripts/coverage.sh.
--  ---------------------------------------------------------------------------

package Mod10.Warning
  with SPARK_Mode => On
is

   --  L'alarme se lève si le niveau est bas, OU si un déséquilibre est
   --  détecté ALORS QU'une sonde est en panne — un déséquilibre seul étant
   --  normal en virage, et une panne de sonde seule n'étant pas une alarme
   --  carburant.
   --
   --  @satisfies LLR-FQMSWRN-010
   function Alarm
     (Low_Fuel : Boolean; Imbalance : Boolean; Sensor_Fault : Boolean)
      return Boolean
   with
     Post =>
       Alarm'Result = (Low_Fuel or else (Imbalance and then Sensor_Fault));

   --  Nombre de conditions de la décision ci-dessus. Il est ici pour une
   --  raison : MC/DC demande N+1 cas de test au minimum pour N conditions,
   --  et le rapport de couverture doit pouvoir se lire contre ce chiffre.
   --
   --  @satisfies LLR-FQMSWRN-020
   Condition_Count : constant := 3;

end Mod10.Warning;

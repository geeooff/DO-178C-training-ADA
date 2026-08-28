--  ---------------------------------------------------------------------------
--  Campagne FAIBLE — 100 % de décision, et rien de plus.
--
--  Deux cas suffisent à faire prendre à la décision ses deux valeurs. Un
--  projet DAL C s'arrêterait là, et il aurait raison : le tableau A-7 ne lui
--  demande que la couverture de décision (objectif 6). Un projet DAL A ou B
--  qui s'arrêterait là serait en défaut.
--
--  Comparer le rapport de ce projet à celui de la campagne complète est
--  l'exercice central du module.
--  ---------------------------------------------------------------------------
with Mod10.Warning;
with Testing;

procedure Test_Decision_Only is

   package Warn renames Mod10.Warning;

   Suite : constant String := "Warning_Decision_Only";

begin
   Testing.Start (Suite, "decision_true", "LLR-FQMSWRN-010");
   Testing.Check
     (Warn.Alarm (True, False, False), "la décision prend la valeur vraie");

   Testing.Start (Suite, "decision_false", "LLR-FQMSWRN-010");
   Testing.Check
     (not Warn.Alarm (False, False, False),
      "la décision prend la valeur fausse");

   Testing.Summary (Suite);
end Test_Decision_Only;

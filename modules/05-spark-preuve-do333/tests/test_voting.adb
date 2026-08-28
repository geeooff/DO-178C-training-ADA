--  Module 05 — campagne basée sur les exigences.
--
--  Question à se poser en lisant ce fichier : à quoi servent encore ces
--  tests, puisque gnatprove a démontré les postconditions pour TOUTES les
--  entrées ? Le README §1.6 y répond — et la réponse n'est pas « à rien ».
with Mod05.Voting;
with Testing;

procedure Test_Voting is

   package Voting renames Mod05.Voting;

   Suite : constant String := "Voting";

   Mixed  : constant Voting.Reading_Array := [3_000, 2_500, 400, 1_800];
   All_Ok : constant Voting.Reading_Array := [3_000, 2_500, 1_800];
   Empty  : constant Voting.Reading_Array (1 .. 0) := [others => 0];

   Index : Natural;
   Found : Boolean;

begin
   Testing.Start (Suite, "mid_value_nominal", "LLR-M05-002");
   Testing.Check_Equal
     (Voting.Mid_Value (2_000, 2_050, 1_980), 2_000, "trois voies saines");
   Testing.Check_Equal (Voting.Mid_Value (1, 2, 3), 2, "ordre croissant");
   Testing.Check_Equal (Voting.Mid_Value (3, 2, 1), 2, "ordre décroissant");

   Testing.Start (Suite, "mid_value_rejects_outlier", "LLR-M05-002");
   Testing.Check_Equal
     (Voting.Mid_Value (2_000, 9_999, 1_980),
      2_000,
      "un capteur bloqué haut est écarté");
   Testing.Check_Equal
     (Voting.Mid_Value (0, 2_050, 1_980),
      1_980,
      "un capteur bloqué bas est écarté");

   Testing.Start (Suite, "mid_value_with_equal_inputs", "LLR-M05-002");
   Testing.Check_Equal
     (Voting.Mid_Value (500, 500, 500), 500, "trois valeurs égales");
   Testing.Check_Equal
     (Voting.Mid_Value (500, 500, 9_000),
      500,
      "deux valeurs égales sur trois");

   --  Les six permutations de trois valeurs distinctes. Chaque décision de
   --  Mid_Value combine quatre conditions ; les cas nominaux ci-dessus n'en
   --  exerçaient que six effets indépendants sur onze, alors même que la
   --  preuve était complète. C'est l'illustration la plus nette du module :
   --  la preuve et la couverture structurelle ne mesurent pas la même chose.
   Testing.Start (Suite, "mid_value_all_orderings", "LLR-M05-002");
   Testing.Check_Equal (Voting.Mid_Value (10, 20, 30), 20, "A < B < C");
   Testing.Check_Equal (Voting.Mid_Value (10, 30, 20), 20, "A < C < B");
   Testing.Check_Equal (Voting.Mid_Value (20, 10, 30), 20, "B < A < C");
   Testing.Check_Equal (Voting.Mid_Value (20, 30, 10), 20, "C < A < B");
   Testing.Check_Equal (Voting.Mid_Value (30, 10, 20), 20, "B < C < A");
   Testing.Check_Equal (Voting.Mid_Value (30, 20, 10), 20, "C < B < A");

   Testing.Start (Suite, "find_first_low_finds_it", "LLR-M05-003");
   Voting.Find_First_Low (Mixed, Index, Found);
   Testing.Check (Found, "un réservoir bas est présent");
   Testing.Check_Equal (Index, 3, "c'est le troisième");

   Testing.Start (Suite, "find_first_low_finds_none", "LLR-M05-003");
   Voting.Find_First_Low (All_Ok, Index, Found);
   Testing.Check (not Found, "aucun réservoir bas");
   Testing.Check_Equal (Index, 0, "l'indice rendu est neutre");

   Testing.Start (Suite, "find_first_low_empty_array", "LLR-M05-003");
   Voting.Find_First_Low (Empty, Index, Found);
   Testing.Check (not Found, "un tableau vide ne trouve rien");

   Testing.Start (Suite, "refuel_steps_nominal", "LLR-M05-004");
   Testing.Check_Equal
     (Voting.Refuel_Steps (3_000, 400), 8, "3 000 L par charges de 400 L");
   Testing.Check_Equal
     (Voting.Refuel_Steps (2_000, 1_000), 2, "division exacte");

   Testing.Start (Suite, "refuel_steps_boundaries", "LLR-M05-004");
   Testing.Check_Equal (Voting.Refuel_Steps (0, 100), 0, "rien à charger");
   Testing.Check_Equal (Voting.Refuel_Steps (1, 1), 1, "une seule charge");
   Testing.Check_Equal
     (Voting.Refuel_Steps (100, 10_000),
      1,
      "une charge plus grande que la cible suffit");

   Testing.Summary (Suite);
end Test_Voting;

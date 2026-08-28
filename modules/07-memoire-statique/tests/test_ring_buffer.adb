--  Module 07 — campagne basée sur les exigences.
with Mod07.Ring_Buffer;
with Testing;

procedure Test_Ring_Buffer is

   package Ring renames Mod07.Ring_Buffer;

   Suite : constant String := "Ring_Buffer";

   B     : Ring.Buffer;
   Value : Ring.Litres;

begin
   Testing.Start (Suite, "clear_empties", "LLR-M07-001");
   Ring.Clear (B);
   Testing.Check (Ring.Is_Empty (B), "une file neuve est vide");
   Testing.Check (not Ring.Is_Full (B), "et elle n'est pas pleine");
   Testing.Check_Equal (Ring.Length (B), 0, "longueur nulle");

   Testing.Start (Suite, "push_then_pop_is_fifo", "LLR-M07-002");
   Ring.Push (B, 100);
   Ring.Push (B, 200);
   Ring.Push (B, 300);
   Testing.Check_Equal (Ring.Length (B), 3, "trois éléments");
   Ring.Pop (B, Value);
   Testing.Check_Equal (Value, 100, "le premier entré sort le premier");
   Ring.Pop (B, Value);
   Testing.Check_Equal (Value, 200, "puis le deuxième");
   Testing.Check_Equal (Ring.Length (B), 1, "il en reste un");

   Testing.Start (Suite, "fills_to_capacity", "LLR-M07-002");
   Ring.Clear (B);
   for I in 1 .. Ring.Capacity loop
      Ring.Push (B, I);
   end loop;
   Testing.Check (Ring.Is_Full (B), "la file atteint sa capacité");
   Testing.Check_Equal
     (Ring.Length (B), Ring.Capacity, "longueur égale à la capacité");

   Testing.Start (Suite, "wraps_around", "LLR-M07-003");
   --  Vider puis remplir de nouveau force l'indice de tête à repasser par
   --  zéro : c'est le seul chemin qui exerce le `mod Capacity`.
   for I in 1 .. Ring.Capacity loop
      Ring.Pop (B, Value);
      Testing.Check_Equal (Value, I, "l'ordre FIFO tient sur un tour complet");
   end loop;
   Testing.Check (Ring.Is_Empty (B), "la file est vidée");

   Ring.Push (B, 42);
   Ring.Pop (B, Value);
   Testing.Check_Equal (Value, 42, "et elle reste utilisable après le tour");

   Testing.Summary (Suite);
end Test_Ring_Buffer;

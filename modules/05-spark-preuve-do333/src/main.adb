with Ada.Text_IO;
with Mod05.Voting;

--  Démonstration : ce que la preuve garantit, et ce qu'elle ne garantit pas.

procedure Main is

   package Voting renames Mod05.Voting;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   procedure Voter (A, B, C : Voting.Litres);

   procedure Voter (A, B, C : Voting.Litres) is
   begin
      Ada.Text_IO.Put_Line
        ("  ("
         & A'Image
         & ","
         & B'Image
         & ","
         & C'Image
         & " ) -> "
         & Voting.Mid_Value (A, B, C)'Image
         & " L");
   end Voter;

   Tanks : constant Voting.Reading_Array := [3_000, 2_500, 400, 1_800];
   Index : Natural;
   Found : Boolean;

begin
   Titre ("Vote médian : un capteur en panne est écarté");
   Voter (2_000, 2_050, 1_980);
   Voter (2_000, 9_999, 1_980);
   Voter (0, 2_050, 1_980);
   Ada.Text_IO.Put_Line
     ("  la médiane est prouvée pour TOUTES les entrées, pas pour ces trois.");

   Titre ("Parcours prouvé : premier réservoir sous le seuil");
   Voting.Find_First_Low (Tanks, Index, Found);
   Ada.Text_IO.Put_Line
     ("  trouvé = " & Found'Image & ", indice =" & Index'Image);
   Ada.Text_IO.Put_Line
     ("  et il est démontré qu'aucun réservoir avant lui n'était bas.");

   Titre ("Terminaison démontrée par Loop_Variant");
   Ada.Text_IO.Put_Line
     ("  3 000 L par charges de 400 L :"
      & Voting.Refuel_Steps (3_000, 400)'Image
      & " charges");
   Ada.Text_IO.Put_Line
     ("  1 L par charges de 1 L      :"
      & Voting.Refuel_Steps (1, 1)'Image
      & " charge");
end Main;

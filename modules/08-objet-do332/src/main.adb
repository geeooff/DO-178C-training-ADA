with Ada.Text_IO;
with Mod08.Instruments;

--  Démonstration : un seul site d'appel, deux cibles réelles.

procedure Main is

   package Ins renames Mod08.Instruments;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   --  Un seul sous-programme, appelé avec deux types réels différents.
   --  L'appel à Reading est DISPATCHANT : le code exécuté dépend du tag.
   procedure Mesurer (Nom : String; Sonde : Ins.Instrument'Class);

   procedure Mesurer (Nom : String; Sonde : Ins.Instrument'Class) is
   begin
      Ada.Text_IO.Put_Line
        ("  "
         & Nom
         & " : 0 ->"
         & Ins.Reading (Sonde, 0)'Image
         & " L, 500 ->"
         & Ins.Reading (Sonde, 500)'Image
         & " L, 1000 ->"
         & Ins.Reading (Sonde, 1_000)'Image
         & " L");
   end Mesurer;

   Cap : constant Ins.Capacitive := (Serial => 1, Gain => 10);
   Ult : constant Ins.Ultrasonic := (Serial => 2, Dead_Zone => 300);

begin
   Titre ("Un site d'appel, deux cibles");
   Mesurer ("capacitive", Cap);
   Mesurer ("ultrasons ", Ult);
   Ada.Text_IO.Put_Line
     ("  la ligne d'appel est la même ; le code exécuté ne l'est pas.");

   Titre ("Substitution : la dérivée renforce, jamais n'affaiblit");
   Ada.Text_IO.Put_Line ("  Post'Class de la racine : résultat <= 10 000 L");
   Ada.Text_IO.Put_Line
     ("  Post de la dérivée      : résultat >= zone morte, soit 300 L");
   Ada.Text_IO.Put_Line
     ("  ultrasons à 0 compte    :"
      & Ins.Reading (Ult, 0)'Image
      & " L, jamais moins que sa zone morte.");

   Titre ("Plausibilité : chaque technologie a son domaine");
   Ada.Text_IO.Put_Line
     ("  capacitive juge 100 L plausible : "
      & Ins.Is_Plausible (Cap, 100)'Image);
   Ada.Text_IO.Put_Line
     ("  ultrasons juge 100 L plausible  : "
      & Ins.Is_Plausible (Ult, 100)'Image
      & "  (sous sa zone morte)");
end Main;

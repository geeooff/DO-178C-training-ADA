package body Mod08.Instruments
  with SPARK_Mode => On
is

   function Reading (Self : Instrument'Class; Raw : Raw_Count) return Litres is
   begin
      return To_Litres (Self, Raw);
   end Reading;

   --  JUSTIFICATION D'UNE VÉRIFICATION NON PROUVÉE.
   --
   --  gnatprove ne sait pas démontrer qu'un appel DISPATCHANT termine : il
   --  faudrait raisonner sur toutes les redéfinitions présentes et futures,
   --  y compris celles d'une extension écrite ailleurs. Il rend donc un
   --  « medium », que --checks-as-errors=on transforme en échec.
   --
   --  L'annotation ci-dessous n'efface pas la vérification : elle la
   --  justifie, et gnatprove la rapporte comme justifiée avec sa raison. En
   --  DO-178C, c'est exactement ce qu'on attend d'une déviation — écrite,
   --  argumentée, et visible dans la donnée de vie plutôt que dans la
   --  mémoire d'un relecteur.
   pragma
     Annotate
       (GNATprove,
        False_Positive,
        "implicit aspect Always_Terminates",
        "les deux redefinitions de To_Litres sont des expression functions "
          & "sans boucle ni recursion, donc terminantes par construction ; "
          & "toute extension future devra le rester, ce qui releve du "
          & "standard "
          & "de codage du module 11");

end Mod08.Instruments;

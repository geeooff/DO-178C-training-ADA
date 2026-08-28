--  ---------------------------------------------------------------------------
--  Harnais de test minimal.
--
--  Pourquoi pas AUnit, qui existe pourtant comme crate Alire ? Trois raisons.
--  Il exigerait un `alire.toml` par module, alors que le dépôt s'en tient à
--  gprbuild. Il repose sur des types étiquetés et de l'allocation dynamique,
--  que le module 07 apprend à bannir. Et surtout il ne sait rien des
--  exigences : `Start` porte ici l'identifiant d'exigence dans l'appel, ce
--  qui rend la traçabilité vérifiable par `tools/trace_check.py` au lieu de
--  reposer sur une relecture.
--
--  Ce harnais est du code de vérification, pas du code embarqué. Il a donc le
--  droit d'utiliser Ada.Text_IO et des variables d'état, interdits ailleurs.
--  `SPARK_Mode => Off` l'exclut explicitement de la preuve : c'est un choix
--  déclaré, pas un oubli.
--  ---------------------------------------------------------------------------

package Testing
  with SPARK_Mode => Off
is

   --  Ouvre un cas de test. `Requirements` est la liste, séparée par des
   --  virgules, des exigences que ce cas vérifie — par exemple
   --  "LLR-M01-001,LLR-M01-002". Ce champ est une donnée de vie : le
   --  renseigner faux est un défaut documentaire, pas une négligence.
   procedure Start (Suite : String; Test_Case : String; Requirements : String);

   procedure Check (Condition : Boolean; Label : String);

   procedure Check_Equal (Actual, Expected : Integer; Label : String);

   procedure Check_Equal (Actual, Expected : String; Label : String);

   --  Vérifie qu'une action lève bien Constraint_Error. C'est le pendant
   --  Ada des tests de robustesse du §6.4.2 : on ne teste pas seulement que
   --  le nominal marche, mais que l'anormal est refusé.
   --
   --  Générique et non « accès à sous-programme » : un `access procedure`
   --  refuserait à la compilation qu'on lui passe une procédure déclarée
   --  dans le corps d'un test (règles d'accessibilité), alors que c'est
   --  exactement là qu'on veut l'écrire. Le générique n'a pas ce défaut, et
   --  évite au harnais le type accès que le module 07 apprend à bannir.
   generic
      with procedure Action;
   procedure Check_Raises_Constraint_Error (Label : String);

   --  Même chose pour Assertion_Error, que lèvent les aspects Pre, Post,
   --  Type_Invariant et Predicate lorsque -gnata est actif.
   generic
      with procedure Action;
   procedure Check_Raises_Assertion_Error (Label : String);

   --  Affiche le bilan et positionne le code de retour du programme : 0 si
   --  tout passe, 1 sinon. C'est ce code que la CI regarde.
   procedure Summary (Suite : String);

end Testing;

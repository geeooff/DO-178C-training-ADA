with Ada.Real_Time;
with Ada.Text_IO;
with Cyclic;
with GNAT.OS_Lib;

--  Démonstration du profil Ravenscar.

procedure Ravenscar_Demo is
   use Ada.Real_Time;
   Deadline : constant Time := Clock + Milliseconds (300);
begin
   --  `delay until` et non `delay` : Ravenscar interdit le délai relatif,
   --  parce qu'une échéance absolue s'analyse et une durée relative dérive.
   delay until Deadline;

   Ada.Text_IO.Put_Line
     ("Profil Ravenscar : cycles exécutés =" & Cyclic.Counter.Value'Image);

   --  Un programme Ravenscar EST fait pour ne pas se terminer : ses tâches
   --  bouclent tant que le calculateur est alimenté. Sortir du processus est
   --  donc ici un artifice de démonstration, et pas un motif à reproduire.
   GNAT.OS_Lib.OS_Exit (0);
end Ravenscar_Demo;

with Ada.Real_Time;

package body Cyclic is

   protected body Counter is

      procedure Bump is
      begin
         if Cycles < Natural'Last then
            Cycles := Cycles + 1;
         end if;
      end Bump;

      function Value return Natural
      is (Cycles);

   end Counter;

   --  Tâche périodique de niveau bibliothèque. Le motif « Next := Next +
   --  Period ; delay until Next » est LE motif Ravenscar : il donne une
   --  période stable même si un cycle déborde, contrairement à un délai
   --  relatif qui accumulerait la dérive.
   task Periodic;

   task body Periodic is
      use Ada.Real_Time;
      Period : constant Time_Span := Milliseconds (10);
      Next   : Time := Clock;
   begin
      for Cycle in 1 .. 5 loop
         Next := Next + Period;
         delay until Next;
         Counter.Bump;
      end loop;
   end Periodic;

end Cyclic;

with Ada.Assertions;
with Ada.Command_Line;
with Ada.Text_IO;

package body Testing
  with SPARK_Mode => Off
is

   Cases    : Natural := 0;
   Checks   : Natural := 0;
   Failures : Natural := 0;

   procedure Start (Suite : String; Test_Case : String; Requirements : String)
   is
   begin
      Cases := Cases + 1;
      Ada.Text_IO.Put_Line
        ("  " & Suite & "." & Test_Case & "  [" & Requirements & "]");
   end Start;

   procedure Check (Condition : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not Condition then
         Failures := Failures + 1;
         Ada.Text_IO.Put_Line ("    ECHEC : " & Label);
      end if;
   end Check;

   procedure Check_Equal (Actual, Expected : Integer; Label : String) is
   begin
      Check
        (Actual = Expected,
         Label
         & " (attendu"
         & Expected'Image
         & ", obtenu"
         & Actual'Image
         & ")");
   end Check_Equal;

   procedure Check_Equal (Actual, Expected : String; Label : String) is
   begin
      Check
        (Actual = Expected,
         Label & " (attendu """ & Expected & """, obtenu """ & Actual & """)");
   end Check_Equal;

   procedure Check_Raises_Constraint_Error (Label : String) is
      Raised : Boolean := False;
   begin
      begin
         Action;
      exception
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, Label & " doit lever Constraint_Error");
   end Check_Raises_Constraint_Error;

   procedure Check_Raises_Assertion_Error (Label : String) is
      Raised : Boolean := False;
   begin
      begin
         Action;
      exception
         when Ada.Assertions.Assertion_Error =>
            Raised := True;
      end;
      Check (Raised, Label & " doit lever Assertion_Error");
   end Check_Raises_Assertion_Error;

   procedure Summary (Suite : String) is
      use Ada.Command_Line;
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line
        (Suite
         & " :"
         & Cases'Image
         & " cas,"
         & Checks'Image
         & " verifications,"
         & Failures'Image
         & " echec(s).");

      if Failures = 0 then
         Set_Exit_Status (Success);
      else
         Set_Exit_Status (Failure);
      end if;
   end Summary;

end Testing;

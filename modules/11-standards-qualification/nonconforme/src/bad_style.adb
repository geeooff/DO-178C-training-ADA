--  Ce fichier viole DÉLIBÉRÉMENT le standard de codage du module 11.
--  Chaque violation est annotée par la règle qu'elle enfreint.
--  Ne pas le « corriger » : il est le contre-exemple.
with Ada.Text_IO;
procedure Bad_Style is
   --  R-11 : type nu, aucun domaine borné.
   Fuel : Integer := 0;

   --  R-61 : identifiant en français.
   Quantite_Restante : Integer := 0;

   --  R-60 : procédure imbriquée sans déclaration préalable, indentation à 2
   --  au lieu de 3, et une ligne qui dépasse largement les 79 colonnes.
   procedure Ajouter (X : Integer) is
   begin
     Fuel := Fuel + X;   -- R-62 : commentaire qui paraphrase le code : additionne X a Fuel
   end Ajouter;

   --  R-43 : récursion. La profondeur de pile cesse d'être calculable.
   function Compte_A_Rebours (N : Integer) return Integer is
   begin
      if N <= 0 then
         return 0;
      else
         return 1 + Compte_A_Rebours (N - 1);
      end if;
   end Compte_A_Rebours;

begin
   Ajouter (500);

   --  R-21 : programmation défensive redondante — le domaine est déjà
   --  garanti par l'appel juste au-dessus.
   if Fuel < 0 then
      Fuel := 0;
   end if;

   Quantite_Restante := Fuel;

   --  R-42 : Ada.Text_IO et chaîne de longueur variable dans du code qui
   --  prétendrait voler.
   Ada.Text_IO.Put_Line ("Fuel =" & Quantite_Restante'Image);
   Ada.Text_IO.Put_Line
     ("Compte a rebours :" & Compte_A_Rebours (5)'Image);
end Bad_Style;

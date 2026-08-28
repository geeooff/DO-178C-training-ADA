with Ada.Text_IO;
with Mod07.Ring_Buffer;

--  Démonstration : une file de huit éléments dont la taille est connue à la
--  compilation. Rien n'est alloué, rien n'est libéré, rien ne peut fragmenter.

procedure Main is

   package Ring renames Mod07.Ring_Buffer;

   procedure Titre (Texte : String);

   procedure Titre (Texte : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("== " & Texte & " ==");
   end Titre;

   B     : Ring.Buffer;
   Value : Ring.Litres;

begin
   Titre ("Empreinte connue à la compilation");
   Ada.Text_IO.Put_Line ("Capacité :" & Ring.Capacity'Image & " éléments");
   Ada.Text_IO.Put_Line
     ("Taille du type Buffer :"
      & Natural'Image (Ring.Buffer'Size / 8)
      & " octets");
   Ada.Text_IO.Put_Line ("  calculée, pas observée : aucun tas n'intervient.");

   Titre ("Remplissage puis vidage, en ordre FIFO");
   Ring.Clear (B);
   for I in 1 .. 5 loop
      Ring.Push (B, Ring.Litres (I * 100));
   end loop;
   Ada.Text_IO.Put_Line ("Longueur :" & Ring.Length (B)'Image);

   while not Ring.Is_Empty (B) loop
      Ring.Pop (B, Value);
      Ada.Text_IO.Put (Value'Image);
   end loop;
   Ada.Text_IO.New_Line;

   Titre ("La capacité est une borne, pas une suggestion");
   Ring.Clear (B);
   for I in 1 .. Ring.Capacity loop
      Ring.Push (B, I);
   end loop;
   Ada.Text_IO.Put_Line
     ("Plein :"
      & Ring.Is_Full (B)'Image
      & " : un Push de plus violerait la précondition,");
   Ada.Text_IO.Put_Line
     ("et gnatprove le refuse chez l'appelant, pas à l'exécution.");
end Main;

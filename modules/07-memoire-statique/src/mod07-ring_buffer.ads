--  ---------------------------------------------------------------------------
--  File circulaire à capacité fixe — module 07.
--
--  Aucune allocation, aucun pointeur, aucune capacité qui dépend de
--  l'exécution. La taille est connue à la compilation, donc l'empreinte
--  mémoire du programme se calcule au lieu de s'observer.
--
--  Ce que le dépôt frère en C++ doit construire à la main — un StaticVector
--  avec son placement new, son alignement et sa destruction manuelle — tient
--  ici dans un tableau contraint et un enregistrement privé. C'est la
--  différence la plus économique entre les deux langages.
--  ---------------------------------------------------------------------------

package Mod07.Ring_Buffer
  with SPARK_Mode => On
is

   Capacity : constant := 8;

   subtype Litres is Natural range 0 .. 10_000;

   subtype Count_Type is Natural range 0 .. Capacity;

   subtype Index_Type is Natural range 0 .. Capacity - 1;

   type Buffer is private;

   function Length (B : Buffer) return Count_Type;

   function Is_Empty (B : Buffer) return Boolean
   is (Length (B) = 0);

   function Is_Full (B : Buffer) return Boolean
   is (Length (B) = Capacity);

   --  Fonction de spécification : le K-ième élément dans l'ordre
   --  d'insertion. `Ghost` veut dire qu'elle n'existe QUE pour les contrats —
   --  le compilateur l'élimine du code de production. On peut donc écrire une
   --  spécification riche sans payer une ligne de code embarqué.
   function Element (B : Buffer; K : Count_Type) return Litres
   with Ghost, Pre => K < Length (B);

   --  @satisfies LLR-M07-001
   procedure Clear (B : out Buffer)
   with Post => Length (B) = 0;

   --  @satisfies LLR-M07-002
   procedure Push (B : in out Buffer; Value : Litres)
   with
     Pre  => not Is_Full (B),
     Post =>
       Length (B) = Length (B'Old) + 1
       and then Element (B, Length (B) - 1) = Value
       and then (for all K in 0 .. Length (B'Old) - 1 =>
                   Element (B, K) = Element (B'Old, K));

   --  @satisfies LLR-M07-003
   procedure Pop (B : in out Buffer; Value : out Litres)
   with
     Pre  => not Is_Empty (B),
     Post =>
       Length (B) = Length (B'Old) - 1
       and then Value = Element (B'Old, 0)
       and then (for all K in 0 .. Length (B) - 1 =>
                   Element (B, K) = Element (B'Old, K + 1));

private

   type Element_Array is array (Index_Type) of Litres;

   type Buffer is record
      Items : Element_Array := [others => 0];
      First : Index_Type := 0;
      Count : Count_Type := 0;
   end record;

   function Length (B : Buffer) return Count_Type
   is (B.Count);

   function Element (B : Buffer; K : Count_Type) return Litres
   is (B.Items ((B.First + K) mod Capacity));

end Mod07.Ring_Buffer;

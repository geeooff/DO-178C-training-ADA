--  ---------------------------------------------------------------------------
--  Décodage de trame capteur, sans une seule exception — module 06.
--
--  Ada A des exceptions, et de bonnes. On les interdit quand même en DAL A/B.
--  Le module explique pourquoi, et montre ce qu'on met à la place.
--
--  La règle de conception tient en une phrase : UN ÉCHEC EST UNE VALEUR DE
--  RETOUR, pas un saut. Le statut voyage avec la donnée, l'appelant ne peut
--  pas l'ignorer sans que ça se voie, et le chemin d'erreur est un chemin
--  ordinaire — donc mesurable par la couverture structurelle.
--  ---------------------------------------------------------------------------

package Mod06.Sensor_Io
  with SPARK_Mode => On
is

   subtype Litres is Natural range 0 .. 10_000;

   subtype Raw_Value is Natural range 0 .. 65_535;

   subtype Age_Ms is Natural range 0 .. 10_000;

   subtype Checksum_Value is Natural range 0 .. 255;

   Max_Age : constant Age_Ms := 200;

   --  L'ORDRE DES LITTÉRAUX EST SIGNIFICATIF : il définit la gravité
   --  croissante. C'est ce qui permet à `Worst` de se réduire à 'Max, sans
   --  table de correspondance à maintenir en parallèle.
   type Status_Code is (Ok, Stale_Data, Out_Of_Range, Bad_Checksum);

   type Frame is record
      Raw      : Raw_Value := 0;
      Age      : Age_Ms := 0;
      Checksum : Checksum_Value := 0;
   end record;

   --  @satisfies LLR-M06-001
   function Expected_Checksum
     (Raw : Raw_Value; Age : Age_Ms) return Checksum_Value
   is ((Raw + Age) mod 256)
   with Global => null;

   --  Décode une trame. Aucun `raise` : le statut EST une partie du
   --  résultat, et la postcondition dit exactement quand il vaut Ok.
   --
   --  @satisfies LLR-M06-002
   procedure Decode
     (Input : Frame; Value : out Litres; Status : out Status_Code)
   with
     Global => null,
     Post   =>
       (Status = Ok)
       = (Input.Checksum = Expected_Checksum (Input.Raw, Input.Age)
          and then Input.Raw <= Litres'Last
          and then Input.Age <= Max_Age)
       and then (if Status = Ok then Value = Input.Raw else Value = 0);

   --  Combine deux statuts en gardant le plus grave. Une ligne, parce que
   --  l'ordre du type porte déjà l'information.
   --
   --  @satisfies LLR-M06-003
   function Worst (A, B : Status_Code) return Status_Code
   is (Status_Code'Max (A, B))
   with Global => null, Post => Worst'Result = A or else Worst'Result = B;

end Mod06.Sensor_Io;

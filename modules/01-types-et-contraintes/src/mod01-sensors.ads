--  ---------------------------------------------------------------------------
--  Les types du capteur de jauge — module 01.
--
--  Tout ce paquetage tient dans une idée : en Ada, une contrainte s'écrit
--  UNE fois, dans le type, et le compilateur, l'exécution et la preuve la
--  font respecter ensuite. En C#, la même contrainte s'écrit dans chaque
--  méthode qui touche la valeur, et un oubli ne se voit pas.
--  ---------------------------------------------------------------------------

package Mod01.Sensors
  with SPARK_Mode => On
is

   --  --- 1. Type modulaire : le débordement est DÉFINI
   --
   --  Le capteur capacitif délivre 12 bits. `mod 2**12` dit exactement cela :
   --  les valeurs vont de 0 à 4095 et l'arithmétique boucle. C'est le
   --  comportement de `unchecked` en C# et des entiers non signés en C++.
   --  Ce qui change, c'est que la largeur est dans le type et non dans un
   --  commentaire.
   type Raw_Count is mod 2**12;

   --  --- 2. Énumération : pas un entier déguisé
   --
   --  En C#, `(SensorId) 200` compile et produit une valeur invalide qui se
   --  propage. En Ada il n'existe aucune conversion implicite depuis un
   --  entier : il faut passer par 'Val, qui lève Constraint_Error hors
   --  domaine. Le contrôle n'est plus optionnel.
   type Sensor_Id is (Left_Tank, Right_Tank, Centre_Tank, Trim_Tank);

   --  --- 3. Sous-type : même type, contrainte en plus
   --
   --  Celsius EST un Integer. Il s'additionne, se compare et s'affecte avec
   --  des Integer sans conversion. Seule la plage change, et elle est
   --  vérifiée à chaque affectation.
   subtype Celsius is Integer range -60 .. 90;

   --  --- 4. Types distincts : deux grandeurs qu'on ne mélangera pas
   --
   --  `type ... is delta ...` crée un type NOUVEAU. Litres et Kilograms ont
   --  la même représentation et restent incompatibles : `Volume + Masse` ne
   --  compile pas. C'est ce contrôle-là qui manquait au Mars Climate Orbiter
   --  en 1999, où des livres-force-seconde ont été lues comme des
   --  newtons-seconde. La sonde a été perdue.
   --
   --  La virgule fixe, et non le flottant : le pas est exact, la
   --  représentation est un entier mis à l'échelle, et le résultat ne dépend
   --  pas de l'unité de calcul. La DO-178C n'interdit pas le flottant, mais
   --  §6.3.4.f demande de justifier la précision — ce qui est bien plus
   --  facile quand chaque valeur est un multiple exact de 0,25.
   type Litres is delta 0.25 range 0.0 .. 1_024.0;
   type Kilograms is delta 0.25 range 0.0 .. 1_024.0;

   --  Étalonnage : 4096 comptes pour 1024 litres.
   Litres_Per_Count : constant Litres := 0.25;

   --  Masse volumique du Jet A-1 à 15 °C, en kg par litre.
   --
   --  Pourquoi un TYPE et pas un simple nombre nommé `= 0.804` : SPARK
   --  refuse qu'un littéral réel apparaisse dans une multiplication en
   --  virgule fixe, parce que le type du résultat dépendrait alors d'une
   --  règle de conversion implicite. Donner un type à la constante rend
   --  l'échelle explicite — et c'est vérifiable.
   --
   --  `Small => 0.001` fixe le pas de représentation à un millième exact.
   --  Sans cette clause, GNAT prendrait la puissance de deux immédiatement
   --  inférieure (2**-10), et 0,804 deviendrait 0,8037109375. Sur une masse
   --  de carburant, l'écart n'est pas anecdotique.
   type Density_Kg_Per_L is delta 0.001 range 0.0 .. 2.0 with Small => 0.001;

   Density_Jet_A1 : constant Density_Kg_Per_L := 0.804;

   --  --- Opérations

   --  @satisfies LLR-M01-001
   function Next_Count (Raw : Raw_Count) return Raw_Count
   is (Raw + 1);

   --  @satisfies LLR-M01-002
   function To_Litres (Raw : Raw_Count) return Litres;

   --  @satisfies LLR-M01-003
   function To_Kilograms (Volume : Litres) return Kilograms;

   --  Décode l'identifiant reçu sur le bus. Une trame corrompue peut
   --  contenir n'importe quoi : le décodage doit le DIRE, pas planter.
   --
   --  @satisfies LLR-M01-004
   procedure Decode_Sensor_Id
     (Octet : Natural; Id : out Sensor_Id; Valid : out Boolean)
   with
     Post =>
       Valid = (Octet <= Sensor_Id'Pos (Sensor_Id'Last))
       and then (if Valid then Sensor_Id'Pos (Id) = Octet);

   --  Ramène une température brute dans le domaine, et signale qu'elle l'a
   --  été. Écraser silencieusement une valeur hors domaine masquerait une
   --  panne capteur : le drapeau est la moitié utile du résultat.
   --
   --  @satisfies LLR-M01-005
   procedure Clamp_Temperature
     (Raw : Integer; Value : out Celsius; Clamped : out Boolean)
   with
     Post =>
       Clamped = (Raw < Celsius'First or else Raw > Celsius'Last)
       and then (if Raw < Celsius'First then Value = Celsius'First)
       and then (if Raw > Celsius'Last then Value = Celsius'Last)
       and then (if not Clamped then Value = Raw);

end Mod01.Sensors;

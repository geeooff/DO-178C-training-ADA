--  ---------------------------------------------------------------------------
--  Instruments de jaugeage — module 08.
--
--  Deux technologies de capteur, une seule interface. C'est le cas d'usage
--  légitime du polymorphisme en avionique : le calculateur ne veut pas savoir
--  si la jauge est capacitive ou à ultrasons, il veut des litres.
--
--  Ce que la DO-332 exige en échange tient en une phrase : la substitution
--  doit être VÉRIFIÉE, pas espérée. Ada 2022 le permet directement avec
--  Pre'Class et Post'Class, dont gnatprove fait des obligations de preuve.
--  Le principe de substitution de Liskov cesse d'être un conseil de
--  conception pour devenir une propriété démontrée.
--  ---------------------------------------------------------------------------

package Mod08.Instruments
  with SPARK_Mode => On
is

   --  SPARK exige que le point de gel des types dérivés tombe dans la
   --  « région d'appel précoce » de leurs primitives, faute de quoi il ne
   --  peut pas garantir l'ordre d'élaboration. pragma Elaborate_Body le
   --  résout en une ligne, et c'est ce que le message E0003 suggère.
   pragma Elaborate_Body;

   --  Le domaine du TYPE est plus large que l'échelle physique : c'est ce
   --  qui rend les contrats de plausibilité utiles au lieu d'être
   --  trivialement vrais.
   subtype Litres is Natural range 0 .. 12_000;

   Full_Scale : constant Litres := 10_000;

   subtype Raw_Count is Natural range 0 .. 1_000;

   subtype Gain_Range is Natural range 1 .. 10;

   subtype Dead_Zone_Range is Litres range 0 .. 1_000;

   --  --- La racine abstraite

   type Instrument is abstract tagged record
      Serial : Natural := 0;
   end record;

   --  Conversion comptes bruts vers litres.
   --
   --  Post'Class est un CONTRAT DE CLASSE : toute redéfinition doit le
   --  satisfaire. Une dérivée peut rendre la postcondition PLUS forte,
   --  jamais plus faible. C'est exactement la substitution de Liskov, et
   --  gnatprove la vérifie sur chaque redéfinition.
   --
   --  @satisfies LLR-M08-001
   function To_Litres (Self : Instrument; Raw : Raw_Count) return Litres
   is abstract
   with Post'Class => To_Litres'Result <= Full_Scale;

   --  Pre'Class fonctionne à l'envers : une dérivée peut AFFAIBLIR la
   --  précondition, jamais la renforcer. Un appelant qui respecte le contrat
   --  de la racine doit être accepté par toutes les dérivées.
   --
   --  @satisfies LLR-M08-002
   function Is_Plausible (Self : Instrument; Value : Litres) return Boolean
   is abstract
   with Pre'Class => Value <= Full_Scale;

   --  Appel DISPATCHANT : le type réel n'est connu qu'à l'exécution. C'est
   --  ce que la DO-332 §OO.6.4.4.2 demande de couvrir — chaque site d'appel
   --  doit être exercé pour chaque cible possible.
   --
   --  @satisfies LLR-M08-003
   function Reading (Self : Instrument'Class; Raw : Raw_Count) return Litres
   with Post => Reading'Result <= Full_Scale;

   --  --- Deux technologies

   --  Jauge capacitive : linéaire, avec un gain propre à la sonde.
   type Capacitive is new Instrument with record
      Gain : Gain_Range := 10;
   end record;

   --  @satisfies LLR-M08-004
   overriding
   function To_Litres (Self : Capacitive; Raw : Raw_Count) return Litres
   is (Raw * Self.Gain);

   --  @satisfies LLR-M08-004
   overriding
   function Is_Plausible (Self : Capacitive; Value : Litres) return Boolean
   is (Value <= Raw_Count'Last * Self.Gain);

   --  Jauge à ultrasons : zone morte en fond de réservoir, donc un décalage.
   type Ultrasonic is new Instrument with record
      Dead_Zone : Dead_Zone_Range := 0;
   end record;

   --  La postcondition est ici PLUS FORTE que celle de la racine : le
   --  résultat est aussi minoré par la zone morte. Renforcer est permis ;
   --  c'est le sens même de la substitution.
   --
   --  @satisfies LLR-M08-005
   overriding
   function To_Litres (Self : Ultrasonic; Raw : Raw_Count) return Litres
   is (Self.Dead_Zone + Raw * 9)
   with
     Post =>
       To_Litres'Result <= Full_Scale
       and then To_Litres'Result >= Self.Dead_Zone;

   --  Une seule condition, et c'est une correction issue de la MESURE.
   --
   --  La version initiale écrivait `Value >= Self.Dead_Zone and then
   --  Value <= Full_Scale`. La couverture MC/DC est restée à 1 sur 2 : la
   --  seconde condition ne peut jamais valoir False, puisque la Pre'Class
   --  héritée exige déjà `Value <= Full_Scale`. C'était du code
   --  inatteignable — exactement ce que l'analyse de couverture
   --  structurelle doit révéler (§6.4.4.3) — et la bonne réponse est de le
   --  retirer, pas d'inventer un cas de test impossible.
   --
   --  @satisfies LLR-M08-005
   overriding
   function Is_Plausible (Self : Ultrasonic; Value : Litres) return Boolean
   is (Value >= Self.Dead_Zone);

end Mod08.Instruments;

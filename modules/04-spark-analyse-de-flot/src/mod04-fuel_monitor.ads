--  ---------------------------------------------------------------------------
--  Surveillance du niveau carburant — module 04.
--
--  Ce paquetage a de l'ÉTAT. C'est justement pour cela qu'il est ici : l'état
--  caché est ce qui rend le couplage de données difficile à établir, et
--  l'objectif A-7.8 de la DO-178C demande précisément d'établir le couplage
--  de données et de contrôle.
--
--  Le dépôt frère en C++ y consacre un module entier et un tableau tenu à la
--  main. Ici, Abstract_State, Global et Depends disent la même chose dans le
--  code, et gnatprove vérifie que le corps ne s'en écarte pas. Le tableau
--  cesse d'être une donnée de vie qu'on entretient : il devient une sortie
--  d'outil.
--
--  La coquille est MINCE À DESSEIN : toute la décision est dans
--  Mod04.Alarm_Logic, qui n'a pas d'état. Voir le README du module, §1.7,
--  pour la raison d'outillage qui rend cette séparation nécessaire ici, et
--  pas seulement souhaitable.
--  ---------------------------------------------------------------------------
with Mod04.Alarm_Logic;

package Mod04.Fuel_Monitor
  with SPARK_Mode => On, Abstract_State => State, Initializes => State
is

   subtype Litres is Mod04.Alarm_Logic.Litres;

   --  Prend en compte une nouvelle mesure.
   --
   --  Global dit QUOI est touché, Depends dit QUOI DÉPEND DE QUOI. Les deux
   --  sont vérifiés contre le corps : si quelqu'un ajoute demain une lecture
   --  d'une autre variable globale, la preuve échoue.
   --
   --  Note d'écriture : SPARK admet le raccourci `State =>+ Reading` pour
   --  « dépend aussi de lui-même ». Il est écrit ici en toutes lettres, parce
   --  que `gnatformat` réécrit `=>+` en `=> +`, forme que le vérificateur de
   --  style `-gnatyt` refuse ensuite. Deux outils de la chaîne se
   --  contredisent sur ce point ; la forme longue les met d'accord, et se lit
   --  mieux.
   --
   --  @satisfies LLR-M04-001
   procedure Update (Reading : Litres)
   with Global => (In_Out => State), Depends => (State => (State, Reading));

   --  Remet la surveillance à zéro. `Output` et non `In_Out` : l'état
   --  précédent n'est pas lu, il est écrasé. La nuance n'est pas cosmétique —
   --  elle dit qu'aucune information ne traverse le Reset.
   --
   --  @satisfies LLR-M04-002
   procedure Reset
   with
     Global  => (Output => State),
     Depends => (State => null),
     Post    => Sample_Count = 0 and then not Alarm_Active;

   --  @satisfies LLR-M04-003
   function Last_Reading return Litres
   with Global => (Input => State);

   --  @satisfies LLR-M04-004
   function Alarm_Active return Boolean
   with Global => (Input => State);

   --  @satisfies LLR-M04-005
   function Sample_Count return Natural
   with Global => (Input => State);

end Mod04.Fuel_Monitor;

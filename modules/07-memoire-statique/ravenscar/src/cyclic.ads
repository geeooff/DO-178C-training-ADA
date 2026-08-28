--  ---------------------------------------------------------------------------
--  Un cycle périodique et son état partagé.
--
--  Tout est au niveau BIBLIOTHÈQUE : Ravenscar interdit les objets protégés
--  locaux et la hiérarchie de tâches. Ce n'est pas une contrainte gratuite —
--  une tâche créée dynamiquement au fond d'une procédure ne s'analyse pas.
--  ---------------------------------------------------------------------------

package Cyclic is

   --  Un objet protégé remplace le mutex et la variable partagée. L'exclusion
   --  mutuelle est dans le type, pas dans la discipline de l'appelant : c'est
   --  la même idée qu'au module 01, appliquée à la concurrence.
   protected Counter is
      procedure Bump;
      function Value return Natural;
   private
      Cycles : Natural := 0;
   end Counter;

end Cyclic;

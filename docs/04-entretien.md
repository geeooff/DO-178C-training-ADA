# Préparation à l'entretien

> Les questions qui reviennent, et des réponses **appuyées sur ce dépôt**.
> Une réponse qui cite un chiffre mesuré vaut dix réponses qui récitent la
> norme.

---

## 1. Les cinq chiffres à connaître par cœur

Ils viennent tous d'une exécution, pas d'une estimation.

| Chiffre | Ce qu'il dit | Où |
|---|---|---|
| **13 %** | surcoût en `.text` des vérifications à l'exécution (1005 contre 889 octets, GNAT 16.1, `-O0`) | [module 02](../modules/02-verifications-execution/) |
| **55 %** | MC/DC de la campagne initiale du vote médian, sur du code dont **28 obligations sur 28** étaient prouvées | [module 05](../modules/05-spark-preuve-do333/) |
| **33 %** | MC/DC atteint par deux cas de test qui donnent **100 % de couverture de décisions** | [module 10](../modules/10-couverture-et-preuve/) |
| **4 sur 10** | violations du standard de codage attrapées par le compilateur ; les six autres restent à la revue | [module 11](../modules/11-standards-qualification/) |
| **44 → 35** | instructions du FQMS après correction des écarts de couverture : le composant a **maigri** en gagnant en couverture | [module 12](../modules/12-projet-integre/) |

---

## 2. Sur la DO-178C

> **« Qu'est-ce que le DAL, et qui le choisit ? »**
> Le *Design Assurance Level* est alloué par l'analyse de sécurité **système**
> (ARP4761), à partir de l'effet de la panne : catastrophique en A, sans effet
> en E. L'équipe logicielle ne le choisit pas, elle le subit. Ce qu'il change,
> c'est le nombre d'objectifs à satisfaire, l'indépendance exigée, et le
> niveau de couverture structurelle.

> **« À quoi sert la couverture structurelle ? »**
> Pas à valider le code : à trouver ce que les exigences ne justifient pas. Le
> §6.4.4.3 le dit ainsi. Sur mon dépôt, elle a trouvé une garde rendue
> inatteignable par une précondition de classe, sur du code par ailleurs
> entièrement prouvé.

> **« Dead code ou deactivated code ? »**
> Le code désactivé est prévu et tracé à une exigence, simplement inactif dans
> cette configuration : il reste et se justifie. Le code mort n'est justifié
> par rien : il part.

> **« Qu'est-ce qu'une exigence dérivée ? »**
> Une exigence qui ne remonte à aucune exigence de niveau supérieur : elle naît
> d'une décision de conception. Le §5.1.2.h impose de l'identifier et de la
> **remonter au processus de sécurité système**, parce que personne d'autre
> n'a pu en évaluer l'effet. C'est le point où le logiciel introduit un
> comportement que le système n'avait pas demandé.

> **« Comment établissez-vous le couplage de données et de contrôle ? »**
> En Ada/SPARK, il est déclaré dans le code par `Global` et `Depends`, et
> `gnatprove` vérifie que le corps s'y conforme. L'artefact A-7.8 devient une
> sortie d'outil au lieu d'un tableau ré-audité à chaque modification. C'est
> probablement l'écart le plus net avec un projet C ou C++ équivalent.

> **« Cet outil, il faut le qualifier ? »**
> La question n'est jamais « l'outil est-il bon » mais « son résultat
> élimine-t-il, réduit-il ou automatise-t-il une activité que la norme
> exige ». Si oui, on regarde le critère DO-330 puis on croise avec le DAL
> pour obtenir le TQL. Exemple concret : GNATcoverage, si son rapport remplace
> une revue, est critère 2 — et AdaCore vend un **kit de qualification DO-330
> réel** pour cet outil. `clang-tidy` n'est qualifié pour rien.

---

## 3. Sur Ada et SPARK

> **« Pourquoi Ada plutôt que C ? »**
> Trois choses que le langage donne et qu'il faudrait sinon construire : les
> domaines dans les types, les contrats exécutables **et** prouvables, et
> l'interdiction vérifiée de ce qu'on ne veut pas — exceptions, allocation,
> délais relatifs. Ce ne sont pas des conventions de codage, ce sont des
> erreurs de compilation.

> **« SPARK, c'est un autre langage ? »**
> Non, un sous-ensemble d'Ada plus des aspects. Le code SPARK se compile avec
> un compilateur Ada ordinaire. On peut l'adopter unité par unité, ce qui
> compte sur un existant.

> **« La preuve remplace-t-elle les tests ? »**
> Elle remplace certains **objectifs**, selon la DO-333, pas les tests sur
> l'exécutable intégré. Et j'ai le contre-exemple : un vote médian dont les 28
> obligations étaient déchargées, donc correct pour toutes les entrées, et
> dont la campagne initiale ne couvrait que 55 % du MC/DC. La preuve porte sur
> le source ; la couverture, sur ce que les tests ont exercé du binaire.

> **« Les vérifications Ada, on les garde ou on les enlève ? »**
> On les enlève quand on a prouvé qu'elles ne peuvent pas se déclencher, et
> pas avant : les supprimer sans preuve rend l'exécution *erroneous* au sens
> de la norme, on retombe sur le comportement indéfini du C. Sur mon dépôt,
> elles coûtent 13 % de `.text` — un chiffre que j'ai mesuré, pas estimé.

> **« Un invariant et un variant de boucle, quelle différence ? »**
> L'invariant dit ce qui reste vrai à chaque tour et sert à prouver la
> postcondition ; le variant dit ce qui décroît strictement et sert à prouver
> la **terminaison**. Sur un `while`, aucun invariant n'implique la
> terminaison.

> **« Ravenscar ? »**
> Un profil de restrictions qui réduit le modèle de tâches à ce que les
> théorèmes d'ordonnançabilité savent traiter : tâches périodiques de priorité
> fixe au niveau bibliothèque, objets protégés à plafond de priorité, délais
> absolus. Ce n'est pas une bibliothèque, c'est un `pragma` vérifié par le
> compilateur.

> **« L'objet est-il autorisé ? »**
> Oui, encadré par la DO-332 : cohérence locale de type — Liskov — couverture
> de chaque site d'appel dispatchant pour chaque cible, et pas d'allocation
> dynamique. En Ada 2022, la première se **démontre** avec `Pre'Class` et
> `Post'Class` au lieu de se re-tester extension par extension. Et la
> troisième exigence est ce qui limite la profondeur d'héritage en pratique :
> chaque extension multiplie les obligations de couverture.

---

## 4. Les questions de sincérité

Celles qui cherchent à savoir si le candidat sait où s'arrête son expérience.

> **« Qu'est-ce que vous n'avez pas fait ? »**
> Pas de tests sur cible réelle, pas de couverture du code objet, pas
> d'analyse WCET réelle, pas de multicœur, pas de DO-331, pas de rédaction
> complète des plans, aucune relation avec une autorité. Ce sont les limites
> d'un dépôt d'apprentissage sans matériel, et elles sont écrites dans le plan
> de formation.

> **« Vous avez déjà vu deux outils de vérification se gêner ? »**
> Oui, sur ce dépôt : l'instrumentation de GNATcoverage ajoute de l'état caché
> qui invalide le `Refined_State` de SPARK. Un paquetage à `Abstract_State`
> n'est donc pas mesurable par instrumentation de source. La réponse a été de
> garder la coquille d'état mince et sans décision, de mesurer la logique, et
> d'écrire la justification d'exclusion dans le script plutôt que de la
> laisser implicite. Cela a même **façonné l'architecture** du composant
> DAL B, et le SDD le dit.

> **« Racontez-moi un défaut que vous avez trouvé. »**
> Sur le FQMS, la couverture a trouvé trois choses dans un composant qui
> compilait sans avertissement, passait ses tests et était entièrement prouvé :
> une garde inatteignable, une saturation non testable, et un cas de test
> manquant. J'ai retiré la garde, redimensionné le compteur de maintenance en
> 16 bits — ce qui est d'ailleurs ce qu'on trouve en équipement réel — et
> ajouté le cas symétrique. Le composant est passé de 44 à 35 instructions en
> gagnant 24 points de couverture de décisions.

> **« Que faites-vous d'une vérification que le prouveur ne décharge pas ? »**
> Je la justifie explicitement, avec `pragma Annotate` et une raison écrite.
> Elle apparaît alors dans la colonne « Justified » du rapport, et elle se
> relit en revue. Ce qu'il ne faut pas faire, c'est baisser le seuil de
> vérification pour la faire disparaître.

---

## 5. Les accidents, et ce qu'il faut en dire

Les citer est facile ; en tirer la bonne leçon distingue.

> **Ariane 5, Vol 501 (1996).** Une conversion flottant 64 bits vers entier 16
> bits déborde parce que la trajectoire d'Ariane 5 sortait du domaine
> d'Ariane 4 ; la protection avait été retirée pour tenir le budget CPU, sur
> la foi d'une analyse valable pour l'ancien lanceur.
> **La leçon n'est pas « ne pas réutiliser »** : c'est que l'hypothèse
> justifiant la suppression n'était écrite nulle part dans le code, donc
> personne ne l'a rejouée. En SPARK, ce serait une précondition, et sa
> révision serait mécanique.

> **Mars Climate Orbiter (1999).** Livres-force-seconde lues comme des
> newtons-seconde, facteur 4,45, sonde perdue.
> **Les deux logiciels étaient corrects** : c'est l'interface qui ne l'était
> pas, et aucun compilateur n'avait de quoi s'en apercevoir parce que les deux
> grandeurs étaient des `double`. Deux types dérivés distincts rendent
> l'affectation impossible à écrire.

> **Air Canada 143 (1983).** Conversion livres/kilogrammes fausse au plein,
> jaugeage inopérant, Boeing 767 posé en vol plané à Gimli.
> C'est la justification du **DAL B** du FQMS de ce dépôt : une indication de
> quantité erronée par excès est une condition de panne dangereuse.

---

## 6. Ce qu'il ne faut pas dire

- « J'ai 100 % de couverture. » — 100 % de **quoi** ? Sans le niveau, la
  phrase ne veut rien dire, et l'interlocuteur le sait.
- « SPARK prouve que le programme est correct. » — SPARK prouve ce qu'on lui a
  demandé de prouver. Une postcondition fausse se prouve très bien.
- « Ada est sûr. » — Ada déplace la charge de la preuve. Ce qui est sûr, c'est
  un processus, pas un langage.
- « On n'a pas besoin de tests puisque c'est prouvé. » — voir §3.
- Réciter des numéros d'objectifs sans savoir ce qu'ils demandent. Mieux vaut
  dire « je sais que c'est dans le tableau A-7, je vérifierais le numéro ».

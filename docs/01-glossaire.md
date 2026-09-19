# Glossaire

> Les sigles de la certification et les termes Ada/SPARK qui n'ont pas
> d'équivalent en C#. Rangés par thème plutôt qu'alphabétiquement : on cherche
> rarement un sigle isolé.

---

## 1. Normes et documents

| Terme | Ce que c'est |
|---|---|
| **DO-178C** / ED-12C | *Software Considerations in Airborne Systems and Equipment Certification*. La norme. Décrit des **objectifs**, pas une méthode. |
| **DO-330** | Supplément *Tool Qualification*. Quand et comment qualifier un outil. |
| **DO-331** | Supplément *Model-Based Development* — SCADE, Simulink. |
| **DO-332** | Supplément *Object-Oriented Technology*. Voir [module 08](../modules/08-objet-do332/). |
| **DO-333** | Supplément *Formal Methods*. Voir [module 05](../modules/05-spark-preuve-do333/). |
| **ARP4754B / ARP4761A** | Processus et analyse de sécurité au niveau **système**, en amont de la DO-178C (révisions de 2023 ; les éditions A et initiale restent couramment citées). C'est de là que vient le DAL. |
| **CAST** | *Certification Authorities Software Team*. Publie des *position papers* qui font jurisprudence. CAST-6 (MC/DC masqué), CAST-10 (ce qu'est une décision), CAST-32A (multicœur, repris depuis par l'AC 20-193 et l'AMC 20-193). |

## 2. Données de vie du logiciel

| Sigle | Nom | §  |
|---|---|---|
| **PSAC** | *Plan for Software Aspects of Certification* | 11.1 |
| **SDP / SVP / SCMP / SQAP** | plans de développement, vérification, configuration, qualité | 11.2 à 11.5 |
| **SRD** | *Software Requirements Data* — les HLR | 11.9 |
| **SDD** | *Design Description* — architecture et LLR | 11.10 |
| **SCI** | *Software Configuration Index* — ce qui **constitue** le logiciel | 11.16 |
| **SECI** | *Software Life Cycle Environment Configuration Index* — ce qui l'a **produit** | 11.15 |
| **SAS** | *Software Accomplishment Summary* — le bilan remis à l'autorité | 11.20 |

Voir [module 11](../modules/11-standards-qualification/) et
`tools/config_index.py`, qui génère le SCI et le SECI de ce dépôt.

## 3. Niveaux et catégories

| Terme | Ce que c'est |
|---|---|
| **DAL** (A à E) | *Design Assurance Level*. Alloué par l'analyse de sécurité **système**, jamais choisi par l'équipe logicielle. A = catastrophique, E = sans effet. |
| **CC1 / CC2** | *Control Category*. CC1 exige revue formelle, approbation et archivage garanti ; CC2 est allégé. Le SCI et le SECI sont CC1 **à tous les DAL**. |
| **TQL** (1 à 5) | *Tool Qualification Level*, DO-330. Croisement du **critère** de l'outil et du DAL. |

## 4. Exigences

| Terme | Ce que c'est |
|---|---|
| **HLR** | *High-Level Requirement*. **Ce que** le logiciel doit faire. |
| **LLR** | *Low-Level Requirement*. **Comment**. Assez précise pour coder sans autre décision. |
| **Exigence dérivée** | Exigence sans parent : elle naît d'une décision de conception. §5.1.2.h impose de la **remonter au processus de sécurité système**. |
| **Traçabilité bidirectionnelle** | Descendante : tout ce qui était demandé est fait. Remontante : rien de plus que ce qui était demandé. |

## 5. Vérification

| Terme | Ce que c'est |
|---|---|
| **Cas nominal / de robustesse** | §6.4.2.1 et §6.4.2.2. Le second teste les entrées qui ne devraient pas arriver — et trouve les vrais défauts. |
| **Couverture d'instructions** | Chaque ligne exécutée au moins une fois. DAL C. |
| **Couverture de décisions** | Chaque test booléen a pris ses deux valeurs. DAL B. |
| **MC/DC** | *Modified Condition/Decision Coverage*. Chaque **condition** a démontré qu'elle pouvait, seule, faire basculer sa décision. DAL A. |
| **MC/DC masqué** | Variante admise en certification (CAST-6) où une condition qui ne peut pas influencer le résultat — par exemple non évaluée après un court-circuit — est considérée masquée, pas non couverte. C'est ce qui rend MC/DC praticable sur `and then` / `or else`. |
| **Code objet sans équivalent source** | Code généré par le compilateur qui ne correspond à aucune instruction écrite. Déclenche A-7.9 au DAL A. Voir [module 02](../modules/02-verifications-execution/). |
| **Code mort** (*dead*) | Rien ne le justifie. Il part. |
| **Code désactivé** (*deactivated*) | Prévu, tracé à une exigence, inactif dans cette configuration. Il reste et se justifie. |
| **Couplage de données / de contrôle** | A-7.8. Quelles données circulent entre composants, qui appelle qui. En SPARK : `Global` et `Depends`. |
| **Indépendance** | Le vérificateur n'est pas l'auteur. Exigée sur une vingtaine des 69 objectifs du DAL B et une trentaine des 71 du DAL A — le décompte exact varie d'une source à l'autre, ne pas l'affirmer à l'unité. |

## 6. Ada

| Terme | Ce que c'est |
|---|---|
| **Sous-type** | Même type, domaine restreint. `subtype Celsius is Integer range -60 .. 90;` Compatible avec le type de base. |
| **Type dérivé** | Type **nouveau**, incompatible. `type Litres is delta 0.25 range 0.0 .. 1_024.0;` |
| **Type modulaire** | `type Raw is mod 2**12;` Débordement **défini**, il boucle. |
| **Virgule fixe** | Un entier mis à l'échelle. Ni exposant, ni `NaN`, ni mode d'arrondi. |
| **`Small`** | Le pas réel de représentation d'un type à virgule fixe. À déclarer explicitement. |
| **Aspect** | `with Pre => …`, `with Post => …`. Attaché à une déclaration. |
| **`'Old`** | La valeur d'un objet **à l'entrée** du sous-programme. Son préfixe doit nommer une entité. |
| **`Contract_Cases`** | Table de décision exécutable : gardes exhaustives et disjointes, vérifiées par l'outil. |
| **`Type_Invariant`** | Propriété vraie de tout objet d'un type privé, aux frontières du paquetage. |
| **`Ghost`** | Entité qui n'existe **que** pour les contrats. Éliminée du code de production. |
| **Paquetage / enfant** | `Mod12.Fqms` est un enfant de `Mod12`. Le pendant Ada d'un espace de noms, mais c'est une unité de compilation. |
| **Type étiqueté** | `type T is tagged record …` — le support de l'héritage et du dispatching. |
| **`T'Class`** | « T ou n'importe laquelle de ses extensions ». C'est ce type qui rend un appel dispatchant. |
| **Objet protégé** | Type qui porte son exclusion mutuelle. Remplace mutex et variable partagée. |
| **Ravenscar** | Profil de restrictions qui réduit le modèle de tâches à ce qu'une analyse d'ordonnançabilité sait traiter. |
| **`pragma Restrictions`** | Contrainte vérifiée par le compilateur **et** l'éditeur de liens. Transforme une règle de codage en propriété. |

## 7. SPARK

| Terme | Ce que c'est |
|---|---|
| **SPARK** | Sous-ensemble d'Ada plus des aspects, conçu pour être prouvable. Pas un autre langage. |
| **`SPARK_Mode`** | Aspect qui met une unité dans le périmètre de preuve — ou l'en sort, **explicitement**. |
| **Analyse de flot** | Sans prouveur : lectures non initialisées, affectations mortes, dépendances non déclarées, aliasing. |
| **AoRTE** | *Absence of Run-Time Errors*. Le palier de preuve qui se vend : aucun `Constraint_Error` possible. |
| **Obligation de vérification** | Formule logique dont la validité implique la correction. Produite par `gnatprove`, déchargée par un prouveur SMT. |
| **`Global` / `Depends`** | Ce qui est touché, et ce qui dépend de quoi. Vérifiés contre le corps. |
| **`Abstract_State` / `Refined_State`** | L'état d'un paquetage, nommé dans la spécification et raffiné dans le corps. |
| **`Loop_Invariant`** | Ce qui reste vrai à chaque tour. Sans lui, le prouveur ne sait rien d'un tour à l'autre. |
| **`Loop_Variant`** | Ce qui décroît strictement. Démontre la **terminaison**, qu'aucun invariant n'implique. |
| **`pragma Annotate`** | Justifie une vérification non déchargée. `False_Positive` ou `Intentional`, **avec une raison écrite**. |

## 8. Accidents cités

| Accident | Année | Ce qu'il enseigne | Module |
|---|---|---|---|
| **Ariane 5 Vol 501** | 1996 | une protection retirée sur la foi d'une analyse valable pour l'ancien lanceur | [06](../modules/06-erreurs-sans-exceptions/) |
| **Mars Climate Orbiter** | 1999 | deux logiciels corrects, une interface d'unités fausse | [01](../modules/01-types-et-contraintes/) |
| **Air Canada 143** (Gimli) | 1983 | une quantité carburant fausse et un jaugeage inopérant | [12](../modules/12-projet-integre/) |

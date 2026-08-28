# SDD — Software Design Description

## FQMS — Fuel Quantity Management System, réalisation Ada / SPARK

> **Document** : *Design Description*, DO-178C §11.10
> **Catégorie de contrôle** : CC1
> **Niveau** : **DAL B**
> **Version** : 1.0
> **Part number** : PN-4210001-001

---

> **Contrairement au SRD, ce document DIFFÈRE de son homologue C++.** Les
> exigences de haut niveau ne dépendent pas du langage ; la conception, si.
> Comparer les deux SDD est l'exercice le plus instructif des deux dépôts.

---

## 1. Architecture

```
   Raw_Inputs (3 × Integer, non contraint)
              │
              ▼
      ┌───────────────┐   par réservoir
      │    Acquire    │───► masse + validité, compteur de rejets
      └───────┬───────┘
              ▼
      ┌───────────────┐
      │ totalisation  │───► Total, Status
      └───────┬───────┘
              ▼
      ┌───────────────┐   deux instances
      │    Confirm    │───► Imbalance, Low_Level
      └───────────────┘
              │
              ▼
        Cycle_Outputs
```

### DA-01 — L'état est un paramètre, pas un `Abstract_State`

**C'est la décision structurante de ce composant**, et elle est prise pour une
raison mesurée, pas par goût.

Le module 04 §1.7 a établi que `gnatcov instrument` **ne sait pas** instrumenter
un paquetage porteur d'un `Abstract_State` : les variables témoins qu'il insère
deviennent de l'état caché absent du `Refined_State`, et GNAT rejette alors le
raffinement. Un composant DAL B doit être mesuré en couverture ; un état de
paquetage l'en empêcherait.

L'état est donc un type privé `State`, passé en `in out` à `Run_Cycle`. Trois
bénéfices, tous vérifiables :

- il est **mesurable** en couverture structurelle ;
- il est **testable en séquence** : chaque cas de test part d'un `Initial`
  connu, ce qui rend la campagne indépendante de l'ordre ;
- il est **réentrant**, ce qui compte dans une partition ARINC 653.

Le coût est un paramètre de plus dans chaque signature. Il est assumé, et la
raison est écrite dans le code.

> À comparer avec le dépôt frère, où la même contrainte n'existe pas : `gcov`
> instrumente le code objet et se moque de la structure du paquetage. C'est
> un cas où **l'outillage a façonné l'architecture** — ce qui arrive plus
> souvent qu'on ne l'admet, et qu'un SDD doit dire.

### DA-02 — `Acquire` est séparée du cycle

Une jauge s'acquiert seule, se prouve seule, et se teste seule. La séparation
évite aussi au corps de `Run_Cycle` une boucle dont l'invariant coûterait plus
cher à écrire que les trois appels qu'elle remplace.

### DA-03 — La totalisation est écrite sans boucle

Trois réservoirs, trois termes, une borne évidente. Sur une architecture figée,
c'est plus simple **et** plus facile à prouver qu'une boucle avec invariant.

### DA-04 — Une seule machine à confirmation

Les deux alertes suivent le même motif : *n* cycles consécutifs pour lever,
*n* pour effacer, avec deux seuils différents. La procédure `Confirm` est donc
écrite une fois et instanciée deux fois par appel. Un défaut corrigé l'est pour
les deux alertes.

### DA-05 — Aucune exception, aucune allocation, aucun dispatching

Conformément aux modules 06, 07 et 08, et à HLR-FQMS-041 : le temps de cycle
est borné et indépendant des données.

---

## 2. Exigences de bas niveau

### LLR-FQMS-010

- **Type** : LLR
- **Parent** : HLR-FQMS-001
- **Énoncé** : `To_Mass (Raw, Tank)` doit rendre `Raw * Capacity (Tank) /
  4095`. Le résultat doit être inférieur ou égal à `Capacity (Tank)`.
- **Vérification** : `Fqms.hlr_converts_gauge_linearly`, et **preuve** de la
  postcondition `To_Mass'Result <= Capacity (Tank)`.

### LLR-FQMS-020

- **Type** : LLR
- **Parent** : HLR-FQMS-002, HLR-FQMS-040
- **Énoncé** : `Acquire` doit, lorsque la mesure brute n'appartient pas à
  `Raw_Count`, affecter `0` à la masse, `False` à la validité, et incrémenter
  le compteur de rejets du réservoir concerné. L'incrément doit saturer à
  `Natural'Last`.
- **Vérification** : `Fqms.hlr_rejects_out_of_domain`,
  `Fqms.reject_counter_is_per_tank`

### LLR-FQMS-030

- **Type** : LLR
- **Parent** : HLR-FQMS-010
- **Énoncé** : Le total doit être la somme des masses des seuls réservoirs
  valides ; les réservoirs invalides doivent contribuer pour zéro.
- **Vérification** : `Fqms.hlr_totalises_valid_gauges`

### LLR-FQMS-040

- **Type** : LLR
- **Parent** : HLR-FQMS-011, HLR-FQMS-040
- **Énoncé** : Le statut doit valoir `Valid` si les trois jauges sont valides,
  `Unavailable` si aucune ne l'est, `Degraded` sinon. Les compteurs de rejets
  doivent être tenus **par réservoir**, indépendamment les uns des autres.
- **Vérification** : `Fqms.hlr_status_valid`, `Fqms.hlr_status_degraded`,
  `Fqms.hlr_status_unavailable`, `Fqms.reject_counter_is_per_tank`

### LLR-FQMS-050

- **Type** : LLR
- **Parent** : HLR-FQMS-020
- **Énoncé** : L'écart de déséquilibre doit être la **valeur absolue** de la
  différence entre les masses des deux réservoirs d'aile.
- **Justification** : sans valeur absolue, un déséquilibre en faveur de l'aile
  droite ne serait jamais détecté.
- **Vérification** : `Fqms.imbalance_gap_is_absolute`

### LLR-FQMS-060

- **Type** : LLR
- **Parent** : HLR-FQMS-020, HLR-FQMS-021, HLR-FQMS-030, HLR-FQMS-031
- **Énoncé** : `Confirm` doit incrémenter son compteur à chaque cycle où la
  condition de transition est vraie, et le **remettre à zéro** dès qu'elle est
  fausse. La transition doit avoir lieu quand le compteur atteint 5, et le
  compteur doit alors repartir de zéro.
- **Justification** : la remise à zéro est ce qui donne son sens à
  « 5 cycles **consécutifs** ». Sans elle, cinq cycles épars suffiraient.
- **Vérification** : `Fqms.confirmation_resets_on_break`

### LLR-FQMS-070

- **Type** : LLR
- **Parent** : HLR-FQMS-022, HLR-FQMS-032
- **Énoncé** : Lorsque la condition d'évaluation d'une alerte n'est pas
  réunie — jauge d'aile en panne pour le déséquilibre, jauge quelconque en
  panne pour le bas niveau — l'état de l'alerte doit être **conservé** et son
  compteur de confirmation **remis à zéro**.
- **Justification** : conserver l'alerte est ce que le SRD demande. Remettre
  le compteur à zéro est une décision de conception : la séquence de cycles
  consécutifs est rompue, et la reprendre où elle s'était arrêtée produirait
  une confirmation sur des cycles non consécutifs.
- **Vérification** : `Fqms.hlr_imbalance_frozen_on_gauge_fault`,
  `Fqms.hlr_low_level_frozen_on_gauge_fault`

### LLR-FQMS-100

- **Type** : LLR
- **Parent** : HLR-FQMS-042
- **Énoncé** : `Initial` doit rendre un état dont les deux alertes sont
  inactives, les deux compteurs de confirmation nuls, et les trois compteurs
  de rejets nuls.
- **Vérification** : `Fqms.hlr_no_alert_at_power_up`,
  `Fqms.power_up_state_is_defined`

---

## 3. Constantes de conception

| Nom | Valeur | Origine |
|---|---|---|
| `Capacity (Left_Wing)` | 5 000 kg | schéma réservoirs, rév. C |
| `Capacity (Centre)` | 8 000 kg | idem |
| `Capacity (Right_Wing)` | 5 000 kg | idem |
| `Raw_Count'Last` | 4 095 points | jauge capacitive 12 bits |
| `Imbalance_Set` | 500 kg | manuel de vol §3.4 |
| `Imbalance_Clear` | 400 kg | hystérésis, manuel de vol §3.4 |
| `Low_Level_Set` | 1 500 kg | manuel de vol §3.7 |
| `Low_Level_Clear` | 1 700 kg | hystérésis, manuel de vol §3.7 |
| `Confirm_Cycles` | 5 | manuel de vol §3.4 |

Ces valeurs sont **des exigences de bas niveau à part entière**. Les changer
sans rejouer la vérification est un défaut de gestion de configuration.

---

## 4. État de la vérification

| Activité | Résultat |
|---|---|
| Compilation, avertissements en erreurs | 0 avertissement |
| Preuve SPARK (`--level=2`) | **41 obligations déchargées** |
| Campagne de test | **18 cas, 33 vérifications, 0 échec** |
| Couverture structurelle | mesurée par `scripts/coverage.sh` |
| Traçabilité | vérifiée par `tools/trace_check.py --strict` |

---

## 5. Exigence de bas niveau architecturale

### LLR-FQMS-110

- **Type** : LLR
- **Parent** : HLR-FQMS-041
- **Énoncé** : `Run_Cycle` ne doit contenir aucune boucle dont le nombre
  d'itérations dépend des données, aucune allocation dynamique, aucun appel
  dispatchant, et aucune récursion. La seule boucle du corps parcourt
  `Tank_Id`, dont le domaine est statique.
- **Justification** : c'est le raffinement de l'exigence dérivée
  HLR-FQMS-041. Un temps de cycle borné et indépendant des entrées ne se teste
  pas — il se **conçoit**, puis s'établit par analyse.
- **Vérification** : analyse — revue du code, et `scripts/stack-usage.sh` qui
  confirme l'absence de trame de pile non statique dans les unités `mod12`.

# SDD — Software Design Description

## Composant : FQMS-CAL — Étalonnage et consolidation de sondes carburant

> **Document** : SDD (*Design Description*, DO-178C §11.10)
> **Composant** : FQMS-CAL
> **Niveau** : DAL B
> **Version** : 1.0
> **Statut de configuration** : CC1

Ce document contient l'**architecture logicielle** et les **exigences de bas
niveau** (LLR). Les LLR décrivent **COMMENT** le logiciel satisfait les HLR :
assez précisément pour que le code s'écrive directement à partir d'elles, sans
autre décision de conception.

---

## 1. Architecture

```
   compte brut gauche ──►┌────────────┐
                         │  Convert   │──► litres + statut
   compte brut droite ──►└────────────┘
                                │
                                ▼
                      ┌──────────────────┐
                      │   Consolidate    │──► litres + mode
                      └──────────────────┘
                                │
                                ▼
                     indication équipage
```

**DA-01 — le composant est sans état.** Aucune variable persistante : pas de
couplage de données par variable partagée, réentrance triviale, tests
indépendants de l'ordre d'exécution. Conséquence vérifiable :
`Global => null` implicite sur les deux sous-programmes, et l'analyse de flot
de SPARK le confirme.

**DA-02 — la validation du domaine est faite dans `Convert`, une seule fois.**
Une seule implémentation du domaine, donc un seul point à modifier et à
vérifier.

**DA-03 — les erreurs sont rendues par un statut, jamais par une exception.**
Voir module 06 pour la justification.

**DA-04 — la saturation à la capacité est appliquée en dernier**, après le
choix du mode. Ainsi la règle vaut pour les quatre modes sans être répétée
quatre fois.

---

## 2. Exigences de bas niveau

Format d'un identifiant : `LLR-FQMSCAL-nnn`.

### LLR-FQMSCAL-010

- **Type** : LLR
- **Parent** : HLR-FQMSCAL-001
- **Énoncé** : `Convert (Raw, Volume, Status)` doit affecter à `Volume` la
  valeur `Raw * 2` lorsque `Raw` est inférieur ou égal à 4 000, et affecter
  `Valid` à `Status`.
- **Vérification** : `Calibration.convert_nominal`

### LLR-FQMSCAL-020

- **Type** : LLR
- **Parent** : HLR-FQMSCAL-002
- **Énoncé** : `Convert (Raw, Volume, Status)` doit affecter `Out_Of_Domain`
  à `Status` et `0` à `Volume` lorsque `Raw` est strictement supérieur à
  4 000.
- **Vérification** : `Calibration.convert_domain_boundary`

### LLR-FQMSCAL-030

- **Type** : LLR
- **Parent** : HLR-FQMSCAL-003, HLR-FQMSCAL-004
- **Énoncé** : `Consolidate` doit, lorsque les deux sondes sont valides,
  affecter à `Volume` la moyenne entière des deux mesures et `Both_Probes` à
  `Mode`. La valeur affectée à `Volume` doit ensuite être ramenée à 8 000
  litres si elle les dépasse.
- **Vérification** : `Calibration.consolidate_both_probes`,
  `Calibration.consolidate_clamps_to_capacity`

### LLR-FQMSCAL-040

- **Type** : LLR
- **Parent** : HLR-FQMSCAL-003
- **Énoncé** : `Consolidate` doit retenir la mesure de l'unique sonde valide
  et affecter `Left_Only` ou `Right_Only` à `Mode` selon le cas ; si aucune
  sonde n'est valide, elle doit affecter `0` à `Volume` et `No_Probe` à
  `Mode`.
- **Vérification** : `Calibration.consolidate_left_only`,
  `Calibration.consolidate_right_only`, `Calibration.consolidate_no_probe`

---

## 3. Constantes de conception

| Nom | Valeur | Origine |
|---|---|---|
| `Gain` | 2 litres par compte | fiche d'étalonnage sonde ET-4412 |
| `Raw_Count'Last` | 4 000 comptes | domaine étalonné de la même fiche |
| `Capacity` | 8 000 litres | schéma réservoir centre, rév. C |

Ces valeurs sont **des exigences de bas niveau à part entière** : les changer
sans rejouer la vérification est un défaut de gestion de configuration, pas un
réglage.

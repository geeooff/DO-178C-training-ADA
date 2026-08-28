# SDD — Software Design Description

## Composant : FQMS-WRN — Alarme carburant

> **Document** : SDD (*Design Description*, DO-178C §11.10)
> **Composant** : FQMS-WRN
> **Niveau** : DAL B
> **Version** : 1.0
> **Statut de configuration** : CC1

---

## 1. Architecture

**DA-01 — une décision unique.** Les trois conditions sont combinées en une
seule expression booléenne, dans un seul sous-programme. Ce choix a un coût de
vérification explicite : trois conditions dans une décision demandent au moins
quatre cas de test pour satisfaire MC/DC. Le découper en trois décisions
successives coûterait plus cher encore.

**DA-02 — le composant est sans état.** `Global => null`, réentrance triviale.

---

## 2. Exigences de bas niveau

### LLR-FQMSWRN-010

- **Type** : LLR
- **Parent** : HLR-FQMSWRN-001, HLR-FQMSWRN-002
- **Énoncé** : `Alarm (Low_Fuel, Imbalance, Sensor_Fault)` doit rendre `True`
  si et seulement si `Low_Fuel` est vrai, ou si `Imbalance` et `Sensor_Fault`
  sont vrais tous les deux.
- **Vérification** : `Warning.mcdc_pair_low_fuel`,
  `Warning.mcdc_pair_imbalance`, `Warning.mcdc_pair_sensor_fault`,
  `Warning_Decision_Only.*`

### LLR-FQMSWRN-020

- **Type** : LLR
- **Parent** :
- **Énoncé** : Le nombre de conditions de la décision d'alarme doit être
  exposé par une constante du composant, afin que le rapport de couverture
  puisse être relu contre le minimum théorique de cas MC/DC.
- **Justification** : **exigence DÉRIVÉE.** Elle ne vient d'aucune exigence
  système : elle naît d'une décision de vérifiabilité. Elle a un coût — une
  constante à maintenir en cohérence avec l'expression — et ce coût se
  justifie par le fait qu'une revue de couverture sans point de comparaison
  se réduit à faire confiance à l'outil.
- **Vérification** : `Warning.condition_count_is_documented`

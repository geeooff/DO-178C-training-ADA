# SRD — Software Requirements Data

## Composant : FQMS-CAL — Étalonnage et consolidation de sondes carburant

> **Document** : SRD (*Software Requirements Data*, DO-178C §11.9)
> **Composant** : FQMS-CAL, sous-ensemble du *Fuel Quantity Management System*
> **Niveau** : DAL B
> **Version** : 1.0
> **Statut de configuration** : CC1

Ce document contient les **exigences de haut niveau** (HLR). Elles disent
**CE QUE** le logiciel doit faire, jamais comment. Elles sont dérivées des
exigences système et de l'analyse de sécurité, et elles sont vérifiées par des
tests écrits **sans regarder le code**.

---

## 1. Contexte système

Le réservoir central est instrumenté par **deux sondes capacitives
indépendantes**, gauche et droite. Chaque sonde délivre un compte brut. Le
calculateur en tire une indication de quantité carburant présentée à
l'équipage.

L'analyse de sécurité classe la perte d'indication en **Major** et une
indication **erronée non signalée** en **Hazardous** — d'où le DAL B, et d'où
l'exigence dérivée HLR-FQMSCAL-004.

---

## 2. Exigences de haut niveau

Format d'un identifiant : `HLR-FQMSCAL-nnn`.

### HLR-FQMSCAL-001

- **Type** : HLR
- **Parent** : SYS-FQMS-010
- **Énoncé** : Le composant doit convertir le compte brut d'une sonde en une
  quantité de carburant exprimée en litres.
- **Justification** : l'équipage lit des litres, la sonde produit des comptes.
- **Vérification** : `Calibration.hlr_converts_probe_reading`

### HLR-FQMSCAL-002

- **Type** : HLR
- **Parent** : SYS-FQMS-011
- **Énoncé** : Le composant doit refuser un compte brut situé hors du domaine
  étalonné, et signaler ce refus par un statut distinct de la valeur convertie.
- **Justification** : hors du domaine étalonné, la conversion n'a pas de sens
  physique ; rendre une valeur silencieusement fausse est le cas *Hazardous*
  de l'analyse de sécurité.
- **Vérification** : `Calibration.hlr_rejects_reading_out_of_domain`

### HLR-FQMSCAL-003

- **Type** : HLR
- **Parent** : SYS-FQMS-012
- **Énoncé** : Lorsque les deux sondes sont valides, le composant doit fournir
  une indication unique consolidée à partir des deux mesures, et indiquer sur
  combien de sondes repose cette indication.
- **Justification** : l'équipage doit savoir qu'il lit une valeur dégradée.
- **Vérification** : `Calibration.hlr_consolidates_two_probes`

### HLR-FQMSCAL-004

- **Type** : HLR
- **Parent** :
- **Énoncé** : L'indication consolidée ne doit jamais dépasser la capacité
  physique du réservoir.
- **Justification** : **exigence DÉRIVÉE.** Elle ne provient d'aucune exigence
  système : elle naît d'une décision de conception — les sondes peuvent
  indiquer au-delà de la capacité en cas de dérive d'étalonnage, et une
  indication supérieure à la capacité conduirait l'équipage à surestimer son
  autonomie. La DO-178C §5.1.2.h impose de remonter toute exigence dérivée au
  processus de sécurité système, ce que la fiche de dérivation FD-001 acte.
- **Vérification** : `Calibration.hlr_never_exceeds_capacity`

---

## 3. Ce qui n'est PAS ici

- Les seuils numériques précis (gain, capacité) : ils appartiennent au SDD,
  parce que les changer ne change pas *ce que* le logiciel doit faire.
- Le comportement en l'absence totale de sonde valide : traité au niveau
  système, et raffiné en LLR-FQMSCAL-040.
- Le format de présentation à l'équipage : hors du périmètre du composant.

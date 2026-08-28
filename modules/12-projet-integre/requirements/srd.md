# SRD — Software Requirements Data

## FQMS — Fuel Quantity Management System

> **Document** : *Software Requirements Data*, DO-178C §11.9
> **Catégorie de contrôle** : CC1
> **Niveau** : **DAL B**
> **Version** : 1.0
> **Part number** : PN-4210001-001

---

> **Ce document est identique, énoncé pour énoncé, à celui du module 16 du
> dépôt frère en C++.** C'est délibéré, et c'est l'intérêt principal des deux
> dépôts pris ensemble : les exigences ne changent pas quand le langage
> change. Seuls les champs *Vérification* citent des cas de test différents,
> puisqu'ils désignent des campagnes différentes.

---

## 0. Contexte et allocation du niveau

Le FQMS calcule et affiche à l'équipage la quantité de carburant embarquée. Il
surveille trois réservoirs : aile gauche (5 000 kg), caisson central
(8 000 kg), aile droite (5 000 kg).

**Justification du DAL B** (issue de l'analyse de sécurité système, ARP4761) :
une indication de quantité **erronée par excès** peut conduire l'équipage à
décoller avec un carburant insuffisant, donc à une panne sèche en vol —
condition de panne **dangereuse**. Le vol Air Canada 143 (1983) en est
l'illustration historique : une conversion livres/kilogrammes fausse au
plein, un système de jaugeage inopérant, et un Boeing 767 posé en vol plané
sur une piste désaffectée de Gimli.

Conséquences du DAL B (voir module 10) :

- couverture **instructions** et **décisions** requises, MC/DC **non** requise ;
- couplage données et contrôle à vérifier ;
- indépendance requise sur 18 objectifs ;
- la plupart des données de vie sont **CC1**.

---

## 1. Fonction d'acquisition

### HLR-FQMS-001

- **Type** : HLR
- **Parent** : SYS-FUEL-010
- **Énoncé** : Le logiciel doit convertir la mesure brute de chaque jauge, sur
  le domaine [0 ; 4095] points, en une masse de carburant comprise entre 0 et
  la capacité du réservoir concerné, selon une loi linéaire.
- **Vérification** : `Fqms.hlr_converts_gauge_linearly`

### HLR-FQMS-002

- **Type** : HLR
- **Parent** : SYS-FUEL-011
- **Énoncé** : Toute mesure brute hors du domaine [0 ; 4095] doit être
  rejetée. Le logiciel ne doit alors produire **aucune** quantité pour le
  réservoir concerné.
- **Justification** : une quantité fausse mais plausible est plus dangereuse
  que l'absence de quantité : les systèmes aval ne peuvent pas la distinguer
  d'une valeur correcte.
- **Vérification** : `Fqms.hlr_rejects_out_of_domain`

---

## 2. Fonction de totalisation

### HLR-FQMS-010

- **Type** : HLR
- **Parent** : SYS-FUEL-012
- **Énoncé** : Le logiciel doit calculer la quantité totale de carburant comme
  la somme des quantités des réservoirs dont la jauge est valide.
- **Vérification** : `Fqms.hlr_totalises_valid_gauges`

### HLR-FQMS-011

- **Type** : HLR
- **Parent** : SYS-FUEL-013
- **Énoncé** : Le logiciel doit signaler l'état de la quantité totale :
  **valide** si les trois jauges sont valides, **dégradée** si une ou deux
  jauges sont en panne, **indisponible** si les trois jauges sont en panne.
- **Justification** : l'équipage doit savoir si la quantité affichée est
  complète. Une quantité dégradée présentée comme valide reproduirait le
  scénario du vol Air Canada 143.
- **Vérification** : `Fqms.hlr_status_valid`, `Fqms.hlr_status_degraded`,
  `Fqms.hlr_status_unavailable`

---

## 3. Alerte de déséquilibre

### HLR-FQMS-020

- **Type** : HLR
- **Parent** : SYS-FUEL-020
- **Énoncé** : Le logiciel doit lever une alerte de déséquilibre lorsque
  l'écart de masse entre les réservoirs d'aile dépasse 500 kg pendant 5 cycles
  consécutifs.
- **Justification** : un déséquilibre latéral dégrade la tenue en roulis et
  augmente la traînée. Le seuil et la temporisation sont issus du manuel de
  vol.
- **Vérification** : `Fqms.hlr_imbalance_needs_five_cycles`

### HLR-FQMS-021

- **Type** : HLR
- **Parent** : SYS-FUEL-021
- **Énoncé** : L'alerte de déséquilibre doit s'effacer lorsque l'écart repasse
  sous 400 kg pendant 5 cycles consécutifs.
- **Justification** : hystérésis de 100 kg. Sans elle, le ballottement du
  carburant en turbulence ferait clignoter l'alerte en cabine.
- **Vérification** : `Fqms.hlr_imbalance_hysteresis`

### HLR-FQMS-022

- **Type** : HLR
- **Parent** : SYS-FUEL-022
- **Énoncé** : L'alerte de déséquilibre ne doit pas être évaluée si l'une des
  deux jauges d'aile est en panne. Son état doit alors être **conservé**.
- **Justification** : un écart calculé à partir d'une seule jauge valide n'a
  aucun sens. Geler l'alerte est préférable à la lever ou à l'effacer à tort.
- **Vérification** : `Fqms.hlr_imbalance_frozen_on_gauge_fault`

---

## 4. Alerte bas niveau

### HLR-FQMS-030

- **Type** : HLR
- **Parent** : SYS-FUEL-030
- **Énoncé** : Le logiciel doit lever une alerte bas niveau lorsque la
  quantité totale passe sous 1 500 kg pendant 5 cycles consécutifs.
- **Vérification** : `Fqms.hlr_low_level_needs_five_cycles`

### HLR-FQMS-031

- **Type** : HLR
- **Parent** : SYS-FUEL-031
- **Énoncé** : L'alerte bas niveau doit s'effacer lorsque la quantité totale
  repasse au-dessus de 1 700 kg pendant 5 cycles consécutifs.
- **Justification** : hystérésis de 200 kg.
- **Vérification** : `Fqms.hlr_low_level_hysteresis`

### HLR-FQMS-032

- **Type** : HLR
- **Parent** : SYS-FUEL-032
- **Énoncé** : L'alerte bas niveau ne doit pas être évaluée si l'une des trois
  jauges est en panne. Son état doit alors être **conservé**.
- **Justification** : une quantité partielle est nécessairement inférieure à
  la quantité réelle ; l'évaluer déclencherait une alerte bas niveau
  **injustifiée**, conduisant l'équipage à se dérouter sans raison. C'est un
  cas de fausse alerte à effet opérationnel majeur.
- **Vérification** : `Fqms.hlr_low_level_frozen_on_gauge_fault`

---

## 5. Surveillance et maintenance

### HLR-FQMS-040

- **Type** : HLR
- **Parent** : SYS-FUEL-040
- **Énoncé** : Le logiciel doit comptabiliser, par réservoir, le nombre de
  mesures rejetées depuis la mise sous tension.
- **Justification** : donnée de maintenance (BITE). Une jauge qui produit
  quelques rejets par vol annonce une panne franche à venir.
- **Vérification** : `Fqms.hlr_counts_rejects_per_tank`

### HLR-FQMS-041

- **Type** : HLR
- **Parent** :
- **Énoncé** : Le logiciel doit traiter un cycle en un temps d'exécution
  **borné et indépendant des valeurs d'entrée**.
- **Justification** : **exigence DÉRIVÉE** issue de l'architecture. Le FQMS
  s'exécute dans une fenêtre ARINC 653 de durée fixe ; un temps de traitement
  dépendant des données rendrait le WCET indémontrable. À remonter au
  processus de sécurité système pour confirmation de l'allocation temporelle.
- **Vérification** : analyse — revue du code (aucune boucle non bornée, aucune
  allocation, aucun appel dispatchant), et `scripts/stack-usage.sh` pour
  l'absence de trame non statique.

### HLR-FQMS-042

- **Type** : HLR
- **Parent** : SYS-FUEL-041
- **Énoncé** : À la mise sous tension, aucune alerte ne doit être active.
- **Justification** : une alerte active au démarrage serait interprétée comme
  une panne réelle par l'équipage.
- **Vérification** : `Fqms.hlr_no_alert_at_power_up`

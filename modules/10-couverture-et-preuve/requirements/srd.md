# SRD — Software Requirements Data

## Composant : FQMS-WRN — Alarme carburant

> **Document** : SRD (*Software Requirements Data*, DO-178C §11.9)
> **Composant** : FQMS-WRN, sous-ensemble du *Fuel Quantity Management System*
> **Niveau** : DAL B
> **Version** : 1.0
> **Statut de configuration** : CC1

---

## 1. Contexte système

L'alarme carburant du poste de pilotage est commandée à partir de trois
informations booléennes produites en amont : niveau bas, déséquilibre entre
réservoirs, panne de sonde.

Un déséquilibre seul est **normal en virage** ; une panne de sonde seule n'est
pas une alarme carburant, elle est signalée par ailleurs. C'est la conjonction
des deux qui rend la quantité indiquée douteuse.

---

## 2. Exigences de haut niveau

### HLR-FQMSWRN-001

- **Type** : HLR
- **Parent** : SYS-FQMS-030
- **Énoncé** : Le composant doit activer l'alarme carburant lorsque le niveau
  est bas.
- **Vérification** : `Warning.hlr_alarm_on_low_fuel`

### HLR-FQMSWRN-002

- **Type** : HLR
- **Parent** : SYS-FQMS-031
- **Énoncé** : Le composant ne doit pas activer l'alarme carburant lorsque
  aucune des conditions d'alarme n'est présente.
- **Justification** : une alarme intempestive détourne l'attention de
  l'équipage et le conduit à ignorer les suivantes.
- **Vérification** : `Warning.hlr_no_alarm_when_nominal`

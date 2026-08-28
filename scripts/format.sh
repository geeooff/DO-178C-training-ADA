#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Applique le format canonique. `verify.sh format` se contente de vérifier ;
# c'est ce script-ci qui modifie les fichiers.
#
# La séparation est volontaire. Un outil qui réécrit du code sous contrôle de
# configuration sans qu'un humain le demande serait un outil de développement
# au sens de la DO-330 (critère 1), soumis à qualification. Vérifier n'engage
# rien ; corriger engage. La CI ne lance donc jamais ce script.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

#  Le contre-exemple du module 11 est exclu : il viole le standard À DESSEIN,
#  et son seul point d'entrée est scripts/coding-standard.sh, qui vérifie
#  précisément qu'il ne compile PAS sous ces commutateurs.
mapfile -t PROJETS < <(find common modules -name '*.gpr' -not -path '*/nonconforme/*' | sort)

for p in "${PROJETS[@]}"; do
   echo "  $p"
   # --charset=utf-8 : sans lui, gnatformat décode en iso-8859-1 et réécrit
   # tout commentaire accentué en mojibake.
   gnatformat --charset=utf-8 -P "$p"
done

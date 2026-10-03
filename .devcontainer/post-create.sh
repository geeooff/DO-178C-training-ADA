#!/usr/bin/env bash
# Exécuté une fois, à la création du conteneur.
set -euo pipefail

# Le dépôt est monté depuis l'hôte : git refuse un dépôt dont le propriétaire
# n'est pas l'utilisateur courant tant qu'on ne l'a pas déclaré sûr.
git config --global --add safe.directory /workspace
git config --global --add safe.directory /workspace/.git

#  `sed -n 1p` et non `head -1` : sous pipefail, head ferme le tube dès la
#  première ligne, l'outil reçoit SIGPIPE en écrivant la suite, et le
#  script entier échoue en code 141 — gnatprove --version écrit cinq lignes.
echo "Chaîne disponible :"
gnatmake  --version | sed -n 1p
gprbuild  --version | sed -n 1p
gnatprove --version | sed -n 1p
gnatcov   --version | sed -n 1p
gnatformat --version | sed -n 1p

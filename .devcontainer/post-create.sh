#!/usr/bin/env bash
# Exécuté une fois, à la création du conteneur.
set -euo pipefail

# Le dépôt est monté depuis l'hôte : git refuse un dépôt dont le propriétaire
# n'est pas l'utilisateur courant tant qu'on ne l'a pas déclaré sûr.
git config --global --add safe.directory /workspace
git config --global --add safe.directory /workspace/.git

echo "Chaîne disponible :"
gnatmake  --version | head -1
gprbuild  --version | head -1
gnatprove --version | head -1
gnatcov   --version | head -1
gnatformat --version | head -1

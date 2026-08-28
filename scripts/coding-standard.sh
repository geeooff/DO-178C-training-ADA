#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Ce que le standard de codage attrape — support du module 11.
#
# Recompile le contre-exemple sous les commutateurs STRICTS du dépôt, et
# affiche les diagnostics. La compilation DOIT échouer : c'est le résultat
# attendu, et c'est pourquoi ce script n'est pas dans verify.sh.
#
# L'intérêt est de montrer la frontière : ce que le compilateur attrape tout
# seul, et ce qui reste à la revue humaine.
# ---------------------------------------------------------------------------
set -uo pipefail

cd "$(dirname "$0")/.."

SOURCE=modules/11-standards-qualification/nonconforme/src/bad_style.adb

printf '\n\033[1m== Le contre-exemple sous les commutateurs du dépôt ==\033[0m\n'

travail=$(mktemp -d)
cp "$SOURCE" "$travail"/

# Les mêmes commutateurs que shared.gpr, appliqués à la main pour rester
# lisibles dans la sortie.
( cd "$travail" \
  && gcc -c -gnat2022 -gnatW8 -gnata -gnatwa -gnatwe -gnatyy -gnatf \
        bad_style.adb ) 2>&1 | sed 's/^/  /'

statut=${PIPESTATUS[0]}
rm -rf "$travail"

printf '\n'
if [ "$statut" -eq 0 ]; then
   printf '\033[31mLe contre-exemple a compilé : le standard ne mord plus.\033[0m\n'
   exit 1
fi

printf '\033[32mCompilation refusée, comme attendu.\033[0m\n'
printf '\nCe que le compilateur N'"'"'A PAS vu, et qui reste à la revue :\n'
printf '  R-11  type nu Integer sans domaine borné\n'
printf '  R-21  garde redondante avec la précondition\n'
printf '  R-42  Ada.Text_IO et chaîne de longueur variable\n'
printf '  R-43  récursion\n'
printf '  R-61  identifiant en français\n'
printf '  R-62  commentaire qui paraphrase le code\n'
printf '\nSur un projet GNAT Pro, GNATcheck en attraperait plusieurs.\n'
printf 'Il n'"'"'est pas distribué librement : la limite est assumée.\n'

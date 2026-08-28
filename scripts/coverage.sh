#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Couverture structurelle par instrumentation de source (GNATcoverage).
#
# Le niveau demandé est stmt+mcdc : MC/DC est l'objectif de couverture du
# DAL A (DO-178C tableau A-7 §5). Le mesurer dès maintenant, au lieu de se
# contenter des lignes et des branches, est ce que la chaîne Ada permet et
# que gcov ne permettait pas dans le dépôt frère en C++.
#
# --projects restreint la mesure au projet du module. Sans lui, le harnais de
# test de common/ serait compté dans la couverture du code sous test, ce qui
# gonflerait le chiffre sans rien vérifier de plus.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

NIVEAU="${NIVEAU:-stmt+mcdc}"
mapfile -t PROJETS < <(find modules -name '*.gpr' | sort)

mkdir -p reports/couverture

for p in "${PROJETS[@]}"; do
   dossier="$(dirname "$p")"
   module="$(basename "$dossier")"
   sortie="reports/couverture/$module"
   printf '\n\033[1m== %s ==\033[0m\n' "$p"

   rm -rf "$dossier/obj" "$dossier/bin" "$dossier"/*.srctrace
   gnatcov instrument -P "$p" --projects "$p" --level="$NIVEAU" \
      --dump-trigger=atexit
   gprbuild -q -P "$p" --src-subdirs=gnatcov-instr \
      --implicit-with=gnatcov_rts

   for exe in "$dossier"/bin/*; do
      [ -f "$exe" ] && [ -x "$exe" ] || continue
      ( cd "$dossier" && "./bin/$(basename "$exe")" )
   done

   mkdir -p "$sortie"
   gnatcov coverage -P "$p" --projects "$p" --level="$NIVEAU" \
      --annotate=xcov --output-dir="$sortie" "$dossier"/*.srctrace
   cat "$sortie"/*.xcov
done

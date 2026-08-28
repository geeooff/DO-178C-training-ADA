#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Couverture structurelle par instrumentation de source (GNATcoverage).
#
# Le niveau demandé est stmt+decision+mcdc : MC/DC est l'objectif de
# couverture du DAL A (DO-178C tableau A-7 §5). Le mesurer dès maintenant, au
# lieu de se contenter des lignes et des branches, est ce que la chaîne Ada
# permet et que gcov ne permettait pas dans le dépôt frère en C++.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

NIVEAU="${NIVEAU:-stmt+mcdc}"
mapfile -t PROJETS < <(find modules -name '*.gpr' | sort)

for p in "${PROJETS[@]}"; do
   dossier="$(dirname "$p")"
   printf '\n\033[1m== %s ==\033[0m\n' "$p"

   rm -rf "$dossier/obj" "$dossier/bin"
   gnatcov instrument -P "$p" --level="$NIVEAU" --dump-trigger=atexit
   gprbuild -q -P "$p" --src-subdirs=gnatcov-instr --implicit-with=gnatcov_rts

   for exe in "$dossier"/bin/*; do
      [ -f "$exe" ] && [ -x "$exe" ] || continue
      ( cd "$dossier" && "./bin/$(basename "$exe")" )
   done

   gnatcov coverage -P "$p" --level="$NIVEAU" --annotate=xcov \
      --output-dir="$dossier/obj/couverture" "$dossier"/*.srctrace
   cat "$dossier/obj/couverture"/*.xcov
done

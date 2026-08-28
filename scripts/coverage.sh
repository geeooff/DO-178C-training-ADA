#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Couverture structurelle par instrumentation de source (GNATcoverage).
#
# Le niveau demandé est stmt+mcdc : MC/DC est l'objectif de couverture du
# DAL A (DO-178C tableau A-7 §5). Le mesurer dès maintenant, au lieu de se
# contenter des lignes et des branches, est ce que la chaîne Ada permet et
# que gcov ne permettait pas dans le dépôt frère en C++.
#
# CE QUI EST MESURÉ, ET CE QUI NE L'EST PAS
# La couverture structurelle porte sur le CODE EMBARQUÉ, exercé par les tests
# basés sur les exigences (§6.4.4.2). Mesurer en plus le harnais de test et
# les programmes de démonstration gonflerait le chiffre sans rien vérifier de
# plus — et masquerait le seul chiffre qui compte. Ils sont donc exclus, et
# l'exclusion est écrite ici plutôt que laissée au hasard d'un filtre.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

NIVEAU="${NIVEAU:-stmt+mcdc}"
mapfile -t PROJETS < <(find modules -name '*.gpr' | sort)

HORS_PERIMETRE=(
   --excluded-source-files='test_*.adb'
   --excluded-source-files='main.adb'
   --excluded-source-files='testing.ad?'
)

mkdir -p reports/couverture

for p in "${PROJETS[@]}"; do
   dossier="$(dirname "$p")"
   module="$(basename "$dossier")"
   sortie="reports/couverture/$module"
   printf '\n\033[1m== %s ==\033[0m\n' "$p"

   rm -rf "$dossier/obj" "$dossier/bin" "$dossier"/*.srctrace
   gnatcov instrument -P "$p" --level="$NIVEAU" --dump-trigger=atexit
   gprbuild -q -P "$p" --src-subdirs=gnatcov-instr \
      --implicit-with=gnatcov_rts

   #  Seules les campagnes de test comptent : la DO-178C mesure la
   #  couverture obtenue par les tests basés sur les exigences (§6.4.4.2),
   #  pas celle obtenue en lançant une démonstration.
   for exe in "$dossier"/bin/test_*; do
      [ -f "$exe" ] && [ -x "$exe" ] || continue
      ( cd "$dossier" && "./bin/$(basename "$exe")" > /dev/null )
   done

   mkdir -p "$sortie"
   gnatcov coverage -P "$p" --level="$NIVEAU" --annotate=xcov \
      "${HORS_PERIMETRE[@]}" --output-dir="$sortie" "$dossier"/*.srctrace
   cat "$sortie"/*.xcov
done

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Couverture structurelle par instrumentation de source (GNATcoverage).
#
# Le niveau demandé est stmt+mcdc : MC/DC est l'objectif de couverture du
# DAL A (DO-178C tableau A-7 §5). Le mesurer dès maintenant, au lieu de se
# contenter des lignes et des branches, est ce que la chaîne Ada permet et
# que gcov ne permettait pas dans le dépôt frère en C++.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

NIVEAU="${NIVEAU:-stmt+mcdc}"
mapfile -t PROJETS < <(find modules -name '*.gpr' | sort)

# ---------------------------------------------------------------------------
# Fichiers hors périmètre de mesure. Une exclusion se justifie, sinon elle
# maquille un chiffre.
#
#  * test_*.adb, main.adb, testing.ad? — code de VÉRIFICATION et de
#    démonstration. La DO-178C mesure la couverture obtenue par les tests
#    basés sur les exigences (§6.4.4.2), pas celle du harnais qui les
#    exécute ni celle des programmes de démonstration.
#
#  * mod04-fuel_monitor.ad? — exclusion SUBIE, et documentée comme telle.
#    `gnatcov instrument` insère une variable témoin devant chaque
#    déclaration d'objet. Dans un paquetage qui déclare un Abstract_State,
#    ces variables deviennent de l'état caché que le Refined_State ne
#    mentionne pas, et GNAT rejette alors le raffinement. Vérifié sous
#    gnatcov 26.2.1, aussi bien avec les constituants en corps qu'en partie
#    privée, et --spark-compat n'y change rien. La conception du module y
#    répond : la coquille d'état reste mince et sans décision, toute la
#    logique est dans Mod04.Alarm_Logic — qui, lui, est mesuré. Voir
#    modules/04-spark-analyse-de-flot/README.md §1.7.
# ---------------------------------------------------------------------------
HORS_PERIMETRE=(
   --excluded-source-files='test_*.adb'
   --excluded-source-files='main.adb'
   --excluded-source-files='testing.ad?'
   --excluded-source-files='mod04-fuel_monitor.ad?'
)

mkdir -p reports/couverture

for p in "${PROJETS[@]}"; do
   dossier="$(dirname "$p")"
   module="$(basename "$dossier")"
   sortie="reports/couverture/$module"
   printf '\n\033[1m== %s ==\033[0m\n' "$p"

   rm -rf "$dossier/obj" "$dossier/bin" "$dossier"/*.srctrace

   #  --spark-compat rend le code instrumenté conforme aux règles Ghost de
   #  SPARK. Il ne résout PAS le cas Abstract_State ci-dessus : c'est la
   #  liste d'exclusions qui s'en charge.
   gnatcov instrument -P "$p" --level="$NIVEAU" --dump-trigger=atexit \
      --spark-compat "${HORS_PERIMETRE[@]}"

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

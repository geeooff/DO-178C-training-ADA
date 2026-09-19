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
mapfile -t PROJETS < <(find modules -name '*.gpr' -not -path '*/nonconforme/*' | sort)

# ---------------------------------------------------------------------------
# Périmètre de mesure : les unités ModNN.* du module, et rien d'autre.
#
# `--units` le dit positivement à gnatcov. Sans lui, le harnais et les
# programmes principaux restent des « unités d'intérêt » que l'exclusion
# ci-dessous ignore fichier par fichier, et gnatcov signale alors pour
# chacune un « no SID file found » — vingt-cinq avertissements par campagne
# complète, tous attendus, tous à ignorer. Un journal de vérification qui
# demande au lecteur d'ignorer des avertissements n'est pas un journal
# propre. Le périmètre déclaré est aussi ce que la DO-178C attend : on dit
# ce qu'on mesure, on ne laisse pas l'outil le déduire.
# ---------------------------------------------------------------------------
PERIMETRE=(--units='mod*')

# ---------------------------------------------------------------------------
# Fichiers hors périmètre de mesure. Une exclusion se justifie, sinon elle
# maquille un chiffre.
#
#  * test_*.adb, main.adb, testing.ad? — code de VÉRIFICATION et de
#    démonstration. La DO-178C mesure la couverture obtenue par les tests
#    basés sur les exigences (§6.4.4.2), pas celle du harnais qui les
#    exécute ni celle des programmes de démonstration. Déjà hors périmètre
#    par `--units` ; l'exclusion explicite reste pour que l'intention se
#    lise ici, avec sa justification.
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
#
#    Cette exclusion laisse UN avertissement dans le journal — « no SID file
#    found for unit mod04.fuel_monitor » — et c'est voulu : une unité du
#    périmètre qui n'est pas mesurée doit rester visible, pas disparaître
#    en silence. C'est le seul avertissement attendu de ce script.
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

   #  Un projet sans campagne de test n'a rien à mesurer : la DO-178C mesure
   #  la couverture obtenue par les tests basés sur les exigences (§6.4.4.2),
   #  pas celle d'une démonstration. C'est le cas des deux profils du
   #  module 06 (restreint) et du module 07 (Ravenscar), qui ne servent qu'à
   #  prouver qu'ils se construisent. On le constate AVANT d'instrumenter :
   #  le profil Ravenscar n'a aucune unité ModNN, et gnatcov refuserait à
   #  juste titre d'instrumenter un périmètre vide.
   if ! compgen -G "$dossier/*/test_*.adb" > /dev/null; then
      echo "  (aucune campagne de test : rien à mesurer)"
      continue
   fi

   #  --spark-compat rend le code instrumenté conforme aux règles Ghost de
   #  SPARK. Il ne résout PAS le cas Abstract_State ci-dessus : c'est la
   #  liste d'exclusions qui s'en charge.
   gnatcov instrument -P "$p" --level="$NIVEAU" --dump-trigger=atexit \
      --spark-compat "${PERIMETRE[@]}" "${HORS_PERIMETRE[@]}"

   gprbuild -q -P "$p" --src-subdirs=gnatcov-instr \
      --implicit-with=gnatcov_rts

   #  Seules les campagnes de test comptent : la DO-178C mesure la
   #  couverture obtenue par les tests basés sur les exigences (§6.4.4.2),
   #  pas celle obtenue en lançant une démonstration.
   for exe in "$dossier"/bin/test_*; do
      [ -f "$exe" ] && [ -x "$exe" ] || continue
      ( cd "$dossier" && "./bin/$(basename "$exe")" > /dev/null )
   done

   #  Une campagne existe : elle DOIT avoir laissé une trace. Sans trace,
   #  c'est l'instrumentation ou le déclencheur d'écriture qui est en
   #  défaut, et un chiffre de couverture absent n'est pas un chiffre nul —
   #  c'est une vérification qui n'a pas eu lieu.
   if ! compgen -G "$dossier/*.srctrace" > /dev/null; then
      echo "  ERREUR : campagne présente, aucune trace produite." >&2
      exit 1
   fi

   mkdir -p "$sortie"
   gnatcov coverage -P "$p" --level="$NIVEAU" --annotate=xcov \
      "${PERIMETRE[@]}" "${HORS_PERIMETRE[@]}" \
      --output-dir="$sortie" "$dossier"/*.srctrace
   cat "$sortie"/*.xcov
done

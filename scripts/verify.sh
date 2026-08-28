#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Protocole de vérification du dépôt. Aucune modification n'est terminée tant
# que ce script n'est pas vert. C'est ce qui distingue un support de formation
# d'un ensemble d'extraits jamais compilés.
#
#   ./scripts/verify.sh          toutes les étapes
#   ./scripts/verify.sh build    une étape (build|run|prove|trace|format)
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

ETAPE="${1:-all}"
#  Le contre-exemple du module 11 est exclu : il viole le standard À DESSEIN,
#  et son seul point d'entrée est scripts/coding-standard.sh, qui vérifie
#  précisément qu'il ne compile PAS sous ces commutateurs.
mapfile -t PROJETS < <(find common modules -name '*.gpr' -not -path '*/nonconforme/*' | sort)

if [ ${#PROJETS[@]} -eq 0 ]; then
   echo "Aucun projet GPR trouvé sous modules/." >&2
   exit 1
fi

titre() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

if [ "$ETAPE" = all ] || [ "$ETAPE" = build ]; then
   titre "Compilation — avertissements traités en erreurs"
   for p in "${PROJETS[@]}"; do
      echo "  $p"
      gprbuild -q -P "$p"
   done
fi

if [ "$ETAPE" = all ] || [ "$ETAPE" = run ]; then
   titre "Exécution des programmes témoins"
   for exe in modules/*/bin/* modules/*/*/bin/*; do
      [ -f "$exe" ] && [ -x "$exe" ] || continue
      echo "  $exe"
      "$exe"
   done
fi

if [ "$ETAPE" = all ] || [ "$ETAPE" = prove ]; then
   titre "Preuve SPARK"
   for p in "${PROJETS[@]}"; do
      echo "  $p"
      # -U est obligatoire : sans lui, gnatprove n'analyse que la clôture des
      # unités principales et laisse passer sans un mot tout fichier qui n'en
      # fait pas partie.
      gnatprove -P "$p" -U --checks-as-errors=on --report=statistics -q
   done
fi

if [ "$ETAPE" = all ] || [ "$ETAPE" = trace ]; then
   titre "Traçabilité exigences <-> code <-> tests"
   # --strict : la vérification échoue si la matrice se dégrade. C'est ce qui
   # empêche une exigence non implémentée, un test orphelin ou une référence
   # documentaire périmée de passer inaperçus.
   python3 tools/trace_check.py --strict --csv reports/tracabilite.csv \
      | tail -20
fi

if [ "$ETAPE" = all ] || [ "$ETAPE" = format ]; then
   titre "Formatage"
   for p in "${PROJETS[@]}"; do
      echo "  $p"
      # --charset=utf-8 est obligatoire : le défaut de gnatformat est
      # iso-8859-1, et il réécrit alors les commentaires accentués en mojibake.
      gnatformat --check --charset=utf-8 -P "$p"
   done
fi

printf '\n\033[32mVérification terminée sans défaut.\033[0m\n'

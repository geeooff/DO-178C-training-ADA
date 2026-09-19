#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Analyse de pile — support du module 07.
#
# Sans allocation dynamique, la seule mémoire qui varie à l'exécution est la
# PILE. La DO-178C la nomme explicitement : le §6.3.4.f (objectif A-5.6, le
# code est « accurate and consistent ») cite l'usage de la pile parmi ce que
# la revue du code doit examiner, à côté du temps d'exécution pire cas. Un
# débordement de pile est un défaut catastrophique et silencieux.
#
# -fstack-usage fait écrire au compilateur, pour chaque sous-programme, la
# taille de sa trame et sa nature — `static`, `dynamic` ou `bounded`. Une
# trame `dynamic` est un signal d'alarme : sa taille dépend de l'exécution,
# donc le pire cas ne se calcule pas depuis le source.
#
# Ce script ne remplace pas un outil d'analyse de pile réel (GNATstack, ou
# une mesure sur cible) : il montre la matière première et où la chercher.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

mapfile -t PROJETS < <(find common modules -name '*.gpr' -not -path '*/nonconforme/*' | sort)

titre() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

titre "Reconstruction avec -fstack-usage"
for p in "${PROJETS[@]}"; do
   gprbuild -q -f -P "$p" --subdirs=pile -cargs -fstack-usage
done

titre "Trames les plus grandes, tous modules confondus"
printf '%8s  %-9s  %s\n' "OCTETS" "NATURE" "SOUS-PROGRAMME"
find . -path '*/pile/*' -name '*.su' -print0 \
   | xargs -0 cat \
   | awk -F'\t' 'NF >= 3 { printf "%8d  %-9s  %s\n", $2, $3, $1 }' \
   | sort -rn \
   | head -15

titre "Trames non statiques"
# Une seule ligne ici et l'analyse de pire cas depuis le source tombe.
if find . -path '*/pile/*' -name '*.su' -print0 \
      | xargs -0 cat \
      | awk -F'\t' '$3 != "static"' \
      | grep . ; then
   echo "(voir ci-dessus)"
else
   echo "Aucune : toutes les trames sont de taille statique."
fi

titre "Total"
find . -path '*/pile/*' -name '*.su' -print0 \
   | xargs -0 cat \
   | awk -F'\t' 'NF >= 3 { n += 1; s += $2 }
                 END { printf "%d sous-programmes, %d octets de trames cumulés\n", n, s }'

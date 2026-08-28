#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Ce que coûtent les vérifications à l'exécution — support du module 02.
#
# Construit deux fois le même source : une fois tel quel, une fois avec
# -gnatp qui supprime les vérifications. Compare la taille du code objet,
# exécute les deux, et montre le code que le compilateur a ajouté.
#
# Ce script n'est pas dans verify.sh : il ne vérifie rien, il mesure. Les
# chiffres qu'il produit sont recopiés dans le README du module 02, et se
# rejouent d'une commande pour vérifier qu'ils n'ont pas menti.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

PROJET=modules/02-verifications-execution/mod02.gpr
UNITE=mod02-fuel_gauge.o

titre() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

titre "Construction avec vérifications"
gprbuild -q -f -P "$PROJET" --subdirs=avec

titre "Construction sans vérifications (-gnatp)"
gprbuild -q -f -P "$PROJET" --subdirs=sans -cargs -gnatp

titre "Taille du code objet"
AVEC=modules/02-verifications-execution/obj/avec/$UNITE
SANS=modules/02-verifications-execution/obj/sans/$UNITE
size "$AVEC" "$SANS"

octets_avec=$(size --format=SysV "$AVEC" | awk '$1==".text" {print $2}')
octets_sans=$(size --format=SysV "$SANS" | awk '$1==".text" {print $2}')
printf '\n.text avec contrôles : %s octets\n' "$octets_avec"
printf '.text sans contrôles : %s octets\n' "$octets_sans"
printf 'Surcoût             : %s octets (%s %%)\n' \
   "$((octets_avec - octets_sans))" \
   "$(( (octets_avec - octets_sans) * 100 / octets_sans ))"

titre "Comportement avec vérifications"
modules/02-verifications-execution/bin/avec/main | tail -4

titre "Comportement sans vérifications"
modules/02-verifications-execution/bin/sans/main | tail -4

# -gnatG imprime le source ÉTENDU par le compilateur : on y lit les
# `[constraint_error when ...]` que personne n'a écrits. C'est très
# exactement ce que la DO-178C §6.4.4.2.b appelle du code objet sans
# équivalent source, et ce qui oblige, en DAL A, à une analyse de couverture
# du code objet.
#
# On compile ici l'unité seule, hors gprbuild : sinon la sortie mélange les
# vérifications de toutes les unités du projet, harnais compris.
travail=$(mktemp -d)
cp modules/02-verifications-execution/src/mod02*.ad? "$travail"/
( cd "$travail" \
  && gcc -c -gnatG -gnat2022 -gnatW8 -gnata mod02-fuel_gauge.adb ) \
   | grep -B 2 -A 3 -F "[constraint_error when" | head -24
rm -rf "$travail"

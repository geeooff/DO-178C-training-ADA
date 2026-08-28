#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
trace_check.py -- verificateur de tracabilite exigences <-> code <-> tests.

CONTEXTE DO-178C
----------------
La norme exige une tracabilite BIDIRECTIONNELLE entre les exigences de haut
niveau, les exigences de bas niveau, le code source et les cas de test
(objectifs A-3.6, A-4.6, A-5.5 et tables A-6/A-7). Le sens descendant
(exigence -> code) montre que tout ce qui etait demande est fait. Le sens
remontant (code -> exigence) montre qu'il n'y a rien DE PLUS que ce qui etait
demande : c'est celui qui revele le code non justifie, donc le code mort et
les fonctions ajoutees au cas ou.

Cet outil reconstruit les deux sens et signale cinq defauts :

    1. exigence de bas niveau SANS code   -> non implementee
    2. exigence SANS aucune verification  -> non verifiee
    3. code citant une exigence INCONNUE  -> reference pourrie
    4. cas de test SANS exigence valide   -> test orphelin
    5. document citant un cas INEXISTANT  -> matrice qui designe du vide

Le defaut 5 merite un mot. Les documents d'exigences citent leurs cas de test
dans le champ "Verification", et les README de module dans leur colonne
"Verifiee par". Ces references croisees sont ecrites A LA MAIN. Une reference
croisee que personne ne verifie POURRIT : il suffit de renommer un cas de test
pour que le document continue a citer un nom qui n'existe plus, sans que rien
ne le signale. La matrice a alors l'air complete, mais elle designe du vide.

STATUT DE QUALIFICATION (DO-330)
--------------------------------
Cet outil est un OUTIL DE VERIFICATION au sens de la DO-178C 12.2 : son
resultat pourrait servir a eliminer une revue manuelle de la matrice de
tracabilite. Dans ce cas il releverait du TQL-5 et devrait etre qualifie.

Dans le cadre de cette formation il est utilise en COMPLEMENT de la revue
manuelle, jamais a sa place : la qualification n'est donc pas requise. Cette
distinction est exactement celle que la DO-330 demande d'expliciter, et le
module 11 la traite.

FORMATS RECONNUS
----------------
Exigences (fichiers modules/*/requirements/*.md) :

    ### LLR-FQMS-010
    - **Type** : LLR
    - **Parent** : HLR-FQMS-002, HLR-FQMS-003
    - **Enonce** : ...
    - **Verification** : `Gauge.nominal_reading`

Code source Ada (.ads / .adb) :

    --  @satisfies LLR-FQMS-010

Cas de test. Le nom de la suite est declare UNE FOIS par fichier, et chaque
cas le reprend -- c'est ce qui evite de le recopier a chaque appel :

    Suite : constant String := "Gauge";
    ...
    Testing.Start (Suite, "nominal_reading", "LLR-FQMS-010");

USAGE
-----
    python3 tools/trace_check.py                 # rapport console
    python3 tools/trace_check.py --csv rapport.csv
    python3 tools/trace_check.py --strict        # code 1 si defaut
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

# --- Motifs de reconnaissance -------------------------------------------------

# Un identifiant d'exigence : PREFIXE-COMPOSANT-NUMERO
RE_REQ_ID = re.compile(r"\b((?:HLR|LLR|SYS|DER)-[A-Z0-9]+-\d+)\b")

RE_REQ_HEADER = re.compile(r"^###\s+((?:HLR|LLR|SYS|DER)-[A-Z0-9]+-\d+)\s*$")
RE_REQ_FIELD = re.compile(r"^\s*-\s+\*\*(\w+)\*\*\s*:\s*(.*)$")

RE_SATISFIES = re.compile(r"@satisfies\s+([A-Za-z0-9\-,\s]+)")

# Le nom de la suite, declare une fois par fichier de test.
RE_SUITE_DECL = re.compile(
    r"Suite\s*:\s*constant\s+String\s*:=\s*\"([^\"]+)\"\s*;"
)

# L'appel qui ouvre un cas de test. DOTALL parce que gnatformat a le droit de
# repartir l'appel sur plusieurs lignes : un outil de tracabilite qui se
# casserait au premier reformatage ne servirait a rien.
RE_TEST_START = re.compile(
    r"Testing\.Start\s*\(\s*Suite\s*,\s*\"([^\"]+)\"\s*,\s*\"([^\"]*)\"\s*\)",
    re.DOTALL,
)

SOURCE_SUFFIXES = {".ads", ".adb"}

# Repertoires produits par la construction : jamais du code source.
IGNORED_PARTS = {
    "obj", "bin", "lib", ".git", "reports", "pile",
}


@dataclass
class Requirement:
    identifier: str
    kind: str = ""
    parents: list[str] = field(default_factory=list)
    statement: str = ""
    source_file: str = ""
    line: int = 0
    derived: bool = False

    #  Une exigence peut etre verifiee par TEST, par ANALYSE ou par REVUE
    #  (DO-178C 6.3 et 6.4). Un outil qui ne connait que le test signale a
    #  tort comme non verifiee toute exigence dont la verification est une
    #  analyse -- et le bruit finit par faire ignorer les vrais defauts.
    verification: str = ""
    by_analysis: bool = False

    code_sites: list[str] = field(default_factory=list)
    test_cases: list[str] = field(default_factory=list)


@dataclass
class Findings:
    requirements: dict[str, Requirement] = field(default_factory=dict)
    unknown_in_code: list[tuple[str, str]] = field(default_factory=list)
    unknown_in_tests: list[tuple[str, str]] = field(default_factory=list)
    untraced_tests: list[str] = field(default_factory=list)
    stale_doc_refs: list[tuple[str, int, str]] = field(default_factory=list)
    known_cases: set[str] = field(default_factory=set)
    known_suites: set[str] = field(default_factory=set)


# --- Lecture des exigences ----------------------------------------------------

def parse_requirement_files(root: Path) -> dict[str, Requirement]:
    """Lit tous les fichiers d'exigences du depot."""
    requirements: dict[str, Requirement] = {}

    for path in sorted(root.glob("modules/*/requirements/*.md")):
        current: Requirement | None = None
        relative = path.relative_to(root).as_posix()
        lines = path.read_text(encoding="utf-8").splitlines()

        for number, raw in enumerate(lines, start=1):
            header = RE_REQ_HEADER.match(raw)
            if header:
                identifier = header.group(1)
                current = Requirement(
                    identifier=identifier, source_file=relative, line=number
                )
                if identifier in requirements:
                    print(f"ATTENTION : exigence en double : {identifier}")
                requirements[identifier] = current
                continue

            if current is None:
                continue

            field_match = RE_REQ_FIELD.match(raw)
            if not field_match:
                continue

            name = field_match.group(1).lower()
            value = field_match.group(2).strip()

            if name == "type":
                current.kind = value
            elif name == "parent":
                parents = RE_REQ_ID.findall(value)
                current.parents = parents
                # Une exigence sans parent est DERIVEE : la DO-178C impose de
                # l'identifier comme telle et de la remonter au processus de
                # securite systeme (5.1.2.h).
                current.derived = len(parents) == 0
            elif name in ("enonce", "énoncé"):
                current.statement = value
            elif name in ("verification", "vérification"):
                current.verification = value
                minuscule = value.lower()
                current.by_analysis = (
                    "analyse" in minuscule or "revue" in minuscule
                )

    return requirements


# --- Lecture du code et des tests ---------------------------------------------

def traced_modules(root: Path) -> list[Path]:
    """Modules situes DANS le perimetre de tracabilite.

    Le perimetre est defini par la presence d'un repertoire requirements/ :
    c'est une decision de configuration, pas une convention implicite. Les
    modules pedagogiques qui n'en ont pas restent hors perimetre, et leurs
    identifiants LLR-Mxx-nnn ne sont donc pas signales comme inconnus.
    """
    return sorted(p.parent for p in root.glob("modules/*/requirements"))


def in_scope(path: Path, scope: list[Path] | None) -> bool:
    if scope is None:
        return True
    return any(scoped == path or scoped in path.parents for scoped in scope)


def scan_sources(root: Path, findings: Findings, scope: list[Path] | None) -> None:
    """Parcourt le code source et les tests du perimetre."""
    for path in sorted(root.rglob("*")):
        if path.suffix not in SOURCE_SUFFIXES:
            continue
        if IGNORED_PARTS & set(path.parts):
            continue
        if not in_scope(path, scope):
            continue

        relative = path.relative_to(root).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")

        # --- annotations @satisfies (code de production) --------------------
        for number, raw in enumerate(text.splitlines(), start=1):
            site = f"{relative}:{number}"
            for match in RE_SATISFIES.finditer(raw):
                for identifier in RE_REQ_ID.findall(match.group(1)):
                    requirement = findings.requirements.get(identifier)
                    if requirement is None:
                        findings.unknown_in_code.append((identifier, site))
                    else:
                        requirement.code_sites.append(site)

        # --- cas de test ----------------------------------------------------
        suite_decl = RE_SUITE_DECL.search(text)
        if suite_decl is None:
            continue
        suite = suite_decl.group(1)
        findings.known_suites.add(suite)

        for match in RE_TEST_START.finditer(text):
            name, ids = match.group(1), match.group(2)
            number = text.count("\n", 0, match.start()) + 1
            site = f"{relative}:{number}"
            case_name = f"{suite}.{name}"
            findings.known_cases.add(case_name)

            found = RE_REQ_ID.findall(ids)
            if not found:
                findings.untraced_tests.append(f"{case_name} ({site})")
            for identifier in found:
                requirement = findings.requirements.get(identifier)
                if requirement is None:
                    findings.unknown_in_tests.append(
                        (identifier, f"{case_name} @ {site}")
                    )
                else:
                    requirement.test_cases.append(case_name)


# --- Verification des references documentaires --------------------------------

# Un nom de cas de test cite dans la documentation : `Suite.nom_du_cas`, ou
# `Suite.*` pour designer toute une suite. La majuscule initiale de la suite et
# la minuscule initiale du cas distinguent ces citations d'un nom de fichier.
RE_DOC_TESTREF = re.compile(r"`([A-Z][A-Za-z0-9_]*)\.([a-z_][a-z0-9_]*\*?|\*)`")

EXTENSIONS_FICHIER = {
    "ads", "adb", "adc", "gpr", "md", "py", "sh", "toml", "json", "yml",
    "yaml", "txt", "out", "su", "xcov", "csv", "html", "log",
}


def check_doc_references(
    root: Path, findings: Findings, scope: list[Path] | None
) -> None:
    """Verifie que les cas de test cites dans la documentation existent."""
    for path in sorted(root.glob("modules/*/**/*.md")):
        if not in_scope(path, scope):
            continue

        relative = path.relative_to(root).as_posix()
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for number, raw in enumerate(lines, start=1):
            for match in RE_DOC_TESTREF.finditer(raw):
                suite, cas = match.group(1), match.group(2)
                if cas in EXTENSIONS_FICHIER:
                    continue  # nom de fichier, pas un cas de test
                if cas == "*":
                    if suite not in findings.known_suites:
                        findings.stale_doc_refs.append(
                            (relative, number, f"{suite}.*")
                        )
                elif cas.endswith("*"):
                    prefixe = f"{suite}.{cas[:-1]}"
                    if not any(c.startswith(prefixe) for c in findings.known_cases):
                        findings.stale_doc_refs.append(
                            (relative, number, f"{suite}.{cas}")
                        )
                else:
                    nom = f"{suite}.{cas}"
                    if nom not in findings.known_cases:
                        findings.stale_doc_refs.append((relative, number, nom))


# --- Rapport ------------------------------------------------------------------

def print_report(findings: Findings) -> int:
    requirements = findings.requirements
    defects = 0

    llr = {k: v for k, v in requirements.items() if v.kind.upper() == "LLR"}
    hlr = {k: v for k, v in requirements.items() if v.kind.upper() == "HLR"}

    print("=" * 78)
    print("  RAPPORT DE TRACABILITE")
    print("=" * 78)
    print(f"  exigences de haut niveau (HLR) : {len(hlr)}")
    print(f"  exigences de bas niveau  (LLR) : {len(llr)}")
    print(f"  total                          : {len(requirements)}")

    derived = [r for r in requirements.values() if r.derived]
    print(f"  dont exigences DERIVEES        : {len(derived)}")
    for requirement in derived:
        print(
            f"      {requirement.identifier}  "
            f"({requirement.source_file}:{requirement.line})"
        )
    if derived:
        print("      -> a remonter au processus de securite systeme (5.1.2.h)")

    print()
    print("-" * 78)
    print(f"  {'EXIGENCE':<22}{'CODE':>6}{'TESTS':>7}   CAS DE TEST")
    print("-" * 78)
    for identifier in sorted(requirements):
        requirement = requirements[identifier]
        cases = ", ".join(sorted(set(requirement.test_cases)))
        print(
            f"  {identifier:<22}{len(requirement.code_sites):>6}"
            f"{len(set(requirement.test_cases)):>7}   {cases[:38]}"
        )

    print()
    print("-" * 78)
    print("  DEFAUTS DETECTES")
    print("-" * 78)

    # 1. LLR sans code
    sans_code = [r for r in llr.values() if not r.code_sites]
    if sans_code:
        defects += len(sans_code)
        print(f"  [1] {len(sans_code)} LLR SANS code (@satisfies) :")
        for requirement in sans_code:
            print(f"      {requirement.identifier}  -- non implementee ?")
    else:
        print("  [1] toutes les LLR sont implementees (@satisfies present)")

    # 2. exigence sans test
    #
    #    Nuance importante : une HLR peut etre verifiee INDIRECTEMENT si toutes
    #    les LLR qui la couvrent sont elles-memes testees. La DO-178C demande
    #    neanmoins des tests bases sur les HLR (table A-6, objectifs 1 et 2) :
    #    on distingue donc le DEFAUT de l'OBSERVATION.
    sans_test = [
        r for r in requirements.values()
        if not r.test_cases and r.kind.upper() != "SYS"
    ]
    defauts_test = []
    observations_test = []
    par_analyse = []
    for requirement in sans_test:
        #  Verifiee par ANALYSE ou par REVUE plutot que par test : legitime
        #  (§6.3, §6.4), et il faut alors que le champ Verification le dise.
        if requirement.by_analysis:
            par_analyse.append(requirement)
            continue
        if requirement.kind.upper() == "HLR":
            enfants = [
                v for v in llr.values() if requirement.identifier in v.parents
            ]
            if enfants and all(v.test_cases for v in enfants):
                observations_test.append(requirement)
                continue
        defauts_test.append(requirement)

    if defauts_test:
        defects += len(defauts_test)
        print(f"  [2] {len(defauts_test)} exigence(s) SANS verification :")
        for requirement in defauts_test:
            print(f"      {requirement.identifier}  ({requirement.kind})")
    else:
        print("  [2] toute exigence est verifiee, directement ou via ses LLR")

    if par_analyse:
        print(
            f"      {len(par_analyse)} exigence(s) verifiee(s) par ANALYSE "
            "ou REVUE, sans cas de test — legitime si le champ"
        )
        print("      Verification le dit explicitement :")
        for requirement in par_analyse:
            print(
                f"        {requirement.identifier}  "
                f"({requirement.verification})"
            )

    if observations_test:
        print(
            f"      OBSERVATION : {len(observations_test)} HLR verifiee(s) "
            "seulement INDIRECTEMENT, via leurs LLR. La table A-6 demande"
        )
        print("      aussi des tests bases sur les exigences de HAUT niveau :")
        for requirement in observations_test:
            print(f"        {requirement.identifier}")

    # 3. code referencant une exigence inconnue
    if findings.unknown_in_code:
        defects += len(findings.unknown_in_code)
        print(
            f"  [3] {len(findings.unknown_in_code)} reference(s) a une "
            "exigence INCONNUE :"
        )
        for identifier, site in findings.unknown_in_code:
            print(f"      {identifier}  a {site}")
    else:
        print("  [3] aucune reference a une exigence inconnue dans le code")

    # 4. tests orphelins
    orphelins = findings.untraced_tests + [
        f"{case} -> {identifier} inconnue"
        for identifier, case in findings.unknown_in_tests
    ]
    if orphelins:
        defects += len(orphelins)
        print(f"  [4] {len(orphelins)} cas de test SANS exigence valide :")
        for entry in orphelins:
            print(f"      {entry}")
    else:
        print("  [4] tous les cas de test sont traces a une exigence existante")

    # 5. references documentaires perimees
    if findings.stale_doc_refs:
        defects += len(findings.stale_doc_refs)
        print(
            f"  [5] {len(findings.stale_doc_refs)} reference(s) documentaire(s)"
            " vers un cas de test INEXISTANT :"
        )
        for fichier, ligne, nom in findings.stale_doc_refs:
            print(f"      {fichier}:{ligne}  cite {nom}")
        print("      -> la documentation designe du vide : renommage oublie ?")
    else:
        print("  [5] toute reference documentaire designe un cas existant")

    print()
    print("-" * 78)
    print("  COUVERTURE DES HLR PAR LES LLR")
    print("-" * 78)
    for identifier in sorted(hlr):
        enfants = sorted(k for k, v in llr.items() if identifier in v.parents)
        if enfants:
            print(f"  {identifier:<22} <- {', '.join(enfants)}")
        else:
            defects += 1
            print(f"  {identifier:<22} <- AUCUNE LLR  *** DEFAUT ***")

    print()
    print("=" * 78)
    if defects == 0:
        print("  RESULTAT : aucun defaut de tracabilite detecte.")
    else:
        print(f"  RESULTAT : {defects} defaut(s) de tracabilite a traiter.")
    print("=" * 78)
    return defects


def write_csv(findings: Findings, path: Path) -> None:
    # Le repertoire de destination n'existe pas forcement : reports/ est
    # ignore par Git, donc absent de tout depot fraichement clone -- ce qui
    # est exactement le cas d'une machine d'integration continue.
    if path.parent != Path(""):
        path.parent.mkdir(parents=True, exist_ok=True)

    lignes = ["exigence;type;derivee;parents;sites_code;cas_de_test"]
    for identifier in sorted(findings.requirements):
        requirement = findings.requirements[identifier]
        lignes.append(
            ";".join(
                [
                    identifier,
                    requirement.kind,
                    "oui" if requirement.derived else "non",
                    "|".join(requirement.parents),
                    "|".join(requirement.code_sites),
                    "|".join(sorted(set(requirement.test_cases))),
                ]
            )
        )
    path.write_text("\n".join(lignes) + "\n", encoding="utf-8")
    print(f"\nMatrice exportee vers {path}")


def main() -> int:
    # La console Windows utilise cp1252 par defaut : on force l'UTF-8 pour que
    # les accents des rapports s'affichent correctement.
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    parser.add_argument("--root", default=".", help="racine du depot")
    parser.add_argument("--csv", help="exporte la matrice au format CSV")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="code de retour non nul si un defaut est detecte",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="scanne TOUT le depot, modules hors perimetre compris",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not (root / "modules").is_dir():
        print(f"ERREUR : {root} n'est pas la racine du depot (pas de modules/).")
        return 2

    findings = Findings(requirements=parse_requirement_files(root))
    if not findings.requirements:
        print("Aucune exigence trouvee dans modules/*/requirements/*.md")
        return 2

    scope = None if args.all else traced_modules(root)
    if scope is not None:
        print("Perimetre de tracabilite :")
        for module in scope:
            print(f"    {module.relative_to(root).as_posix()}")
        print()

    scan_sources(root, findings, scope)
    check_doc_references(root, findings, scope)
    defects = print_report(findings)

    if args.csv:
        write_csv(findings, Path(args.csv))

    return 1 if (args.strict and defects > 0) else 0


if __name__ == "__main__":
    sys.exit(main())

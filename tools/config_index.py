#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
config_index.py -- generation du SCI et du SECI a partir du depot Git.

CONTEXTE DO-178C
----------------
La section 11 de la DO-178C decrit deux documents que tout dossier de
certification doit contenir :

  * SCI  -- Software Configuration Index (11.16)
            La liste EXACTE de ce qui constitue le logiciel : chaque fichier,
            sa taille, son empreinte. C'est ce qui permet d'affirmer "ce
            binaire est bien celui qui a ete verifie", et de le reconstruire
            a l'identique dans quinze ans.

  * SECI -- Software Life Cycle Environment Configuration Index (11.15)
            La liste EXACTE de l'environnement de production : compilateur et
            sa version, options, outils de verification, systeme hote.

Le SCI est classe CC1 a tous les niveaux : sans lui, le produit n'est pas
identifiable. Le SECI l'est aux niveaux A a C ; la table A-8 l'allege en CC2
au niveau D, ou l'enjeu ne justifie plus l'approbation formelle de chaque
version de l'environnement.

CE QUE CET OUTIL FAIT DE PARTICULIER ICI
----------------------------------------
Le SECI de ce depot n'est pas une liste que l'on tient a jour : c'est
.devcontainer/Dockerfile, ou ce que l'image contient est epingle : image de
base par digest, paquets apt par instantane de l'archive, archive d'Alire par
empreinte, chaine Ada par versions de crates. Il relit aussi, dans l'image,
l'instantane que les sources apt designent et l'empreinte d'Alire
effectivement controlee, et signale tout ecart. L'outil lit donc les
ARG de ce fichier EN PLUS d'interroger les outils presents sur la machine, et
il RAPPROCHE les deux. Un ecart entre la version epinglee et la version
detectee est signale : c'est exactement le defaut qu'un SECI doit empecher.

Il lit aussi les lignes FROM, et signale toute image de base designee par sa
seule etiquette, sans digest : elle peut changer sans que le depot change.

Enfin, il consigne ce qui CONSTRUIT l'image sans en faire partie -- image du
runner, buildx, BuildKit -- quand la CI le lui transmet par les variables
SECI_RUNNER, SECI_BUILDX et SECI_BUILDKIT. Ces outils ne sont pas epingles :
ils sont traces. GITHUB_ACTIONS, transmise elle aussi, distingue un document
genere hors CI (variables absentes, c'est normal) d'un document genere en CI
avec une valeur manquante (c'est un defaut, et il est signale).

STATUT DE QUALIFICATION (DO-330)
--------------------------------
Cet outil produit une DONNEE DE VIE DU LOGICIEL. Il n'elimine, ne reduit ni
n'automatise aucune activite de VERIFICATION : le SCI qu'il genere est relu et
approuve. Il ne requiert donc PAS de qualification.

S'il servait a demontrer l'integrite du chargement sans autre verification, il
deviendrait un outil de verification, donc TQL-5.

USAGE
-----
    python3 tools/config_index.py
    python3 tools/config_index.py --output reports
    python3 tools/config_index.py --part-number PN-7654321-002 --version 1.0.0
"""

from __future__ import annotations

import argparse
import hashlib
import os
import platform
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# Fichiers exclus du perimetre de configuration du LOGICIEL : ils appartiennent
# au projet, pas au produit charge dans l'equipement.
EXCLUDED_PREFIXES = ("reports/", "obj/", "bin/")

DOCKERFILE = Path(".devcontainer/Dockerfile")


def run_git(root: Path, *args: str) -> str:
    """Execute une commande git et renvoie sa sortie, ou une chaine vide."""
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=str(root),
            capture_output=True,
            text=True,
            check=False,
            encoding="utf-8",
            errors="replace",
        )
    except OSError:
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def tool_version(command: list[str], pattern: str = "") -> str:
    """Recupere la version d'un outil, ou 'non detecte'."""
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            encoding="utf-8",
            errors="replace",
        )
    except OSError:
        return "non detecte"
    sortie = (result.stdout + result.stderr).strip()
    if not sortie:
        return "non detecte"
    if pattern:
        found = re.search(pattern, sortie)
        if found:
            return found.group(0)
    return sortie.splitlines()[0].strip()


def pinned_versions(root: Path) -> dict[str, str]:
    """Lit les versions EPINGLEES dans le Dockerfile du SECI."""
    chemin = root / DOCKERFILE
    if not chemin.is_file():
        return {}
    epingles: dict[str, str] = {}
    motif = re.compile(r"^ARG\s+([A-Z_]+_VERSION)\s*=\s*(\S+)")
    for ligne in chemin.read_text(encoding="utf-8").splitlines():
        found = motif.match(ligne.strip())
        if found:
            epingles[found.group(1)] = found.group(2)
    return epingles


def pinned_arg(root: Path, nom: str) -> str:
    """Lit la valeur d'un ARG donne du Dockerfile du SECI, ou ''."""
    chemin = root / DOCKERFILE
    if not chemin.is_file():
        return ""
    motif = re.compile(rf"^ARG\s+{re.escape(nom)}\s*=\s*(\S+)")
    valeur = ""
    # Docker retient la derniere definition d'un ARG, et en retire les
    # guillemets : faire de meme, sinon l'outil signalerait un faux ecart.
    for ligne in chemin.read_text(encoding="utf-8").splitlines():
        found = motif.match(ligne.strip())
        if found:
            valeur = found.group(1).strip("\"'")
    return valeur


# Les sources apt de l'image : le Dockerfile les reecrit vers l'instantane.
# C'est elles qu'apt lit, donc elles qu'il faut relire.
APT_SOURCES = Path("/etc/apt/sources.list.d/ubuntu.sources")

# Preuve laissee dans l'image par le Dockerfile, apres le `sha256sum -c` de
# l'archive d'Alire : l'empreinte effectivement controlee.
ALIRE_PREUVE = Path("/opt/alire/archive.sha256")


def detected_snapshot() -> str:
    """Rend l'instantane que les sources apt de la machine designent.

    'non detecte' si les sources sont absentes (hors de l'image) ;
    'archive courante' si une source au moins ne designe pas un instantane ;
    'instantanes multiples' si elles en designent plusieurs.
    """
    try:
        texte = APT_SOURCES.read_text(encoding="utf-8")
    except OSError:
        return "non detecte"
    uris = re.findall(r"^URIs:\s*(\S+)", texte, re.MULTILINE)
    if not uris:
        return "non detecte"
    dates = set()
    for uri in uris:
        found = re.match(r"https://snapshot\.ubuntu\.com/ubuntu/(\w+)/?$", uri)
        if not found:
            return "archive courante"
        dates.add(found.group(1))
    return dates.pop() if len(dates) == 1 else "instantanes multiples"


def detected_alire_sha() -> str:
    """Rend l'empreinte d'archive d'Alire controlee a la construction."""
    try:
        return ALIRE_PREUVE.read_text(encoding="utf-8").strip() or "non detecte"
    except OSError:
        return "non detecte"


def base_images(root: Path) -> list[str]:
    """Lit les images de base EXTERNES des lignes FROM du Dockerfile du SECI.

    Les options (`--platform=...`) sont ignorees, ainsi que les references a
    une etape precedente d'une construction multi-etapes (`FROM build`).
    L'instruction n'est reconnue qu'en majuscules, comme ce depot l'ecrit :
    une ligne `from ...` dans un heredoc Python n'est pas un FROM.

    Deux limites, assumees pour un Dockerfile a une seule etape ecrit en
    clair : une instruction `from` en minuscules echappe au controle, et un
    FROM ecrit au travers d'un ARG (`FROM ${BASE}`) est signale meme si
    l'ARG porte un digest, faute de pouvoir le verifier.
    """
    chemin = root / DOCKERFILE
    if not chemin.is_file():
        return []
    etapes: set[str] = set()
    images: list[str] = []
    for ligne in chemin.read_text(encoding="utf-8").splitlines():
        mots = ligne.split()
        if not mots or mots[0] != "FROM":
            continue
        reste = [mot for mot in mots[1:] if not mot.startswith("--")]
        if not reste:
            continue
        if reste[0].lower() not in etapes:
            images.append(reste[0])
        if len(reste) >= 3 and reste[1].upper() == "AS":
            etapes.add(reste[2].lower())
    return images


def tracked_files(root: Path) -> list[str]:
    listing = run_git(root, "ls-files")
    if not listing:
        return []
    fichiers = [line for line in listing.splitlines() if line]
    return [f for f in fichiers if not f.startswith(EXCLUDED_PREFIXES)]


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for bloc in iter(lambda: handle.read(65536), b""):
            digest.update(bloc)
    return digest.hexdigest()


def build_sci(root: Path, part_number: str, version: str) -> str:
    commit = run_git(root, "rev-parse", "HEAD") or "(hors depot Git)"
    commit_court = commit[:12] if commit != "(hors depot Git)" else commit
    branche = run_git(root, "rev-parse", "--abbrev-ref", "HEAD") or "(inconnue)"
    etiquette = (
        run_git(root, "describe", "--tags", "--always", "--dirty") or "(aucune)"
    )
    date_commit = run_git(root, "log", "-1", "--format=%cI") or "(inconnue)"
    modifie = bool(run_git(root, "status", "--porcelain"))
    horodatage = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    fichiers = tracked_files(root)
    lignes: list[str] = []
    empreinte_globale = hashlib.sha256()

    for relatif in sorted(fichiers):
        chemin = root / relatif
        if not chemin.is_file():
            continue
        empreinte = sha256_of(chemin)
        taille = chemin.stat().st_size
        empreinte_globale.update(relatif.encode("utf-8"))
        empreinte_globale.update(empreinte.encode("ascii"))
        lignes.append(f"| `{relatif}` | {taille} | `{empreinte[:16]}…` |")

    out: list[str] = []
    out.append("# SCI — Software Configuration Index")
    out.append("")
    out.append("> Document DO-178C §11.16. Catégorie de contrôle : **CC1** à")
    out.append("> tous les niveaux.")
    out.append("> Généré par `tools/config_index.py`.")
    out.append("> **Ce document doit être relu et approuvé avant baseline.**")
    out.append("")
    out.append("## 1. Identification du produit")
    out.append("")
    out.append("| Élément | Valeur |")
    out.append("|---|---|")
    out.append(f"| Part number | `{part_number}` |")
    out.append(f"| Version | `{version}` |")
    out.append(f"| Commit Git | `{commit}` |")
    out.append(f"| Branche | `{branche}` |")
    out.append(f"| Étiquette | `{etiquette}` |")
    out.append(f"| Date du commit | {date_commit} |")
    etat = "**OUI — NON BASELINABLE**" if modifie else "non"
    out.append(f"| Arbre de travail modifié | {etat} |")
    out.append(
        f"| Empreinte globale (SHA-256) | `{empreinte_globale.hexdigest()}` |"
    )
    out.append(f"| Date de génération | {horodatage} |")
    out.append("")

    if modifie:
        out.append("> **L'arbre de travail contient des modifications non")
        out.append("> validées.** Un SCI ne peut être établi que sur un état")
        out.append("> figé. Validez ou annulez, puis régénérez.")
        out.append("")

    out.append("## 2. Éléments de configuration")
    out.append("")
    out.append(f"{len(lignes)} fichier(s) sous contrôle de configuration.")
    out.append("")
    out.append("| Fichier | Taille (o) | SHA-256 (tronqué) |")
    out.append("|---|---:|---|")
    out.extend(lignes)
    out.append("")
    out.append("## 3. Procédure de reconstruction")
    out.append("")
    out.append("```bash")
    out.append(f"git clone <url-du-depot> && git checkout {commit_court}")
    out.append("```")
    out.append("")
    out.append("```bash")
    out.append("docker build -t do178c-ada:verif .devcontainer")
    out.append("```")
    out.append("")
    out.append("```bash")
    out.append(
        'docker run --rm -v "$PWD:/workspace" do178c-ada:verif ./scripts/verify.sh'
    )
    out.append("```")
    out.append("")
    return "\n".join(out)


def distribution_hote() -> str:
    """Identifie precisement le systeme hote, quelle que soit la plateforme."""
    base = f"{platform.system()} {platform.release()} ({platform.machine()})"

    os_release = Path("/etc/os-release")
    if os_release.is_file():
        try:
            for ligne in os_release.read_text(encoding="utf-8").splitlines():
                if ligne.startswith("PRETTY_NAME="):
                    nom = ligne.split("=", 1)[1].strip().strip('"')
                    return (
                        f"{nom} ({platform.machine()}), "
                        f"noyau {platform.release()}"
                    )
        except OSError:
            pass

    if "microsoft" in platform.release().lower():
        base += " [WSL]"
    return base


# Correspondance entre les ARG du Dockerfile et les outils reellement presents.
CORRESPONDANCE = [
    ("GNAT (gnatmake)", "GNAT_VERSION", ["gnatmake", "--version"], r"\d+\.\d+\.\d+"),
    ("gprbuild", "GPRBUILD_VERSION", ["gprbuild", "--version"], r"\d+\.\d+\.\d+"),
    ("gnatprove", "GNATPROVE_VERSION", ["gnatprove", "--version"], r"\d+\.\d+\.\d+"),
    ("gnatcov", "GNATCOV_VERSION", ["gnatcov", "--version"], r"\d+\.\d+"),
    ("gnatformat", "GNATFORMAT_VERSION", ["gnatformat", "--version"], r"\d+\.\d+"),
]


def majeur_mineur(version: str) -> str:
    """Reduit une version a `majeur.mineur`.

    La colonne « epingle » du SECI est une version de CRATE ALIRE ; la
    colonne « detecte » est la version que l'outil declare lui-meme. Les deux
    ne coincident pas toujours au niveau du correctif : gprbuild s'annonce
    26.0.0 alors que la crate qui l'installe est 26.0.1. Comparer au niveau
    majeur.mineur evite de crier a l'ecart pour cette raison-la, sans rien
    perdre de ce qu'un vrai ecart de configuration produirait.
    """
    morceaux = version.split(".")
    return ".".join(morceaux[:2])


def build_seci(root: Path) -> str:
    epingles = pinned_versions(root)
    images = base_images(root)
    ecarts: list[str] = []

    lignes: list[str] = []
    for nom, arg, commande, motif in CORRESPONDANCE:
        attendu = epingles.get(arg, "(non épinglé)")
        detecte = tool_version(commande, motif)
        if (
            attendu != "(non épinglé)"
            and detecte != "non detecte"
            and majeur_mineur(attendu) != majeur_mineur(detecte)
        ):
            ecarts.append(f"{nom} : épinglé `{attendu}`, détecté `{detecte}`")
        lignes.append(f"| {nom} | `{attendu}` | `{detecte}` |")

    out: list[str] = []
    out.append("# SECI — Software Life Cycle Environment Configuration Index")
    out.append("")
    out.append("> Document DO-178C §11.15. Catégorie de contrôle : **CC1** aux")
    out.append("> niveaux A à C, CC2 au niveau D (table A-8). Généré par")
    out.append("> `tools/config_index.py`.")
    out.append("")
    out.append("## 1. Environnement de production et de vérification")
    out.append("")
    out.append(f"Système hôte : `{distribution_hote()}`")
    out.append("")
    if len(images) == 1:
        out.append(f"Image de base (déclarée dans le Dockerfile) : `{images[0]}`")
    else:
        out.append("Images de base (déclarées dans le Dockerfile) :")
        out.extend(f"- `{image}`" for image in images)
        if not images:
            out.append("- (aucune ligne FROM trouvée)")
    out.append("")
    snapshot = pinned_arg(root, "UBUNTU_SNAPSHOT")
    alire_sha = pinned_arg(root, "ALIRE_SHA256")
    non_epingles: list[str] = []
    if not snapshot:
        non_epingles.append("les paquets apt (aucun `ARG UBUNTU_SNAPSHOT`)")
    if not alire_sha:
        non_epingles.append("l'archive d'Alire (aucun `ARG ALIRE_SHA256`)")
    if non_epingles:
        out.append("> **NON ÉPINGLÉ** : " + " ; ".join(non_epingles) + ".")
        out.append("> Ce que l'image contient peut alors changer sans que le dépôt")
        out.append("> change. Voir [`docs/03-outils.md`](../docs/03-outils.md) §5.")
        out.append("")
    # Dans l'image — les outils Ada y sont detectes —, un epinglage declare
    # mais absent de la machine est un ecart, pas un silence : c'est le cas
    # d'une image construite avant l'epinglage, ou d'une source modifiee.
    dans_image = not any("non detecte" in ligne for ligne in lignes)
    snapshot_detecte = detected_snapshot()
    if snapshot and snapshot_detecte != snapshot and (
        dans_image or snapshot_detecte != "non detecte"
    ):
        ecarts.append(
            f"instantané apt : épinglé `{snapshot}`, détecté `{snapshot_detecte}`"
        )
    alire_detecte = detected_alire_sha()
    if alire_sha and alire_detecte != alire_sha and (
        dans_image or alire_detecte != "non detecte"
    ):
        ecarts.append(
            f"archive d'Alire : empreinte épinglée `{alire_sha[:16]}…`, "
            f"contrôlée `{alire_detecte[:16]}`"
        )
    sans_digest = [image for image in images if "@sha256:" not in image]
    if sans_digest or not images:
        out.append("> **IMAGE DE BASE NON ÉPINGLÉE PAR DIGEST** : "
                   + (", ".join(f"`{image}`" for image in sans_digest)
                      or "aucune image trouvée") + ".")
        out.append("> Une étiquette d'image est un nom, que l'éditeur repose sur")
        out.append("> une autre image à chaque rafraîchissement : le SECI peut")
        out.append("> alors changer sans que le dépôt change. Épinglez")
        out.append("> `FROM <image>:<étiquette>@sha256:<digest>`.")
        out.append("")
    out.append(
        "La colonne « épinglé » vient des `ARG` de "
        "[`.devcontainer/Dockerfile`](../.devcontainer/Dockerfile), qui **est**"
    )
    out.append(
        "le SECI de ce dépôt. La colonne « détecté » vient de la machine où "
        "ce document a été généré."
    )
    out.append("")
    out.append(
        "La comparaison porte sur `majeur.mineur` : la colonne « épinglé » "
        "est une version de **crate Alire**, la colonne « détecté » est la "
    )
    out.append(
        "version que l'outil déclare lui-même, et les deux ne coïncident pas "
        "toujours au niveau du correctif — gprbuild s'annonce 26.0.0 alors "
    )
    out.append("que la crate qui l'installe est 26.0.1.")
    out.append("")
    out.append("| Outil | Épinglé | Détecté |")
    out.append("|---|---|---|")
    out.extend(lignes)
    out.append(f"| Alire (`alr`) | `{epingles.get('ALIRE_VERSION', '?')}` | — |")
    out.append(
        f"| Archive d'Alire (SHA-256) | "
        f"`{alire_sha[:16] + '…' if alire_sha else '(non épinglé)'}` | "
        f"`{alire_detecte[:16] + '…' if alire_detecte != 'non detecte' else alire_detecte}` |"
    )
    out.append(
        f"| Archive Ubuntu (instantané apt) | "
        f"`{snapshot or '(non épinglé)'}` | `{snapshot_detecte}` |"
    )
    out.append(f"| Python | — | `{platform.python_version()}` |")
    git_version = tool_version(["git", "--version"], r"\d+\.\d+\.\d+[\w.-]*")
    out.append(f"| Git | — | `{git_version}` |")
    out.append("")

    if ecarts:
        out.append("> **ÉCART DÉTECTÉ entre l'épinglage et la machine.**")
        out.append(">")
        for ecart in ecarts:
            out.append(f"> - {ecart}")
        out.append(">")
        out.append("> Un SECI qui annonce une version que la machine n'a pas")
        out.append("> est un SECI faux, et un SECI faux est pire que pas de")
        out.append("> SECI du tout. Régénérez depuis l'image du dépôt.")
        out.append("")
    elif any("non detecte" in ligne for ligne in lignes):
        out.append("> Certains outils n'ont pas été détectés : ce document a")
        out.append("> probablement été généré **hors** de l'image. Il ne")
        out.append("> décrit alors pas l'environnement qui produit le binaire.")
        out.append("")
    elif non_epingles or sans_digest or not images:
        out.append("> Pas d'écart de version, mais l'épinglage est incomplet :")
        out.append("> voir plus haut. Ce SECI ne peut pas se dire conforme.")
        out.append("")
    else:
        out.append("> Aucun écart : la machine correspond à l'épinglage.")
        out.append("")

    out.append("### Construction de l'image")
    out.append("")
    out.append("Ces éléments CONSTRUISENT l'image sans en faire partie, et ne sont")
    out.append("pas épinglés. L'image du runner ne peut pas l'être — c'est aussi")
    out.append("son noyau qui exécute la vérification, voir « Système hôte ».")
    out.append("buildx en vient, et BuildKit est tiré par une étiquette mouvante :")
    out.append("les figer dans le workflow créerait des versions que Dependabot ne")
    out.append("suit pas. Ils sont donc **tracés**, à chaque génération.")
    out.append("")
    out.append("| Élément | Version |")
    out.append("|---|---|")
    manquants: list[str] = []
    for nom, variable in (
        ("Image du runner", "SECI_RUNNER"),
        ("buildx", "SECI_BUILDX"),
        ("BuildKit", "SECI_BUILDKIT"),
    ):
        valeur = os.environ.get(variable, "").strip()
        if not valeur:
            manquants.append(nom)
        out.append(f"| {nom} | `{valeur or 'non renseigné'}` |")
    out.append("")
    if os.environ.get("GITHUB_ACTIONS") != "true":
        out.append("> Document généré hors de la CI, qui seule transmet ces")
        out.append("> versions (`SECI_*`).")
        out.append("")
    elif manquants:
        out.append(f"> **VALEUR MANQUANTE EN CI** : {', '.join(manquants)}. L'étape")
        out.append("> « Identifier l'environnement » aurait dû échouer : ce SECI")
        out.append("> est incomplet.")
        out.append("")

    out.append("## 2. Options de compilation")
    out.append("")
    out.append("Définies une seule fois, dans [`shared.gpr`](../shared.gpr) :")
    out.append("")
    out.append("| Option | Rôle |")
    out.append("|---|---|")
    out.append("| `-gnat2022` | norme du langage |")
    out.append("| `-gnatW8` | sources en UTF-8 |")
    out.append("| `-gnata` | assertions et contrats actifs |")
    out.append("| `-gnatwa` | tous les avertissements utiles |")
    out.append("| `-gnatwe` | avertissements traités en erreurs |")
    out.append("| `-gnatyy` | vérificateur de style GNAT |")
    out.append("| `-gnatf` | diagnostics complets |")
    out.append("")
    out.append("Et pour la preuve :")
    out.append("")
    out.append("| Option | Rôle |")
    out.append("|---|---|")
    out.append("| `--level=2` | niveau d'effort des prouveurs |")
    out.append("| `--checks-as-errors=on` | une vérification non prouvée échoue |")
    out.append("")
    out.append("## 3. Outils de vérification et statut DO-330")
    out.append("")
    out.append("| Outil | Rôle | Qualification |")
    out.append("|---|---|---|")
    out.append(
        "| `common/src/testing.ads` | harnais de test | non requise — "
        "utilisé en complément de la revue |"
    )
    out.append(
        "| `gnatprove` | preuve formelle | **critère 2 si la preuve "
        "remplace des tests** (DO-333) : TQL-4 au DAL B |"
    )
    out.append(
        "| `gnatcov` | couverture structurelle | **critère 3** : TQL-5 à "
        "tout DAL — kit de qualification existant |"
    )
    out.append(
        "| `gnatformat` | formatage | non requise — vérifie, ne corrige pas "
        "en CI |"
    )
    out.append(
        "| `tools/trace_check.py` | matrice de traçabilité | non requise — "
        "complète la revue manuelle |"
    )
    out.append(
        "| `tools/config_index.py` | génération SCI/SECI | non requise — "
        "produit une donnée, relue |"
    )
    out.append("")
    out.append("> Cette dernière colonne est le cœur de la DO-330 : la question")
    out.append("> n'est jamais « l'outil est-il bon ? » mais « son résultat")
    out.append("> remplace-t-il une activité que la norme exige ? ».")
    out.append("")
    return "\n".join(out)


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

    parser = argparse.ArgumentParser(
        description="Genere le SCI et le SECI du depot."
    )
    parser.add_argument("--root", default=".", help="racine du depot")
    parser.add_argument("--output", default="reports", help="repertoire de sortie")
    parser.add_argument("--part-number", default="PN-7654321-001")
    parser.add_argument("--version", default="1.0.0")
    parser.add_argument(
        "--print", action="store_true", help="affiche le SCI sur la sortie"
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not (root / "modules").is_dir():
        print(f"ERREUR : {root} ne ressemble pas a la racine du depot.")
        return 2

    # Sans un depot Git lisible, pas de SCI. Que git refuse le depot --
    # typiquement un montage de conteneur dont le proprietaire n'est pas
    # l'utilisateur courant -- ou qu'il n'y ait pas de depot du tout -- une
    # archive ZIP telechargee --, le document dirait « 0 fichier » et « arbre
    # de travail modifie : non » : une donnee CC1 fausse sous une apparence
    # normale. Mieux vaut aucun document qu'un document qui ment.
    if not run_git(root, "rev-parse", "HEAD"):
        if (root / ".git").exists():
            conseil = (
                "git refuse de lire le depot. Dans un conteneur, le declarer "
                f"sur :\n  git config --global --add safe.directory {root}"
            )
        else:
            conseil = (
                "ce n'est pas un depot Git. Un SCI identifie un etat du "
                "depot : cloner plutot que telecharger une archive."
            )
        print(f"ERREUR : le SCI serait faux, {conseil}", file=sys.stderr)
        return 3

    sci = build_sci(root, args.part_number, args.version)
    seci = build_seci(root)

    sortie = Path(args.output)
    if not sortie.is_absolute():
        sortie = root / sortie
    sortie.mkdir(parents=True, exist_ok=True)

    (sortie / "SCI.md").write_text(sci, encoding="utf-8")
    (sortie / "SECI.md").write_text(seci, encoding="utf-8")

    if args.print:
        print(sci)
        print()
        print(seci)

    print(f"SCI  ecrit dans {sortie / 'SCI.md'}")
    print(f"SECI ecrit dans {sortie / 'SECI.md'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# ---------------------------------------------------------------------------
# SECI exécutable — Software Life Cycle Environment Configuration Index,
# DO-178C §11.15. Une donnée de vie doit dire *exactement* avec quoi le
# logiciel a été construit et vérifié. Un fichier qui l'affirme se périme ;
# une image qui le reconstruit se vérifie. D'où ce Dockerfile.
#
# Ce que l'image contient est épinglé ci-dessous : l'image de base par son
# digest, les paquets apt par un instantané daté de l'archive Ubuntu,
# l'archive d'Alire par son empreinte SHA-256, la chaîne Ada par les versions
# de crates Alire, dont l'index communautaire consigne les empreintes. En
# changer un est une modification de configuration, qui se commite seule, se
# justifie, et se paie d'une vérification complète.
#
# Une réserve, dite plutôt que tue : cet index est suivi en tête de sa
# branche stable-1.4.0, sans commit épinglé. Ses manifestes publiés sont
# immuables par la politique de l'index, pas par construction.
# ---------------------------------------------------------------------------

# L'image de base est épinglée par DIGEST — l'empreinte SHA-256 de l'image —
# et pas seulement par étiquette. Une étiquette est un nom, que l'éditeur
# repose sur une nouvelle image à chaque rafraîchissement : entre le 28 août
# et le 2 octobre 2026, la CI de ce dépôt a construit sur trois images de
# base différentes sans qu'aucune ligne du dépôt ne change.
#
# L'étiquette retenue est le NOM DE CODE `resolute`, c'est-à-dire Ubuntu
# 26.04 LTS, et non `26.04`. Les deux désignent la même image, mais
# Dependabot ne les traite pas pareil. Sur une étiquette versionnée, une
# option de son serveur peut supprimer les propositions de nouveau digest
# (docker_digest_only_update_suppression, dependabot-core#15103) ; un nom de
# code en est exempté, et ne peut pas non plus glisser vers une version non
# LTS. À chaque passage mensuel, Dependabot propose donc le digest courant
# de `resolute` : la dérive silencieuse devient une proposition relue.
FROM ubuntu:resolute@sha256:3595d7fc4286a33fad0fd853a4063e654287a9c3787437d7937c94ca3f7a804e

# Alire est le gestionnaire de paquets d'Ada. On prend le binaire amont et non
# le paquet `alire` de l'univers Ubuntu (1.2.1) : cette version-là est bloquée
# sur l'index figé `stable-1.2.1` de 2023, où gnatprove plafonne à 13.2.1.
ARG ALIRE_VERSION=2.1.1
ARG GNAT_VERSION=16.1.0
ARG GPRBUILD_VERSION=26.0.1
ARG GNATPROVE_VERSION=16.1.0
ARG GNATCOV_VERSION=26.2.1
ARG GNATFORMAT_VERSION=26.0.0

# Empreinte de l'archive d'Alire. Un numéro de version n'est qu'un nom : une
# archive remplacée sous le même nom passerait. Valeur relevée le 2 octobre
# 2026, identique à l'empreinte que GitHub publie pour cet asset de la
# release v2.1.1 (12 800 698 octets).
ARG ALIRE_SHA256=09c66bcd8c35dd4b97b72c3d9b76e44caa6964a2db35aba069f396f00f1f64c7

# Instantané de l'archive Ubuntu (snapshot.ubuntu.com) : `apt-get install`
# rend alors les mêmes versions quel que soit le jour de la construction.
# Sans lui, sept paquets ont changé de version entre les constructions du 19
# septembre et du 2 octobre 2026 sans qu'une ligne du dépôt change. La date
# doit être postérieure à celle de l'image de base, avancer avec elle, et
# rester dans le passé : snapshot.ubuntu.com accepte une date future et sert
# alors l'état courant de l'archive. Dependabot ne la suit pas, c'est un
# point de revue manuel (voir .github/dependabot.yml).
ARG UBUNTU_SNAPSHOT=20261002T000000Z

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Préfixe unique pour toute la chaîne Ada. Installer sous /opt plutôt que dans
# le $HOME de root est ce qui rend les outils utilisables par l'utilisateur
# non privilégié qui travaillera dans le conteneur.
ENV ADA_PREFIX=/opt/ada
ENV PATH=${ADA_PREFIX}/bin:${PATH}
ENV GPR_PROJECT_PATH=${ADA_PREFIX}/share/gpr
ENV LD_LIBRARY_PATH=${ADA_PREFIX}/lib

# Ce RUN répond à trois difficultés, vérifiées en le construisant :
#
#  * Les sources de l'image sont RÉÉCRITES vers l'instantané, plutôt que
#    d'utiliser l'option APT::Snapshot : celle-ci laisse apt télécharger en
#    plus les index de l'archive courante, et la construction dépendrait
#    encore d'archive.ubuntu.com. Le contrôle qui suit le sed vérifie
#    qu'aucune source courante ne subsiste.
#  * Un instantané injoignable laisse `apt-get update` réussir (code 0, de
#    simples avertissements), et l'échec n'apparaît qu'à l'installation, sous
#    un message trompeur. `--error-on=any` le fait échouer au bon endroit.
#  * snapshot.ubuntu.com n'est servi qu'en HTTPS, et l'image de base n'a pas
#    de certificats racines. Un premier `update` se fait donc sans vérifier le
#    pair TLS, le temps d'installer ca-certificates. La signature GPG de
#    l'archive, vérifiée par apt, garantit l'authenticité de ce qui est
#    reçu — pas la date de l'instantané : un intermédiaire pourrait servir un
#    autre instantané, authentique lui aussi. D'où le RÉALIGNEMENT : après
#    l'`update` vérifié, tout ce que l'amorçage a installé ou modifié est
#    réinstallé à la version de l'instantané épinglé. Ce qui reste de
#    l'amorçage dans l'image ne dépend plus de ce qui a été servi.
RUN case "${UBUNTU_SNAPSHOT}" in \
      [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z) ;; \
      *) echo "UBUNTU_SNAPSHOT mal formé : '${UBUNTU_SNAPSHOT}'" >&2; exit 1 ;; \
    esac \
 && { [ "$(date -u +%Y%m%d%H%M%S)" -gt "$(echo "${UBUNTU_SNAPSHOT}" | tr -d TZ)" ] \
      || { echo "UBUNTU_SNAPSHOT est dans le futur : l'archive servirait son état courant" >&2; exit 1; }; } \
 && sed -i -E "s#^URIs: http://(archive|security)\.ubuntu\.com/ubuntu/?\$#URIs: https://snapshot.ubuntu.com/ubuntu/${UBUNTU_SNAPSHOT}/#" \
      /etc/apt/sources.list.d/ubuntu.sources \
 && ! grep -q -E '^URIs: .*(archive|security)\.ubuntu\.com' /etc/apt/sources.list.d/ubuntu.sources \
 && dpkg-query -W -f='${Package} ${Version}\n' | sort > /tmp/avant \
 && apt-get update --error-on=any \
      -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false \
 && apt-get install -y --no-install-recommends \
      -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false \
      ca-certificates \
 && apt-get update --error-on=any \
 && dpkg-query -W -f='${Package} ${Version}\n' | sort > /tmp/apres \
 && REALIGNER=$(comm -13 /tmp/avant /tmp/apres | while read -r p v; do \
      echo "$p=$(apt-cache policy "$p" | sed -n 's/^  Candidate: //p')"; done) \
 && apt-get install -y --no-install-recommends --allow-downgrades ${REALIGNER} \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git python3 sudo unzip \
 && rm -rf /var/lib/apt/lists/* /tmp/avant /tmp/apres

# Alire lui-même : décompressé à part, il ne sert qu'à installer le reste.
RUN curl -fsSL -o /tmp/alr.zip \
      "https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/alr-${ALIRE_VERSION}-bin-x86_64-linux.zip" \
 && echo "${ALIRE_SHA256}  /tmp/alr.zip" | sha256sum -c - \
 && unzip -q /tmp/alr.zip -d /opt/alire \
 && echo "${ALIRE_SHA256}" > /opt/alire/archive.sha256 \
 && rm /tmp/alr.zip \
 && /opt/alire/bin/alr version

# Compilateur et constructeur. `alr install --prefix` dépose gcc/gnatmake/
# gprbuild dans un préfixe partagé, contrairement à `alr toolchain --select`
# qui les enferme dans le cache du seul utilisateur qui a lancé la commande.
RUN /opt/alire/bin/alr -n install --prefix=${ADA_PREFIX} \
      "gnat_native=${GNAT_VERSION}" \
      "gprbuild=${GPRBUILD_VERSION}"

# Outils de vérification : preuve SPARK, couverture, formatage.
RUN /opt/alire/bin/alr -n install --prefix=${ADA_PREFIX} \
      "gnatprove=${GNATPROVE_VERSION}" \
      "gnatcov_bin=${GNATCOV_VERSION}" \
      "gnatformat_bin=${GNATFORMAT_VERSION}"

# Bibliothèque d'exécution de GNATcoverage. Sans elle, `gnatcov instrument`
# produit du code qui ne s'édite pas : la couverture par instrumentation de
# source est le seul chemin vers le MC/DC ici.
RUN gnatcov setup --prefix=${ADA_PREFIX} \
 && chmod -R a+rX ${ADA_PREFIX}

# L'image Ubuntu 26.04 fournit déjà l'utilisateur `ubuntu` en uid 1000.
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
 && chmod 0440 /etc/sudoers.d/ubuntu
USER ubuntu
WORKDIR /workspace

# ---------------------------------------------------------------------------
# SECI exécutable — Software Life Cycle Environment Configuration Index,
# DO-178C §11.15. Une donnée de vie doit dire *exactement* avec quoi le
# logiciel a été construit et vérifié. Un fichier qui l'affirme se périme ;
# une image qui le reconstruit se vérifie. D'où ce Dockerfile.
#
# Toute version ci-dessous est épinglée. En changer une est une modification
# de configuration, qui se commite seule et se justifie.
# ---------------------------------------------------------------------------
FROM ubuntu:26.04

# Alire est le gestionnaire de paquets d'Ada. On prend le binaire amont et non
# le paquet `alire` de l'univers Ubuntu (1.2.1) : cette version-là est bloquée
# sur l'index figé `stable-1.2.1` de 2023, où gnatprove plafonne à 13.2.1.
ARG ALIRE_VERSION=2.1.1
ARG GNAT_VERSION=16.1.0
ARG GPRBUILD_VERSION=26.0.1
ARG GNATPROVE_VERSION=16.1.0
ARG GNATCOV_VERSION=26.2.1
ARG GNATFORMAT_VERSION=26.0.0

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Préfixe unique pour toute la chaîne Ada. Installer sous /opt plutôt que dans
# le $HOME de root est ce qui rend les outils utilisables par l'utilisateur
# non privilégié qui travaillera dans le conteneur.
ENV ADA_PREFIX=/opt/ada
ENV PATH=${ADA_PREFIX}/bin:${PATH}
ENV GPR_PROJECT_PATH=${ADA_PREFIX}/share/gpr
ENV LD_LIBRARY_PATH=${ADA_PREFIX}/lib

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git python3 sudo unzip \
 && rm -rf /var/lib/apt/lists/*

# Alire lui-même : décompressé à part, il ne sert qu'à installer le reste.
RUN curl -fsSL -o /tmp/alr.zip \
      "https://github.com/alire-project/alire/releases/download/v${ALIRE_VERSION}/alr-${ALIRE_VERSION}-bin-x86_64-linux.zip" \
 && unzip -q /tmp/alr.zip -d /opt/alire \
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

# ubuntu:26.04 fournit déjà l'utilisateur `ubuntu` en uid 1000.
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
 && chmod 0440 /etc/sudoers.d/ubuntu
USER ubuntu
WORKDIR /workspace

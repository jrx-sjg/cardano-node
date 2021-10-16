FROM debian as stage1

ENV \
DEBIAN_FRONTEND=noninteractive \
LANG=C.UTF-8 \
ENV=/etc/profile \
USER=root 

WORKDIR /

RUN set -x && apt-get update \
  && mkdir -p /root/.cabal/bin && mkdir -p /root/.ghcup/bin \
  && apt-get install -y  apt-utils wget gnupg apt-utils git\
  && wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/prereqs.sh \
  && export SUDO='N' \
  && export UPDATE_CHECK='N' \
  && export BOOTSTRAP_HASKELL_NO_UPGRADE=1 \
  && chmod +x ./prereqs.sh &&  ./prereqs.sh 

## Stage 2

FROM stage1 as stage2

FROM debian:stable-slim

LABEL org.opencontainers.image.source https://github.com/jrx-sjg/cardano-node

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /

ENV \
    ENV=/etc/profile \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    CNODE_HOME=/opt/cardano/cnode \
    CARDANO_NODE_SOCKET_PATH=$CNODE_HOME/sockets/node0.socket \
    PATH=/nix/var/nix/profiles/per-user/guild/profile/bin:/nix/var/nix/profiles/per-user/guild/profile/sbin:/opt/cardano/cnode/scripts:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/guild/.cabal/bin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/guild/channels

# COPY NODE BINS AND DEPS 
COPY src/bin/* /home/guild/.cabal/bin/
COPY configuration/cardano/mainnet-*-genesis.json $CNODE_HOME/priv/files/

RUN chmod a+x /home/guild/.cabal/bin/* && ls /opt/

# Install locales package
RUN apt-get update && apt-get install --no-install-recommends -y locales apt-utils

#  en_US.UTF-8 for inclusion in generation
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANG=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc

# PREREQ
RUN apt-get update && apt-get install -y libcap2 libselinux1 libc6 libsodium-dev ncurses-bin iproute2 curl wget apt-utils xz-utils netbase sudo coreutils dnsutils net-tools procps tcptraceroute bc usbip \
    && apt-get install -y --no-install-recommends cron \
    && sudo apt-get -y purge && sudo apt-get -y clean && sudo apt-get -y autoremove && sudo rm -rf /var/lib/apt/lists/* # && sudo rm -rf /usr/bin/apt*

RUN cd /usr/bin \
    && sudo wget http://www.vdberg.org/~richard/tcpping \
    && sudo chmod 755 tcpping

# SETUP Guild USER
RUN adduser --disabled-password --gecos '' guild \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && adduser guild sudo \
    && chown -R guild:guild /home/guild/.*

USER guild
WORKDIR /home/guild

# Commit Version 
RUN  curl -sL -H "Accept: application/vnd.github.everest-preview+json" -H "Content-Type: application/json" https://api.github.com/repos/cardano-community/guild-operators/commits | grep -v md | grep -A 2 prereqs.sh | grep sha | head -n 1 | cut -d "\"" -f 4 > ~/guild-latest.txt

# INSTALL NIX
RUN sudo curl -sL https://nixos.org/nix/install | sh \
    && sudo ln -s /nix/var/nix/profiles/per-user/etc/profile.d/nix.sh /etc/profile.d/ \
    && . /home/guild/.nix-profile/etc/profile.d/nix.sh \
    && echo "head -n 8 /home/guild/.scripts/banner.txt" >> ~/.bashrc \
    && echo "grep MENU -A 6 /home/guild/.scripts/banner.txt | grep -v MENU" >> ~/.bashrc \
    && echo "alias env=/usr/bin/env" >> ~/.bashrc \
    && echo "alias cntools=$CNODE_HOME/scripts/cntools.sh" >> ~/.bashrc \
    && echo "alias gLiveView=$CNODE_HOME/scripts/gLiveView.sh" >> ~/.bashrc \
    && echo "alias cncli=$CNODE_HOME/scripts/cncli.sh" >> ~/.bashrc \
    && echo "export PATH=/nix/var/nix/profiles/per-user/guild/profile/bin:/nix/var/nix/profiles/per-user/guild/profile/sbin:/opt/cardano/cnode/scripts:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/guild/.cabal/bin"  >> ~/.bashrc

# INSTALL DEPS  
RUN /nix/var/nix/profiles/per-user/guild/profile/bin/nix-env -i python3 systemd libsodium tmux jq ncurses libtool autoconf git wget gnupg tcptraceroute util-linux less openssl \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-channel --update \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-env -u --always \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-collect-garbage -d \
    && sudo rm /nix/var/nix/profiles/per-user/guild/profile/bin/nix-*

# ENTRY SCRIPT

ADD ./docker/node/addons/banner.txt /home/guild/.scripts/
ADD https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/addons/guild-topology.sh /home/guild/.scripts/
ADD https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/addons/block_watcher.sh /home/guild/.scripts/
ADD https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/addons/healthcheck.sh /home/guild/.scripts/
ADD https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/prereqs.sh /opt/cardano/cnode/scripts/
ADD https://raw.githubusercontent.com/cardano-community/guild-operators/master/files/docker/node/addons/entrypoint.sh ./

RUN sudo chown -R guild:guild $CNODE_HOME/* \
    && sudo chown -R guild:guild /home/guild/.* \
    && sudo chmod a+x /home/guild/.scripts/*.sh /opt/cardano/cnode/scripts/*.sh /home/guild/entrypoint.sh 

HEALTHCHECK --start-period=5m --interval=5m --timeout=100s CMD /home/guild/.scripts/healthcheck.sh

ENTRYPOINT ["./entrypoint.sh"]

# this image could definitely be smaller and build faster, but lets just get it working
FROM gitlab.stytt.com:5001/docker/python3/ubuntu-s6

RUN docker-install \
    autoconf \
    automake \
    build-essential \
    bzip2 \
    curl \
    ca-certificates \
    dirmngr \
    gcc \
    git \
    gnupg2 \
    libffi-dev \
    libsecp256k1-dev \
    libssl-dev \
    libtool \
    make \
    # netbase for cachix use
    netbase \
    pkg-config \
    python3-dev \
    # sudo for nix installer
    sudo \
;

# install node for terra, etherdelta-client (and probably other scripts)
ENV NODE_GPG 9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280
RUN { set -eux; \
    \
    cd /tmp; \
    export GNUPGHOME="$(mktemp -d -p /tmp)"; \
    \
    VERSION=node_10.x; \
    DISTRO=$(cat /etc/*-release | grep -oP 'CODENAME=\K\w+$' | head -1); \
    echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" > /etc/apt/sources.list.d/nodesource.list; \
    echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" >> /etc/apt/sources.list.d/nodesource.list; \
    \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$NODE_GPG"; \
    docker-install nodejs; \
    \
    rm -rf /tmp/*; \
}

# create groups and build users for nix. i don't love doing this is the main image, but we can optimize later
RUN { set -eux; \
    \
    groupadd -r nixbld; \
    for n in $(seq 1 10); do \
      useradd -c "Nix build user $n" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(which nologin)" "nixbld$n"; \
    done; \
}

# this is needed by nix installer and /root/.nix-profile/etc/profile.d/nix.sh
ENV USER root

ENV NIX_GPG B541D55301270E0BCF15CA5D8170B4726D7198DE
ENV NIX_VERSION 2.1.1
RUN { set -eux; \
    \
    cd /tmp; \
    export GNUPGHOME="$(mktemp -d -p /tmp)"; \
    \
    curl -o "install-nix-${NIX_VERSION}" https://nixos.org/nix/install; \
    curl -o "install-nix-${NIX_VERSION}.sig" https://nixos.org/nix/install.sig; \
    gpg2 --keyserver keyserver.ubuntu.com --recv-keys $NIX_GPG; \
    gpg2 --verify ./install-nix-${NIX_VERSION}.sig; \
    sh ./install-nix-${NIX_VERSION}; \
    \
    rm -rf /tmp/*; \
}

# install cachix since building things from source can take a long time
RUN { set -eux; \
    \
    export MANPATH=""; \
    . /root/.nix-profile/etc/profile.d/nix.sh; \
    \
    nix-env -iA cachix -f https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148; \
}

RUN { set -eux; \
    \
    export GNUPGHOME="$(mktemp -d -p /tmp)"; \
    export MANPATH=""; \
    . /root/.nix-profile/etc/profile.d/nix.sh; \
    \
    nix-channel --add https://nix.dapphub.com/pkgs/dapphub; \
    nix-channel --update; \
    # install binaries instead of building from source (which takes a very long time)
    cachix use dapp; \
    # install pinned versions
    nix-env -iA dapphub.{dapp-0.9.0,ethsign-0.10,hevm-0.15,seth-0.6.3,solc-0.4.24,token-0.5.1}; \
    \
    # https://github.com/makerdao/setzer - price feeds for market-maker-keeper
    # https://github.com/makerdao/mcd-cli - makerdao command line interface
    dapp pkg install dai-cli; \
    dapp pkg install setzer; \
    dapp pkg install terra; \
    dapp pkg install mcd; \
    \
    rm -rf /tmp/*; \
}

# https://github.com/makerdao/tx-manager
RUN { set -eux; \
    \
    git clone https://github.com/makerdao/tx-manager /opt/contracts/tx-manager; \
    cd /opt/contracts/tx-manager; \
    git reset --hard 754a6da46d25862983ebf2c19eb70632b46896f5; \
    git submodule update --init --recursive; \
}

# TODO: copy /rootfs/bin/makerdao-installer script?
COPY /rootfs/bin/makerdao-installer /bin/
COPY /rootfs/bin/makerdao-helper /bin/

# TODO: i don't love having all these installs in one RUN, but they share a lot of cache
RUN { set -eux; \
    \
    export PIPCACHE="$(chroot --userspec=abc / mktemp -d -p /tmp)"; \
    \
    # https://github.com/makerdao/plunger
    makerdao-installer plunger 38e7a362109296f84fd33265af84013c6dadcc62; \
    makerdao-helper plunger --help; \
    \
    \
    # https://github.com/makerdao/arbitrage-keeper
    makerdao-installer arbitrage-keeper 0679f30335ac48b96f5e60550c6a49e46612be8a; \
    makerdao-helper arbitrage-keeper --help; \
    \
    \
    # https://github.com/makerdao/auction-keeper
    makerdao-installer auction-keeper 19cda06d5bbc9d61e01979f3c40e6bafd9d8b570; \
    makerdao-helper auction-keeper --help; \
    \
    \
    # https://github.com/makerdao/bite-keeper
    makerdao-installer bite-keeper e606456115cab88636a88a1ff403a81dd80cca77; \
    makerdao-helper bite-keeper --help; \
    \
    \
    # https://github.com/makerdao/cdp-keeper
    makerdao-installer cdp-keeper 4396f0483b4109701cc292dc175360b8a0f00e3e; \
    makerdao-helper cdp-keeper --help; \
    \
    \
    # https://github.com/makerdao/market-maker-keeper (and etherdelta-client)
    makerdao-installer market-maker-keeper 3f0b2016f186c6c53651143db1e3a2ea6574526d; \
    # TODO: run help for all the -keeper and -cancel and any other scripts
    APP="market-maker-keeper" makerdao-helper oasis-market-maker-keeper --help; \
    \
    # etherdelta-client for placing orders on EtherDelta using socket.io
    cd /opt/market-maker-keeper/src/lib/pymaker/utils/etherdelta-client; \
    npm install; \
    \
    rm -rf /tmp/*; \
}

COPY rootfs/ /

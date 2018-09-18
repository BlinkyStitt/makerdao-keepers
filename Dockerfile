FROM gitlab.stytt.com:5001/docker/linux-nix/ubuntu as nix

# this image could definitely be smaller and build faster, but lets just get it working
FROM gitlab.stytt.com:5001/docker/python3/ubuntu-s6

# TODO: i think some of these (sudo for sure) can be removed now that nix stuff is in it's own
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
    libffi-dev \
    libsecp256k1-dev \
    libssl-dev \
    libtool \
    make \
    pkg-config \
    python3-dev \
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

COPY --from=nix /root/.nix-profile /root/.nix-profile
COPY --from=nix /nix /nix
COPY --from=nix /root/.profile /root/.profile

# this is needed by /root/.nix-profile/etc/profile.d/nix.sh
ENV USER root

# we could use `nix-channel --add https://nix.dapphub.com/pkgs/dapphub`, but we want dai-cli, setzer, and terra clones
RUN { set -eux; \
    \
    export GNUPGHOME="$(mktemp -d -p /tmp)"; \
    export MANPATH=""; \
    . /root/.nix-profile/etc/profile.d/nix.sh; \
    \
    # install binaries instead of building from source (which takes a very long time)
    cachix use dapp; \
    # dapp, seth, solc, hevm, ethsign (and also jshon)
    # TODO: clone a specific hash here
    git clone --depth 1 --recursive https://github.com/dapphub/dapptools $HOME/.dapp/dapptools; \
    nix-env -f $HOME/.dapp/dapptools -iA dapp ethsign hevm jshon seth solc token ; \
    \
    # dai
    cd "$HOME/.dapp/dapptools/submodules/dai-cli"; \
    make link; \
    \
    # setzer for price feeds for market-maker-keeper
    cd "$HOME/.dapp/dapptools/submodules/setzer"; \
    make link; \
    \
    # terra
    cd "$HOME/.dapp/dapptools/submodules/terra"; \
    npm install; \
    make link; \
    \
    # https://github.com/makerdao/mcd-cli - makerdao command line interface
    dapp pkg install mcd; \
    \
    rm -rf /tmp/*; \
}

# https://github.com/makerdao/tx-manager
RUN { set -eux; \
    \
    git clone --depth 1 https://github.com/makerdao/tx-manager /opt/contracts/tx-manager; \
    cd /opt/contracts/tx-manager; \
    git reset --hard 754a6da46d25862983ebf2c19eb70632b46896f5; \
    git submodule update --init --recursive; \
}

# TODO: copy /rootfs/bin/makerdao-installer script?
COPY /rootfs/bin/makerdao-helper /bin/

# TODO: i don't love having all these installs in one RUN, but they share a lot of cache
RUN { set -eux; \
    \
    PIPCACHE="$(chroot --userspec=abc / mktemp -d -p /tmp)"; \
    \
    # https://github.com/makerdao/plunger
    # run this before starting any of the keepers since pending transactions can break things!
    APP=plunger; \
    GIT_HASH=38e7a362109296f84fd33265af84013c6dadcc62; \
    \
    VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -r "${VENV}/src/requirements.txt"; \
    \
    makerdao-helper "$APP" --help; \
    \
    \
    # https://github.com/makerdao/arbitrage-keeper
    APP=arbitrage-keeper; \
    GIT_HASH=0679f30335ac48b96f5e60550c6a49e46612be8a; \
    \
    VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -r "${VENV}/src/requirements.txt"; \
    \
    makerdao-helper "$APP" --help; \
    \
    \
    # https://github.com/makerdao/auction-keeper
    APP=auction-keeper; \
    GIT_HASH=19cda06d5bbc9d61e01979f3c40e6bafd9d8b570; \
    \
    VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -r "${VENV}/src/requirements.txt"; \
    \
    makerdao-helper "$APP" --help; \
    \
    \
    # https://github.com/makerdao/bite-keeper
    APP=bite-keeper; \
    GIT_HASH=e606456115cab88636a88a1ff403a81dd80cca77; \
    \
    VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -r "${VENV}/src/requirements.txt"; \
    \
    makerdao-helper "$APP" --help; \
    \
    \
    # https://github.com/makerdao/cdp-keeper
    APP=cdp-keeper; \
    GIT_HASH=4396f0483b4109701cc292dc175360b8a0f00e3e; \
    \
    VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -r "${VENV}/src/requirements.txt"; \
    \
    makerdao-helper "$APP" --help; \
    \
    \
    # https://github.com/makerdao/market-maker-keeper (and etherdelta-client)
    APP=market-maker-keeper; \
    GIT_HASH=3f0b2016f186c6c53651143db1e3a2ea6574526d; \
    \
    VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install --cache-dir "$PIPCACHE" -r "${VENV}/src/requirements.txt"; \
    \
    # etherdelta-client for placing orders on EtherDelta using socket.io
    cd ./lib/pymaker/utils/etherdelta-client; \
    npm install; \
    # TODO: this doesn't seem to install anything onto the path. is this correct?
    \
    # TODO: run help for all the -keeper and -cancel and any other scripts
    APP="$APP" makerdao-helper oasis-market-maker-keeper --help; \
    \
    rm -rf /tmp/*; \
}

COPY rootfs/ /

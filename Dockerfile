FROM gitlab.stytt.com:5001/docker/linux-nix/ubuntu as nix-builder

# https://github.com/dapphub/dapptools
# TODO: pin specific version
RUN { set -eux; \
    \
    export GNUPGHOME="$(mktemp -d -p /tmp)"; \
    export MANPATH=""; \
    . /root/.nix-profile/etc/profile.d/nix.sh; \
    \
    # dapp, seth, solc, hevm, ethsign (and also jshon)
    git clone --depth 1 --recursive https://github.com/dapphub/dapptools $HOME/.dapp/dapptools; \
    nix-env -f $HOME/.dapp/dapptools -iA dapp ethsign hevm seth solc token ; \
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
    make link; \
    \
    rm -rf /tmp/*; \
}

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
    libffi-dev \
    libsecp256k1-dev \
    libssl-dev \
    libtool \
    make \
    pkg-config \
    python3-dev \
    sudo \
;

# install node for etherdelta-client (and probably other scripts)
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

# https://github.com/makerdao/tx-manager
RUN { set -eux; \
    \
    git clone --depth 1 https://github.com/makerdao/tx-manager /opt/contracts/tx-manager; \
    cd /opt/contracts/tx-manager; \
    git reset --hard 754a6da46d25862983ebf2c19eb70632b46896f5; \
}

# https://github.com/makerdao/plunger
# run this before starting any of the keepers since pending transactions can break things!
RUN { set -eux; \
    \
    export APP=plunger; \
    export GIT_HASH=38e7a362109296f84fd33265af84013c6dadcc62; \
    \
    export VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -r "${VENV}/src/requirements.txt"; \
    \
    # TODO: this is wrong. look at /opt/$APP/src/bin/$APP. they need an actual setup.py
    ln -sfv "${VENV}/bin/${APP}" /usr/local/bin/; \
}

# https://github.com/makerdao/arbitrage-keeper
RUN { set -eux; \
    \
    export APP=arbitrage-keeper; \
    export GIT_HASH=0679f30335ac48b96f5e60550c6a49e46612be8a; \
    \
    export VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -r "${VENV}/src/requirements.txt"; \
    \
    # TODO: this is wrong. look at /opt/$APP/src/bin/$APP. they need an actual setup.py
    ln -sfv "${VENV}/bin/${APP}" /usr/local/bin/; \
}

# https://github.com/makerdao/auction-keeper
RUN { set -eux; \
    \
    export APP=auction-keeper; \
    export GIT_HASH=19cda06d5bbc9d61e01979f3c40e6bafd9d8b570; \
    \
    export VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -r "${VENV}/src/requirements.txt"; \
    \
    # TODO: this is wrong. look at /opt/$APP/src/bin/$APP. they need an actual setup.py
    ln -sfv "${VENV}/bin/${APP}" /usr/local/bin/; \
}

# https://github.com/makerdao/bite-keeper
RUN { set -eux; \
    \
    export APP=bite-keeper; \
    export GIT_HASH=e606456115cab88636a88a1ff403a81dd80cca77; \
    \
    export VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -r "${VENV}/src/requirements.txt"; \
    \
    # TODO: this is wrong. look at /opt/$APP/src/bin/$APP. they need an actual setup.py
    ln -sfv "${VENV}/bin/${APP}" /usr/local/bin/; \
}

# https://github.com/makerdao/cdp-keeper
RUN { set -eux; \
    \
    export APP=cdp-keeper; \
    export GIT_HASH=4396f0483b4109701cc292dc175360b8a0f00e3e; \
    \
    export VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -r "${VENV}/src/requirements.txt"; \
    \
    # TODO: this is wrong. look at /opt/$APP/src/bin/$APP. they need an actual setup.py
    ln -sfv "${VENV}/bin/${APP}" /usr/local/bin/; \
}

# https://github.com/makerdao/market-maker-keeper (and etherdelta-client)
RUN { set -eux; \
    \
    export APP=market-maker-keeper; \
    export GIT_HASH=3f0b2016f186c6c53651143db1e3a2ea6574526d; \
    \
    export VENV="/opt/$APP"; \
    \
    mkdir -p "${VENV}"; \
    chown abc:abc "${VENV}"; \
    chroot --userspec=abc / python3.6 -m venv "${VENV}"; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -U setuptools pip; \
    \
    git clone https://github.com/makerdao/${APP}.git "${VENV}/src"; \
    cd "${VENV}/src"; \
    git reset --hard "$GIT_HASH"; \
    git submodule update --init --recursive; \
    chown -R abc:abc .; \
    chroot --userspec=abc / "${VENV}/bin/pip" install -r "${VENV}/src/requirements.txt"; \
    \
    cd "$VENV/bin"; \
    for x in *-keeper; do \
      ln -sfv "$(pwd)/$x" /usr/local/bin/; \
    done; \
    for x in *-cancel; do \
      ln -sfv "$(pwd)/$x" /usr/local/bin/; \
    done; \
    cd -; \
    \
    # etherdelta-client for placing orders on EtherDelta using socket.io
    cd ./lib/pymaker/utils/etherdelta-client; \
    npm install; \
}

COPY --from=nix-builder /root/.nix-profile /root/.nix-profile
COPY --from=nix-builder /nix /nix
COPY --from=nix-builder /root/.dapp/dapptools /root/.dapp/dapptools
COPY --from=nix-builder /usr/local/bin /usr/local/bin

COPY rootfs/ /

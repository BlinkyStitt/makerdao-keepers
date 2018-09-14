FROM gitlab.stytt.com:5001/docker/dapptools as dapptools

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

COPY /rootfs/bin/keeper-helper /bin/

# https://github.com/makerdao/plunger
# run this before starting any of the keepers since pending transactions can break things!
RUN { set -eux; \
    \
    APP=plunger; \
    GIT_HASH=38e7a362109296f84fd33265af84013c6dadcc62; \
    \
    VENV="/opt/$APP"; \
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
    keeper-helper "$APP" --help; \
}

# https://github.com/makerdao/arbitrage-keeper
RUN { set -eux; \
    \
    APP=arbitrage-keeper; \
    GIT_HASH=0679f30335ac48b96f5e60550c6a49e46612be8a; \
    \
    VENV="/opt/$APP"; \
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
    keeper-helper "$APP" --help; \
}

# https://github.com/makerdao/auction-keeper
RUN { set -eux; \
    \
    APP=auction-keeper; \
    GIT_HASH=19cda06d5bbc9d61e01979f3c40e6bafd9d8b570; \
    \
    VENV="/opt/$APP"; \
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
    keeper-helper "$APP" --help; \
}

# https://github.com/makerdao/bite-keeper
RUN { set -eux; \
    \
    APP=bite-keeper; \
    GIT_HASH=e606456115cab88636a88a1ff403a81dd80cca77; \
    \
    VENV="/opt/$APP"; \
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
    keeper-helper "$APP" --help; \
}

# https://github.com/makerdao/cdp-keeper
RUN { set -eux; \
    \
    APP=cdp-keeper; \
    GIT_HASH=4396f0483b4109701cc292dc175360b8a0f00e3e; \
    \
    VENV="/opt/$APP"; \
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
    keeper-helper "$APP" --help; \
}

# https://github.com/makerdao/market-maker-keeper (and etherdelta-client)
RUN { set -eux; \
    \
    APP=market-maker-keeper; \
    GIT_HASH=3f0b2016f186c6c53651143db1e3a2ea6574526d; \
    \
    VENV="/opt/$APP"; \
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
    # etherdelta-client for placing orders on EtherDelta using socket.io
    cd ./lib/pymaker/utils/etherdelta-client; \
    npm install; \
    # TODO: this doesn't seem to install anything onto the path. is this correct?
    \
    # TODO: run help for all the -keeper and -cancel and any other scripts
    APP="$APP" keeper-helper oasis-market-maker-keeper --help; \
}

# how big are these layers? should we copy nix stuff earlier?
# TODO: this is missing something. dapp isn't on the path even when starting a login shell
COPY --from=dapptools /root/.nix-profile /root/.nix-profile
COPY --from=dapptools /nix /nix
COPY --from=dapptools /root/.dapp/dapptools /root/.dapp/dapptools
COPY --from=dapptools /usr/local/bin /usr/local/bin

ENV USER root
RUN . /root/.nix-profile/etc/profile.d/nix.sh

COPY rootfs/ /

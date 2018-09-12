FROM gitlab.stytt.com:5001/docker/python3/alpine-s6

RUN docker-install \
    git \
    python3-dev \
;

ENV GIT_HASH 0679f30335ac48b96f5e60550c6a49e46612be8a

# TODO: move this up
RUN docker-install \
    gcc \
    linux-headers \
    make \
    musl-dev \
;

RUN { set -eux; \
    \
    git clone https://github.com/makerdao/arbitrage-keeper.git /opt/arbitrage-keeper; \
    cd /opt/arbitrage-keeper; \
    git reset --hard $GIT_HASH; \
    git submodule update --init --recursive; \
    pip3 install -r requirements.txt; \
}

COPY rootfs/ /

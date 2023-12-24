FROM node:18-buster AS builder

ARG PIGALLERY_VERSION=2.0.0
RUN git clone https://github.com/bpatrik/pigallery2.git /build \
    && cd /build \
    && git checkout ${PIGALLERY_VERSION}
WORKDIR /build
COPY pigallery2-hotfix-2.0.0.patch /tmp/patch
RUN git apply /tmp/patch

RUN --mount=type=cache,target=/root/.npm \
    npm install --unsafe-perm --loglevel verbose \
    && mkdir -p /build/release/data/config \
    && mkdir -p /build/release/data/db \
    && mkdir -p /build/release/data/images \
    && mkdir -p /build/release/data/tmp \
    && npm run create-release \
    && cd /build/release \
    && npm install --unsafe-perm

FROM node:18-buster-slim AS main
WORKDIR /app
ENV NODE_ENV=production \
    # overrides only the default value of the settings (the actualy value can be overwritten through config.json)
    default-Database-dbFolder=/app/data/db \
    default-Media-folder=/app/data/images \
    default-Media-tempFolder=/app/data/tmp \
    default-Extensions-folder=/app/data/config/extensions \
    # flagging dockerized environemnt
    PI_DOCKER=true

EXPOSE 80
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates wget ffmpeg \
        fuse \
    && apt-get clean -q -y \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/release /app

# gocryptfs
ARG GOCRYPTFS_VERSION=v2.4.0
ARG GOCRYPTFS_URL=https://github.com/rfjakob/gocryptfs/releases/download/${GOCRYPTFS_VERSION}/gocryptfs_${GOCRYPTFS_VERSION}_linux-static_amd64.tar.gz
RUN wget -O- "$GOCRYPTFS_URL" | tar -zxC /usr/local/bin -f- gocryptfs

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

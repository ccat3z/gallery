FROM bpatrik/pigallery2:1.9.0-debian-buster

# apt dependencies
RUN apt update && apt install -y fuse \
 && rm -rf /var/lib/apt/lists/*

# tint
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# gocryptfs
ENV GOCRYPTFS_VERSION v2.1
ENV GOCRYPTFS_URL https://github.com/rfjakob/gocryptfs/releases/download/${GOCRYPTFS_VERSION}/gocryptfs_${GOCRYPTFS_VERSION}_linux-static_amd64.tar.gz
RUN wget -O- "$GOCRYPTFS_URL" | tar -zxC /usr/local/bin -f- gocryptfs

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/tini", "--", "/usr/local/bin/entrypoint.sh"]

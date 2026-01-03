FROM docker.io/library/alpine:3

LABEL org.opencontainers.image.title="megacmd"
LABEL org.opencontainers.image.description="Application packaged by dehahost"
LABEL org.opencontainers.image.vendor="dehahost"
LABEL org.opencontainers.image.base.name="docker.io/library/alpine:3"
LABEL org.opencontainers.image.source="https://github.com/dehahost/megacmd-image"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/dehahost/megacmd"

ARG UID=9100

# - Install MEGA CMD
RUN    apk upgrade --no-cache \
    && apk add --no-cache megacmd

# - Copy launch.sh
COPY entry.sh /usr/local/bin/

# - Prepare home
RUN    adduser -D -u $UID mega  \
    && install -d -o mega -g mega -m 0777 /home/mega \
    && if [ ! -r /etc/machine-id ]; then ln -s /tmp/machine-id /etc/machine-id ; fi

VOLUME [ "/home/mega" ]

USER mega:mega
WORKDIR /home/mega
ENV HOME=/home/mega

ENTRYPOINT [ "/usr/local/bin/entry.sh" ]

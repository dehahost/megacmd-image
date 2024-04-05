FROM docker.io/library/alpine:3

LABEL name="megacmd"
LABEL description="MEGA CMD image"
LABEL version="2.0.0"
LABEL author="dehahost"
LABEL fqin="host.deha.megacmd"

# - Install MEGA CMD
RUN    apk upgrade --no-cache \
    && apk add --no-cache megacmd

# - Copy launch.sh
COPY entry.sh /usr/local/bin/

# - Prepare home
RUN    adduser -D -u 1001 mega \
    && if [ ! -r /etc/machine-id ]; then ln -s /tmp/machine-id /etc/machine-id ; fi

USER mega:mega
WORKDIR /home/mega
ENTRYPOINT /usr/local/bin/entry.sh

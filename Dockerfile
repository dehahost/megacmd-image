FROM docker.io/library/alpine:3

LABEL name="megacmd"
LABEL author="dehahost"
LABEL fqin="com.dehahost.megacmd"

ARG UID=9100

# - Install MEGA CMD
RUN    apk upgrade --no-cache \
    && apk add --no-cache megacmd

# - Copy launch.sh
COPY entry.sh /usr/local/bin/

# - Prepare home
RUN    adduser -D -u ${UID} mega  \
    && install -d -o mega -g mega -m 0777 /home/mega \
    && if [ ! -r /etc/machine-id ]; then ln -s /tmp/machine-id /etc/machine-id ; fi

VOLUME [ "/home/mega" ]

USER mega:mega
WORKDIR /home/mega
ENV HOME=/home/mega

ENTRYPOINT [ "/usr/local/bin/entry.sh" ]

FROM docker.io/library/debian:11-slim

# - Good defaults
ARG ARCH="armhf"
ARG DIST="Raspbian_11"
ARG VER="1.6.3-1.1"

# - Metadata
LABEL name="megacmd"
LABEL description="MEGA CMD containerized"
LABEL version="1.0.0"
LABEL author="dehahost"
LABEL fqin="host.deha.megacmd"

# - Install MEGA CMD
RUN echo "\n===== Install curl\n" && \
    apt-get update && \
    apt-get --assume-yes install curl && \
    echo "\n===== Download MEGA CMD (${DIST}/${ARCH}/${VER}, .deb)\n" && \
    cd /var/cache/apt/archives && \
    curl -LO# "https://mega.nz/linux/repo/${DIST}/${ARCH}/megacmd_${VER}_${ARCH}.deb" && \
    echo "\n===== Install MEGA CMD (.deb)\n" && \
    dpkg -i megacmd_${VER}_${ARCH}.deb ; \
    echo "\n===== Install MEGA CMD (dependencies)\n" && \
    apt-get update && \
    apt-get --assume-yes install -f && \
    echo "\n===== Clean up\n" && \
    rm -vrf /var/cache/apt/archives /var/lib/apt/lists && \
    echo "\n===== Final checks\n" && \
    dpkg -l | grep megacmd && \
    whereis mega-cmd-server

# - Copy launch.sh
COPY ./launch.sh /usr/local/bin/

# - Prepare "home"
RUN mkdir /var/home && \
    chown 1001:1001 /var/home && \
    ln -s /tmp/machine-id /etc/machine-id

USER 1001:1001
WORKDIR /var/home
ENTRYPOINT ["/bin/bash"]
CMD ["/usr/local/bin/launch.sh"]

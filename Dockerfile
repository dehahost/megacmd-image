ARG UBUNTU_RELEASE=24.04
ARG CHISEL_VERSION=v1.4.0

FROM docker.io/library/ubuntu:$UBUNTU_RELEASE AS builder

ARG TARGETARCH UBUNTU_RELEASE CHISEL_VERSION
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

RUN    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y curl ca-certificates git \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/list/*

RUN    curl -o /tmp/chisel.tar.gz \
         "https://github.com/canonical/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_${TARGETARCH}.tar.gz" \
    && tar -xavf /tmp/chisel.tar.gz -C /usr/bin/ \
    && rm -r /tmp/chisel.tar.gz

# TODO:
#   1/ Clone https://github.com/canonical/chisel-releases at branch ubuntu-24.04 (or ubuntu-${UBUNTU_RELEASE})
#   2/ Add megacmd slice to slices dir
#   3/ Run chisel with megacmd_bins and megacmd_config
#   4/ Setup mega home / rename "ubuntu"

RUN    mkdir /staging-rootfs \
    && chisel cut --release "ubuntu-$UBUNTU_RELEASE" --root /staging-rootfs \
         base-files_base \
         base-files_release-info \
         base-files_chisel \
         ca-certificates_data \
         python3_standard

FROM scratch

COPY --from=builder /staging-rootfs /

USER ubuntu
WORKDIR /home/ubuntu

ENTRYPOINT ["python3"]

# FROM docker.io/library/alpine:3.23
#
# LABEL org.opencontainers.image.title="megacmd"
# LABEL org.opencontainers.image.description="Application packaged by dehahost"
# LABEL org.opencontainers.image.vendor="dehahost"
# LABEL org.opencontainers.image.base.name="docker.io/library/alpine:3.23"
# LABEL org.opencontainers.image.source="https://github.com/dehahost/megacmd-image"
# LABEL org.opencontainers.image.url="https://hub.docker.com/r/dehahost/megacmd"
#
# ARG UID=9100
#
# # - Install MEGA CMD
# RUN    apk upgrade --no-cache \
#     && apk add --no-cache bash megacmd
#
# # - Copy launch.sh
# COPY entry.sh /usr/local/bin/
#
# # - Prepare home
# RUN    adduser -D -u $UID mega  \
#     && install -d -o mega -g mega -m 0777 /home/mega \
#     && if [ ! -r /etc/machine-id ]; then ln -s /tmp/machine-id /etc/machine-id ; fi
#
# VOLUME [ "/home/mega" ]
#
# USER mega:mega
# WORKDIR /home/mega
# ENV HOME=/home/mega
#
# ENTRYPOINT [ "/usr/local/bin/entry.sh" ]

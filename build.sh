#!/bin/bash

case $1 in
    armhf)
        arch="armhf"; dist="Raspbian_11"; ver="1.6.3-1.1"
        d_opts="--arch arm --variant v7";
 ;; amd64)
        arch="amd64"; dist="Debian_11"; ver="1.6.3-1.1"
        d_opts="--arch amd64";
 ;; *)
        echo "Enter the target platform: armhf, amd64"
        exit 1
 ;;
esac

podman build \
  ${d_opts} \
  --build-arg ARCH="${arch}" --build-arg DIST="${dist}" --build-arg VER="${ver}" \
  -t "megacmd:${arch}" -t "megacmd:${ver}_${arch}" \
.

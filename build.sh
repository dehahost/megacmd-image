#!/bin/bash

IMG_NAME="docker.io/dehahost/megacmd"
IMG_VERSION="1.6.3"
IMG_ARCHS=(
    "linux/amd64"
    "linux/arm64/v8"
)
IMG_TAGS=(
    "${IMG_NAME}:latest"
    "${IMG_NAME}:${IMG_VERSION}"
    "${IMG_NAME}:${IMG_VERSION}-$(date +"%Y.%m")"
)
IMG_LABLES=(
    "org.opencontainers.image.created=$(date +"%Y-%m-%dT%H:%M:%SZ")"
    "org.opencontainers.image.version=${IMG_VERSION}"
    "com.dehahost.oci.build.version=${IMG_VERSION}-$(date +"%Y.%m")"
    "com.dehahost.oci.build.branch=$(git rev-parse --abbrev-ref HEAD)"
)

###

set -e
unset arg_nocache arg_push arg_tags arg_lables

if [[ $1 == "--help" ]]; then
    echo "$(basename "$0") [--devel] [--no-cache] [--push]"
    exit
fi

if [[ $1 == "--devel" ]]; then
    echo -e "\e[2m[ i ] Override: Use \"devel\" environment\e[0m"
    IMG_TAGS=(
        "${IMG_NAME}:devel"
        "${IMG_NAME}:devel-$(date +"%Y.%m")"
    )
    IMG_LABELS+=( "com.dehahost.oci.env=devel" )
    shift
else
    IMG_LABELS+=( "com.dehahost.oci.env=prod" )
fi

if [[ $1 == "--no-cache" ]]; then
    echo -e "\e[2m[ i ] Override: Build without cache, always pull\e[0m"
    arg_nocache=("--no-cache" "--pull"); shift
fi

if [[ $1 == "--push" ]]; then
    echo -e "\e[2m[ i ] Override: Push after build\e[0m"
    arg_push="--push"; shift
fi

###

IFS=" " read -ra arg_tags <<< "$(printf -- "--tag %s " "${IMG_TAGS[@]}")"
IFS=" " read -ra arg_lables <<< "$(printf -- "--label %s " "${IMG_LABLES[@]}")"

docker buildx build \
    $arg_push "${arg_nocache[@]}" --progress=plain \
    --provenance=true --sbom=true \
    --platform="$(echo "${IMG_ARCHS[@]}" | tr ' ' ',')" \
    "${arg_lables[@]}" \
    "${arg_tags[@]}" \
.

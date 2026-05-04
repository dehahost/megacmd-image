#!/bin/bash
set -e

IMG_NAME="docker.io/dehahost/megacmd"
IMG_VERSION=$(
    curl -sSL https://mega.nz/linux/repo/xUbuntu_24.04/Packages | \
        grep -A 2 "^Package: megacmd$" | \
        grep -B 1 -m 1 "^Architecture: amd64$" | \
        head -1 | \
        cut -d ' ' -f 2 | \
        cut -d '-' -f 1
)
IMG_ARCHS=(
    "linux/amd64"
    "linux/arm64/v8"
)
IMG_TAGS=(
    "${IMG_NAME}:${IMG_VERSION}-$(date +"%Y.%m")"
    "${IMG_NAME}:${IMG_VERSION}"
)
IMG_LABLES=(
    "org.opencontainers.image.created=$(date +"%Y-%m-%dT%H:%M:%SZ")"
    "org.opencontainers.image.version=${IMG_VERSION}"
    "com.dehahost.oci.build.version=${IMG_VERSION}-$(date +"%Y.%m")"
    "com.dehahost.oci.build.branch=$(git rev-parse --abbrev-ref HEAD)"
    "com.dehahost.oci.build.commit=$(git rev-parse HEAD)"
)

###

unset arg_nocache arg_push arg_tags arg_lables _override

if [[ $1 == "--help" ]]; then
    echo "$(basename "$0") [--prod] [--no-cache] [--push]"
    exit
fi

if [[ $1 == "--prod" ]]; then
    echo -e "\e[2m[ \e[0m\e[94mi\e[0m\e[2m ] Override: Use \"prod\" environment\e[0m"
    IMG_TAGS+=( "${IMG_NAME}:latest" )
    IMG_LABELS+=( "com.dehahost.oci.env=prod" )
    _override=1; shift
else
    IMG_TAGS=(
        "${IMG_NAME}:devel-$(date +"%Y.%m")"
        "${IMG_NAME}:devel"
    )
    IMG_LABELS+=( "com.dehahost.oci.env=devel" )
fi

if [[ $1 == "--no-cache" ]]; then
    echo -e "\e[2m[ \e[0m\e[94mi\e[0m\e[2m ] Override: Build without cache, always pull\e[0m"
    arg_nocache=("--no-cache" "--pull")
    _override=1; shift
fi

if [[ $1 == "--push" ]]; then
    echo -e "\e[2m[ \e[0m\e[94mi\e[0m\e[2m ] Override: Push after build\e[0m"
    arg_push="--push"
    _override=1; shift
fi

###

echo -e "\e[2m[ \e[0m\e[94mi\e[0m\e[2m ] MEGAcmd version upstream: ${IMG_VERSION}\e[0m"

if local_mcmd_version="$(head -1 .build.mcmd-ver)" && [[ $IMG_VERSION != "$local_mcmd_version" ]]; then
    #             [ i ] MEGAcmd version upstream: ...
    echo -e "\e[2m                 ...last known: \e[33m${local_mcmd_version}\e[0m"
fi

###

[[ -n $_override ]] && echo

IFS=" " read -ra arg_tags <<<"$(printf -- "--tag %s " "${IMG_TAGS[@]}")"
IFS=" " read -ra arg_lables <<<"$(printf -- "--label %s " "${IMG_LABLES[@]}")"

docker buildx build \
    $arg_push "${arg_nocache[@]}" --progress=plain \
    --provenance=true --sbom=true \
    --platform="$(echo "${IMG_ARCHS[@]}" | tr ' ' ',')" \
    "${arg_lables[@]}" \
    "${arg_tags[@]}" \
.

echo "${IMG_VERSION}" >.build.mcmd-ver

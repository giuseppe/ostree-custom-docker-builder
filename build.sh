#!/bin/bash
set -o pipefail
IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
    echo "Docker socket missing at ${DOCKER_SOCKET}"
    exit 1
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
    TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
fi

mkdir repo
ostree --repo=repo init --mode=archive-z2
ostree --repo=repo remote add origin --no-gpg-verify "${SOURCE_REPOSITORY}"
ostree --repo=repo pull origin "${SOURCE_REF}"
COMMIT=$(ostree --repo=repo rev-parse "${SOURCE_REF}")

docker pull "${TAG}"

if test -z "$(docker images --filter label=ostree.commit=${COMMIT} | tail -n+2)"; then
    mkdir image
    ostree --repo=repo checkout --fsync=no "${SOURCE_REF}" image/sysroot

    cat > image/Dockerfile << EOF
FROM scratch
ADD sysroot /
LABEL ostree.commit=${COMMIT}
EOF
    docker build -t "${TAG}" image
else
    IMAGE="$(docker images --filter label=ostree.commit=${COMMIT} | tail -n+2 | awk '{print $3}')"
    docker tag "${IMAGE}" "${TAG}"
fi

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
    cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
    docker push "${TAG}"
fi

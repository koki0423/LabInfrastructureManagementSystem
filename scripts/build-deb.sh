#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILDER_IMAGE="lims-system-deb-builder:1.0.0"
readonly BUILDER_DOCKERFILE="${REPOSITORY_ROOT}/packaging/debian/Dockerfile.build"
readonly OUTPUT_DIR="${REPOSITORY_ROOT}/dist"
readonly DEB_VERSION="${DEB_VERSION:-}"

if [[ -n "${DEB_VERSION}" && ! "${DEB_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+~alpha\.[0-9]+$ ]]; then
    echo "[ERROR] DEB_VERSION must use X.Y.Z~alpha.N format: ${DEB_VERSION}" >&2
    exit 1
fi

command -v docker >/dev/null 2>&1 || {
    echo "[ERROR] docker が見つかりません。" >&2
    exit 1
}

docker info >/dev/null 2>&1 || {
    echo "[ERROR] Docker Engine に接続できません。" >&2
    exit 1
}

mkdir -p "${OUTPUT_DIR}"

echo "[INFO] Debianビルド用コンテナを作成します。"
docker build --tag "${BUILDER_IMAGE}" --file "${BUILDER_DOCKERFILE}" "${REPOSITORY_ROOT}"

echo "[INFO] Linuxコンテナで.debを生成します。"
docker run --rm \
    --volume "${REPOSITORY_ROOT}:/source:ro" \
    --volume "${OUTPUT_DIR}:/out" \
    --env "DEB_VERSION=${DEB_VERSION}" \
    "${BUILDER_IMAGE}" \
    bash -ceu '
        rm -rf /work/lims-system
        mkdir -p /work/lims-system
        cp -a /source/. /work/lims-system/
        cd /work/lims-system
        cp -a packaging/debian debian
        chmod +x debian/rules debian/lims-system.postinst debian/lims-system.prerm debian/lims-system.postrm scripts/limsctl
        if [[ -n "${DEB_VERSION:-}" ]]; then
            sed -E -i "1s/^lims-system \\([^)]+\\)/lims-system (${DEB_VERSION})/" debian/changelog
        fi
        dpkg-buildpackage -us -uc -b
        cp -v /work/lims-system_*.deb /out/
    '

echo "[OK] パッケージを生成しました: ${OUTPUT_DIR}"

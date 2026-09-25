#!/usr/bin/env bash
# Build the layer and a minimal image on a GitHub-hosted Linux runner.
set -euo pipefail

release=${1:?Usage: validate-yocto.sh scarthgap|wrynose}
case "${release}" in
  scarthgap)
    bitbake_rev=acfe02fa38b5da9e6a36c6cedcf91d4fcbefbfbd
    oe_core_rev=c2746a4a165fd99c2d1aafed17533555787f37ce
    ;;
  wrynose)
    bitbake_rev=a2dd9be788274d9c7280be5b1be5eb5c3990cf54
    oe_core_rev=42fa856a00ac16b2a7a83d7ecfa60a5be192b16c
    ;;
  *)
    echo "Unsupported Yocto release: ${release}" >&2
    exit 2
    ;;
esac

layer_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
runner_temp=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
validation_root=$(mktemp -d "${runner_temp%/}/meta-noxtls-${release}-XXXXXX")

fetch_revision() {
  local url=$1 directory=$2 revision=$3
  git init -q "${directory}"
  git -C "${directory}" remote add origin "${url}"
  git -C "${directory}" fetch --depth 1 origin "${revision}"
  git -C "${directory}" checkout -q --detach FETCH_HEAD
}

fetch_revision https://github.com/openembedded/bitbake.git \
  "${validation_root}/bitbake" "${bitbake_rev}"
fetch_revision https://github.com/openembedded/openembedded-core.git \
  "${validation_root}/openembedded-core" "${oe_core_rev}"

echo "Yocto release: ${release}"
echo "BitBake revision: $(git -C "${validation_root}/bitbake" rev-parse HEAD)"
echo "OE-Core revision: $(git -C "${validation_root}/openembedded-core" rev-parse HEAD)"
echo "meta-noxtls revision: $(git -C "${layer_root}" rev-parse HEAD)"

cd "${validation_root}"
# Both pinned OE-Core revisions support this manual Linux build setup.
# OE-Core's environment script reads optional shell variables without defaults.
# Disable nounset only while sourcing it, then restore strict validation.
set +u
source openembedded-core/oe-init-build-env "${validation_root}/build"
set -u

cat >> conf/local.conf <<'EOF'
MACHINE = "qemux86-64"
DISTRO = "nodistro"
PACKAGE_CLASSES = "package_ipk"
IMAGE_INSTALL:append = " packagegroup-noxtls"
BB_NUMBER_THREADS = "4"
PARALLEL_MAKE = "-j 4"
INHERIT += "rm_work"
EOF

cache_root="${HOME}/.cache/meta-noxtls/${release}"
install -d "${cache_root}/downloads" "${cache_root}/sstate-cache"
cat >> conf/local.conf <<EOF
DL_DIR = "${cache_root}/downloads"
SSTATE_DIR = "${cache_root}/sstate-cache"
EOF

bitbake-layers add-layer "${layer_root}"
bitbake-layers show-recipes noxtls
bitbake noxtls packagegroup-noxtls
bitbake core-image-minimal

manifest=$(find tmp/deploy/images/qemux86-64 -maxdepth 1 -type f \
  -name 'core-image-minimal-*.manifest' -print -quit)
test -n "${manifest}"
grep -E '^noxtls[[:space:]]' "${manifest}"
grep -E '^packagegroup-noxtls[[:space:]]' "${manifest}"
echo "${release} NoxTLS image integration: PASS"

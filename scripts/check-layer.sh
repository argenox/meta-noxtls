#!/usr/bin/env bash
set -euo pipefail

layer_root=$(cd "$(dirname "$0")/.." && pwd)

for path in README.md LICENSE conf/layer.conf \
  recipes-crypto/noxtls/noxtls_0.2.70.bb \
  recipes-core/packagegroups/packagegroup-noxtls.bb \
  scripts/validate-yocto.sh; do
  test -f "${layer_root}/${path}"
done

grep -Fq 'BBFILE_COLLECTIONS += "noxtls"' "${layer_root}/conf/layer.conf"
grep -Fq 'LAYERDEPENDS_noxtls = "core"' "${layer_root}/conf/layer.conf"
grep -Fq 'SRCREV = "3e6c69e6e47bc50496f66000d7277848343e8b47"' \
  "${layer_root}/recipes-crypto/noxtls/noxtls_0.2.70.bb"
grep -Fq 'RDEPENDS:${PN} = "noxtls"' \
  "${layer_root}/recipes-core/packagegroups/packagegroup-noxtls.bb"

echo "meta-noxtls layer structure: PASS"

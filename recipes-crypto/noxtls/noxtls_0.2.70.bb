# SPDX-License-Identifier: LicenseRef-Argenox-Proprietary

SUMMARY = "NoxTLS embedded TLS and cryptography SDK"
DESCRIPTION = "Static NoxTLS libraries, public headers, CMake and pkg-config metadata, and optional command line tools."
HOMEPAGE = "https://github.com/argenox/noxtls"
SECTION = "libs"

# The upstream dual-license notice also offers a separate commercial license.
# This recipe selects the GPLv2 terms documented in LICENSE.md and COPYING.md.
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = " \
    file://LICENSE.md;md5=e950816f5121956f594463383a3601ff \
    file://COPYING.md;md5=f6b273a0a9f3f45338fea41cb0dfdb27 \
"

SRC_URI = "git://github.com/argenox/noxtls.git;protocol=https;branch=master;destsuffix=git"
SRCREV = "3e6c69e6e47bc50496f66000d7277848343e8b47"

# Fix the Git destination across Scarthgap and Wrynose, whose default Git
# destination differs. Older BitBake uses WORKDIR; newer releases use UNPACKDIR.
NOXTLS_SOURCE_UNPACK_DIR = "${@d.getVar('UNPACKDIR') or d.getVar('WORKDIR')}"
S = "${NOXTLS_SOURCE_UNPACK_DIR}/git"

inherit cmake pkgconfig

# Build the installed CLI tools for images by default. The CMake install rules
# place headers and CMake/pkg-config metadata in -dev, and archives in
# -staticdev, following Yocto's normal package split.
PACKAGECONFIG ??= "tools"
PACKAGECONFIG[tools] = "-DBUILD_APPLICATIONS=ON,-DBUILD_APPLICATIONS=OFF"

EXTRA_OECMAKE = " \
    -DBUILD_TESTS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DNOXTLS_APPLICATIONS_BINARY_DIR=${B}/binary \
"

# The library targets are explicitly STATIC in the upstream CMake files.
# Keep the tools package available when an image chooses the default profile.
FILES:${PN} += "${bindir}/*"

# Builds with PACKAGECONFIG:remove:pn-noxtls = "tools" produce only SDK files.
ALLOW_EMPTY:${PN} = "1"

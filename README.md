# meta-noxtls

Portable Yocto/OpenEmbedded integration for [NoxTLS](https://github.com/argenox/noxtls).
The layer builds the upstream static libraries and, by default, its command
line tools. It has no machine, kernel, or board-specific dependencies.

## Add the layer

Add this repository to `bblayers.conf`:

```bitbake
BBLAYERS += "${TOPDIR}/../meta-noxtls"
```

Build the package or include the tools in an image:

```sh
bitbake noxtls
```

```bitbake
IMAGE_INSTALL:append = " packagegroup-noxtls"
```

The `noxtls` package contains target command line programs. Yocto's normal
package split puts public headers, CMake package files, and `noxtls.pc` in
`noxtls-dev`, and the static archives in `noxtls-staticdev`. For an SDK, add
both to `TOOLCHAIN_TARGET_TASK`, or depend on `noxtls` from another recipe:

```bitbake
TOOLCHAIN_TARGET_TASK:append = " noxtls-dev noxtls-staticdev"
```

```bitbake
DEPENDS += "noxtls"
```

Consumers can use `pkg-config --cflags --libs noxtls` or CMake's
`find_package(NoxTLS)` and `NoxTLS::noxtls` imported target. The upstream
libraries are static, so installing `noxtls` alone does not provide a shared
TLS library to other programs at runtime; each consumer links its own binary.

## Build options and source pin

The recipe pins upstream tag `v0.2.70` to commit
`3e6c69e6e47bc50496f66000d7277848343e8b47`. Bump the recipe filename,
`SRCREV`, and license checksums together when updating NoxTLS.

The optional tools may be disabled in a distro or local configuration:

```bitbake
PACKAGECONFIG:remove:pn-noxtls = "tools"
```

This leaves the SDK packages available for linking other recipes. Upstream
CMake profiles can be selected through `EXTRA_OECMAKE:append:pn-noxtls`, for
example ` -DNOXTLS_PROFILE=minimal_tls_client`. Keep the profile consistent
with applications that link the static libraries.

The recipe uses the GPLv2 option in the upstream dual-license notice. If your
product uses the commercial option, review the license metadata and terms with
the license holder before shipping.

## Validation

Run `bash scripts/check-layer.sh` for a fast layer structure check. In a
configured Yocto build, run `bitbake-layers show-recipes noxtls`,
`bitbake noxtls`, and `bitbake packagegroup-noxtls`. The layer declares the
same `scarthgap` and `wrynose` compatibility as the portable `meta-bluenox`
layer; a full BitBake build should be run against each target release before
shipping an image.

## License

The layer files are proprietary to Argenox Technologies LLC; see [LICENSE](LICENSE).
The packaged NoxTLS source has its own dual-license terms.

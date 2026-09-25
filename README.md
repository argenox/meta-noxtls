# meta-noxtls

`meta-noxtls` packages [NoxTLS](https://github.com/argenox/noxtls) for
Yocto/OpenEmbedded images and SDKs. It builds the upstream static libraries,
public headers, CMake and pkg-config metadata, and command line tools. The
layer is independent of BlueNox and does not provide a machine or image recipe.

## Supported Yocto releases

| Yocto release | Version | Validation status |
| --- | --- | --- |
| Scarthgap | 5.0 LTS | Targeted; full BitBake and image install validation pending. |
| Wrynose | 6.0 LTS | Targeted; full BitBake and image install validation pending. |

No Yocto release has passed a layer build yet. `conf/layer.conf` therefore does
not claim a tested release in `LAYERSERIES_COMPAT_noxtls`. Once a release passes
the validation commands below on a Linux runner, add its codename
to that variable and update this table. The initial layer commit listed both
releases before either had been tested.

The upstream NoxTLS `v0.2.70` CMake build was checked outside BitBake, with and
without the tools: both configurations installed 12 static archives and the
SDK files; the default configuration also installed 15 tools. This verifies
the upstream install layout, not Yocto compatibility.

## Dependencies and build inputs

- **Layer dependency:** OpenEmbedded Core (`core`). No BlueNox, OpenSSL, or
  board-specific layer is required by this layer. Your chosen image still
  needs its usual distro and machine layers.
- **Build host:** a Linux host with a configured Yocto build environment and
  the host packages required by that Yocto release. Source its environment
  setup script before running the commands below.
- **Source fetch:** Git access to `https://github.com/argenox/noxtls.git`, or
  a Yocto download mirror containing the pinned revision. The recipe uses
  upstream tag `v0.2.70` at commit
  `3e6c69e6e47bc50496f66000d7277848343e8b47`.
- **Build dependencies:** the recipe inherits Yocto's `cmake` and `pkgconfig`
  classes. It declares no additional target recipe dependencies. Runtime
  dependencies of the command line tools are resolved by Yocto packaging.

## Build the package

The following commands assume an existing Yocto build environment and a
`meta-noxtls` checkout next to the build directory. On Scarthgap, source the
Poky/OE-Core `oe-init-build-env` script. On a Wrynose setup made with
`bitbake-setup`, source its `build/init-build-env` script. Both leave the shell
in the build directory.

```sh
# Run once, from the parent directory of the Yocto build directory.
git clone https://github.com/argenox/meta-noxtls.git

# After sourcing the appropriate Yocto environment setup script:
bitbake-layers add-layer ../meta-noxtls
bitbake-layers show-layers
bitbake-layers show-recipes noxtls
bitbake noxtls
```

If your layout differs, replace `../meta-noxtls` with the absolute path to
this checkout. The Git checkout can also be added directly to `BBLAYERS` in
`conf/bblayers.conf`. Pin its commit in release builds.

## Install in an image

With the layer enabled, add this line to the build's `conf/local.conf`. The
leading space is required by BitBake's `:append` syntax:

```bitbake
IMAGE_INSTALL:append = " packagegroup-noxtls"
```

Then build an image. For example, a configured Poky build can use:

```sh
bitbake core-image-minimal
```

For a product image, replace `core-image-minimal` with its image recipe name.
To affect only that image instead of every image in the build, put
`IMAGE_INSTALL:append = " packagegroup-noxtls"` in its image recipe. The
package group installs `noxtls`, which contains the command line programs.

The upstream libraries are static. Yocto's package split places headers,
`noxtls.pc`, and the CMake package files in `noxtls-dev`, and archives in
`noxtls-staticdev`. Installing `noxtls` in an image does not install a shared
TLS library for other applications. Another recipe should build against it
with:

```bitbake
DEPENDS += "noxtls"
```

That recipe can use `pkg-config --cflags --libs noxtls` or CMake
`find_package(NoxTLS)` and `NoxTLS::noxtls`. To include the headers and static
archives in a generated target SDK, add the following to `conf/local.conf`
and run the SDK task for your image:

```bitbake
TOOLCHAIN_TARGET_TASK:append = " noxtls-dev noxtls-staticdev"
```

```sh
bitbake core-image-minimal -c populate_sdk
```

Replace `core-image-minimal` with your image recipe if needed.

## Build options

Command line tools are enabled by default. To build only the SDK files, add
this to `conf/local.conf` before running `bitbake noxtls`:

```bitbake
PACKAGECONFIG:remove:pn-noxtls = "tools"
```

NoxTLS CMake profiles can be selected for this recipe, for example:

```bitbake
EXTRA_OECMAKE:append:pn-noxtls = " -DNOXTLS_PROFILE=minimal_tls_client"
```

Keep the profile consistent with applications linking the static archives.
When updating NoxTLS, update the recipe filename, `SRCREV`, and license
checksums together, then repeat the Yocto validation.

## Validate a Yocto release

On a Linux build host configured for the release being evaluated, run:

```sh
bash ../meta-noxtls/scripts/check-layer.sh
bitbake-layers show-recipes noxtls
bitbake noxtls packagegroup-noxtls
bitbake core-image-minimal
```

The image step requires the `IMAGE_INSTALL:append` setting above. Record the
Yocto release, machine, distro, layer commit, and build logs before adding the
release to `LAYERSERIES_COMPAT_noxtls`. A native CMake build or metadata-only
check does not establish image compatibility.

The [Yocto validation workflow](.github/workflows/yocto-validation.yml) runs
these checks for both releases on standard GitHub-hosted `ubuntu-24.04`
runners. Its script pins OE-Core and BitBake revisions,
builds for `qemux86-64`, and checks that the image manifest contains both
`noxtls` and `packagegroup-noxtls`.

## Licensing

The files in this layer are proprietary to Argenox Technologies LLC; see
[LICENSE](LICENSE). Upstream NoxTLS is [dual licensed](https://github.com/argenox/noxtls/blob/master/LICENSE.md)
under GPLv2 or a separate commercial agreement. The recipe selects the GPLv2
option with `LICENSE = "GPL-2.0-only"` and checksums of upstream `LICENSE.md`
and `COPYING.md`. A product using a commercial NoxTLS license needs its own
license agreement and matching recipe metadata before release.

## Report issues

- Report layer recipe, packaging, or Yocto integration problems in
  [meta-noxtls issues](https://github.com/argenox/meta-noxtls/issues).
- Report NoxTLS API, cryptography, or protocol problems in
  [NoxTLS issues](https://github.com/argenox/noxtls/issues).

Include the Yocto release, machine, distro, `meta-noxtls` commit, and the
relevant BitBake task log for integration issues.

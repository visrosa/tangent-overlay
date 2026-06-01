# Tangent Gentoo Overlay (Unofficial)

This overlay provides one unofficial Gentoo package for this fork:

- `app-editors/tangent`

The package builds Tangent from source with offline vendored npm/Electron cache inputs, then installs the bundled Electron app produced by `electron-builder` under `/opt/tangent`.

## Add this overlay

Using `eselect-repository`:

```bash
sudo eselect repository add tangent-overlay git https://github.com/visrosa/tangent-overlay.git
sudo emaint sync -r tangent-overlay
```

Or place this directory as a local overlay and add it to `repos.conf`.

## Install

Stable:

```bash
sudo emerge --ask =app-editors/tangent-0.11.6
```

Beta:

```bash
sudo emerge --ask =app-editors/tangent-0.12.0_beta8
```

Live git main:

```bash
sudo cp tangent-9999-vendor.tar.zst /var/cache/distfiles/
sudo emerge --ask =app-editors/tangent-9999
```

The live ebuild requires a local vendor cache tarball at `${DISTDIR}/tangent-9999-vendor.tar.zst` so it can build without npm network access.

## Notes

- This packaging is provided as-is and is not supported by upstream Tangent maintainers.
- The ebuilds package Tangent's bundled Electron runtime, following the current Discord/Logseq-style Gentoo packaging pattern.
- Enable `USE=wayland` to pass Electron Wayland flags through the launcher.

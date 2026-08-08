# Tangent Gentoo Overlay (Unofficial)

Ebuilds for [Tangent](https://www.tangentnotes.com), packaging [visrosa/Tangent](https://github.com/visrosa/Tangent) — a fork of [suchnsuch/Tangent](https://github.com/suchnsuch/Tangent) that adds Linux packaging on top of upstream. This overlay provides one package:

- `app-editors/tangent`

The package builds Tangent from source using offline-vendored npm/Electron cache inputs (no network access outside `src_fetch`), then installs the bundled Electron app produced by `electron-builder` under `/opt/tangent`, following the current Discord/Logseq-style Gentoo packaging pattern for bundled-Electron apps.

## Add this overlay

Using `eselect-repository`:

```bash
sudo eselect repository add tangent-overlay git https://github.com/visrosa/tangent-overlay.git
sudo emaint sync -r tangent-overlay
```

Or add it manually as a local overlay in `repos.conf`.

## Install

Stable:

```bash
sudo emerge --ask =app-editors/tangent-0.12.2
```

Pre-release:

```bash
sudo emerge --ask =app-editors/tangent-0.12.2_beta3
```

Live (tracks the fork's `dev` branch — unmerged feature work, ahead of any tagged release):

```bash
# Requires `gh auth login` once beforehand.
gh release download tangent-dev --repo visrosa/Tangent \
    --pattern 'tangent-dev-gentoo-vendor.tar.zst' \
    --output "$(portageq distdir)/tangent-9999-gentoo-vendor.tar.zst" \
    --clobber

sudo emerge --ask =app-editors/tangent-9999
```

`tangent-9999` needs a local vendor cache tarball at `${DISTDIR}/tangent-9999-gentoo-vendor.tar.zst` to build offline, fetched above from the fork's rolling `tangent-dev` release. This ebuild is a largely untested draft — expect rough edges.

## Updating

```bash
sudo emaint sync -r tangent-overlay
```

Then `emerge --ask =app-editors/tangent-<version>` as usual. `tangent-9999` re-resolves the `dev` branch tip on every emerge, so no version bump or overlay resync is needed to pick up new commits — just a fresh vendor tarball download (above) if it's been a while since the last one.

## Notes

- All ebuilds use `KEYWORDS="~amd64"` — this overlay stays at the testing keyword.
- This packaging is provided as-is and is not supported by upstream Tangent maintainers.
- Enable `USE=wayland` to pass Electron Wayland flags through to the launcher.

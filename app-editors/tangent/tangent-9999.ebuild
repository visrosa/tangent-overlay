# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop git-r3 unpacker xdg

DESCRIPTION="Your Notes, Your Thoughts; Your Tangent"
HOMEPAGE="https://github.com/visrosa/Tangent"
EGIT_REPO_URI="https://github.com/visrosa/Tangent.git"
EGIT_BRANCH="main"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="wayland"
RESTRICT="mirror splitdebug strip"

RDEPEND="
	dev-libs/nss
	dev-libs/openssl:0/3
	media-libs/alsa-lib
	media-libs/mesa
	net-misc/curl
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	virtual/zlib:=
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
"
BDEPEND="
	app-arch/zstd
	net-libs/nodejs[npm]
"

DESTDIR="/opt/${PN}"
QA_PREBUILT="*"

src_unpack() {
	git-r3_src_unpack

	local vendor_tarball="${DISTDIR}/${P}-gentoo-vendor.tar.zst"
	if [[ ! -f "${vendor_tarball}" ]]; then
		die "Missing ${vendor_tarball}. Create or download a live vendor cache tarball and place it in DISTDIR."
	fi

	cd "${S}" || die
	tar --zstd -xf "${vendor_tarball}" || die
}

src_configure() {
	default
	chromium_suid_sandbox_check_kernel_config
}

src_compile() {
	mkdir -p "${T}/home" "${T}/cache" || die
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export npm_config_cache="${S}/vendor/npm-cache"
	export NPM_CONFIG_CACHE="${S}/vendor/npm-cache"
	export npm_config_offline=true
	export npm_config_audit=false
	export npm_config_fund=false
	export npm_config_update_notifier=false
	export ELECTRON_CACHE="${S}/vendor/electron-cache"
	export ELECTRON_BUILDER_CACHE="${S}/vendor/electron-builder-cache"

	npm --cache "${S}/vendor/npm-cache" ci --workspaces --include-workspace-root --offline || die
	npm --cache "${S}/vendor/npm-cache" run build --workspace packages/tangent-query-parser || die
	npm --cache "${S}/vendor/npm-cache" run build --workspace packages/tangent-html-to-markdown || die
	npm --cache "${S}/vendor/npm-cache" run build --workspace lib/typewriter || die
	npm --cache "${S}/vendor/npm-cache" run build --workspace apps/tangent-electron || die
	npm --cache "${S}/vendor/npm-cache" exec --workspace apps/tangent-electron -- electron-builder --linux dir --x64 --publish never -c.linux.executableName=tangent || die
}

src_install() {
	local app_dir="apps/tangent-electron/dist/linux-unpacked"
	local app_exe="${app_dir}/tangent"
	[[ -x "${app_exe}" ]] || app_exe="${app_dir}/tangent_electron"

	pushd "${app_dir}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	exeinto "${DESTDIR}"
	newexe "${app_exe}" tangent
	doexe "${app_dir}/chrome-sandbox" "${app_dir}/libEGL.so" "${app_dir}/libffmpeg.so" "${app_dir}/libGLESv2.so" \
		"${app_dir}/libvk_swiftshader.so" "${app_dir}/libvulkan.so.1"

	insinto "${DESTDIR}"
	doins "${app_dir}/chrome_100_percent.pak" "${app_dir}/chrome_200_percent.pak" \
		"${app_dir}/icudtl.dat" "${app_dir}/resources.pak" \
		"${app_dir}/snapshot_blob.bin" "${app_dir}/v8_context_snapshot.bin" "${app_dir}/vk_swiftshader_icd.json"
	[[ -f "${app_dir}/version" ]] && doins "${app_dir}/version"
	insopts -m0755
	doins -r "${app_dir}/locales" "${app_dir}/resources"

	fowners root "${DESTDIR}/chrome-sandbox"
	fperms 4711 "${DESTDIR}/chrome-sandbox"

	[[ -x "${app_dir}/chrome_crashpad_handler" ]] && doins "${app_dir}/chrome_crashpad_handler"

	local exec_extra_flags=()
	if use wayland; then
		exec_extra_flags+=( "--ozone-platform-hint=auto" "--enable-wayland-ime" )
	fi

	sed \
		-e "s|@@DESTDIR@@|${DESTDIR}|g" \
		-e "s|@@WAYLAND_FLAGS@@|${exec_extra_flags[*]}|g" \
		"${FILESDIR}/${PN}" > "${T}/tangent" || die
	exeinto /usr/bin
	newexe "${T}/tangent" tangent

	make_desktop_entry --eapi9 "/usr/bin/tangent" -a "%U" -n Tangent -i tangent -c Office \
		-e "Terminal=false"
	newicon apps/tangent-electron/build/icon.png tangent.png || true
}

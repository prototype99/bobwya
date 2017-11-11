# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

PLOCALES="ar bg ca cs da de el en en_US eo es fa fi fr he hi hr hu it ja ko lt ml nb_NO nl or pa pl pt_BR pt_PT rm ro ru sk sl sr_RS@cyrillic sr_RS@latin sv te th tr uk wa zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit autotools flag-o-matic gnome2-utils l10n multilib multilib-minimal pax-utils toolchain-funcs virtualx versionator xdg-utils

MY_PN="${PN%%-*}"
MY_PV="${PV}"
version_component_count=$(get_version_component_count)
MY_P="${MY_PN}-${MY_PV}"
STAGING_SUFFIX=""
if [[ "${MY_PV}" == "9999" ]]; then
	#KEYWORDS=""
	EGIT_REPO_URI="https://source.winehq.org/git/wine.git"
	inherit git-r3
	SRC_URI=""
else
	last_component="$( get_version_component_range $((version_component_count)) )"
	if [[ "${last_component}" =~ ^rc[[:digit:]]+$ ]]; then
		rc_version=1
		MY_PV=$(replace_version_separator $((--version_component_count)) '''-''')
		MY_P="${MY_PN}-${MY_PV}"
		#KEYWORDS=""
	else
		rc_version=0
		KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
	fi
	major_version=$(get_major_version)
	minor_version=$(get_version_component_range 2)
	stable_version=$(( (major_version == 1 && (minor_version % 2 == 0)) || (major_version >= 2 && minor_version == 0) ))
	if (( stable_version && rc_version )); then
		# Pull Wine RC stable versions from alternate Github repostiory...
		STABLE_PREFIX="wine-stable"
		MY_P="${STABLE_PREFIX}-${MY_P}"
		SRC_URI="https://github.com/mstefani/wine-stable/archive/${MY_PN}-${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	elif (( (major_version < 2) || ((version_component_count == 2) && (major_version == 2) && (minor_version == 0)) )); then
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.${minor_version}/${MY_P}.tar.bz2 -> ${MY_P}.tar.bz2"
	elif (( (major_version == 2) && (minor_version == 0) )); then
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.0/${MY_P}.tar.xz -> ${MY_P}.tar.xz"
	else
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.x/${MY_P}.tar.xz -> ${MY_P}.tar.xz"
	fi
	((major_version == 1 && minor_version == 8)) && STAGING_SUFFIX="-unofficial"
fi
unset -v last_component minor_version major_version rc_version stable_version version_component_count

STAGING_P="wine-staging-${MY_PV}"
STAGING_DIR="${WORKDIR}/${STAGING_P}${STAGING_SUFFIX}"

GENTOO_WINE_EBUILD_COMMON_P="gentoo-wine-ebuild-common-20171106"
GENTOO_WINE_EBUILD_COMMON_PN="${GENTOO_WINE_EBUILD_COMMON_P%-*}"
GENTOO_WINE_EBUILD_COMMON_PV="${GENTOO_WINE_EBUILD_COMMON_P##*-}"

WINE_STAGING_GIT_HELPER_P="wine-staging-git-helper-0.1.8"
WINE_STAGING_GIT_HELPER_PN="${WINE_STAGING_GIT_HELPER_P%-*}"
WINE_STAGING_GIT_HELPER_PV="${WINE_STAGING_GIT_HELPER_P##*-}"

DESCRIPTION="Free implementation of Windows(tm) on Unix, with optional Wine Staging patchset"
HOMEPAGE="https://www.winehq.org/"
SRC_URI="${SRC_URI}
	https://github.com/bobwya/${GENTOO_WINE_EBUILD_COMMON_PN}/archive/${GENTOO_WINE_EBUILD_COMMON_PV}.tar.gz -> ${GENTOO_WINE_EBUILD_COMMON_P}.tar.gz"

if [[ "${MY_PV}" == "9999" ]]; then
	STAGING_EGIT_REPO_URI="https://github.com/wine-compholio/wine-staging.git"
	SRC_URI="${SRC_URI}
		staging? ( https://github.com/bobwya/${WINE_STAGING_GIT_HELPER_PN}/archive/${WINE_STAGING_GIT_HELPER_PV}.tar.gz -> ${WINE_STAGING_GIT_HELPER_P}.tar.gz )"
else
	SRC_URI="${SRC_URI}
		staging? ( https://github.com/wine-compholio/wine-staging/archive/v${MY_PV}${STAGING_SUFFIX}.tar.gz -> ${STAGING_P}.tar.gz )"
fi

LICENSE="LGPL-2.1"
SLOT="0"

IUSE="+abi_x86_32 +abi_x86_64 +alsa capi cuda cups custom-cflags dos elibc_glibc +fontconfig +gecko gphoto2 gsm gstreamer +jpeg kernel_FreeBSD +lcms ldap +mono mp3 ncurses netapi nls odbc openal opencl +opengl osmesa oss +perl pcap pipelight +png prelink pulseaudio +realtime +run-exes s3tc samba scanner selinux +ssl staging test themes +threads +truetype +udisks v4l vaapi +X +xcomposite xinerama +xml"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )
	X? ( truetype )
	cuda? ( staging )
	elibc_glibc? ( threads )
	mono? ( abi_x86_32 )
	osmesa? ( opengl )
	pipelight? ( staging )
	s3tc? ( staging )
	test? ( abi_x86_32 )
	s3tc? ( staging )
	themes? ( staging )
	vaapi? ( staging )" # osmesa-opengl #286560 # X-truetype #551124

# FIXME: the test suite is unsuitable for us; many tests require net access
# or fail due to Xvfb's opengl limitations.
RESTRICT="test"

COMMON_DEPEND="
	>=app-emulation/wine-desktop-common-20170822
	X? (
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
		x11-libs/libXi[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
	)
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	capi? ( net-libs/libcapi[${MULTILIB_USEDEP}] )
	cups? ( net-print/cups:=[${MULTILIB_USEDEP}] )
	fontconfig? ( media-libs/fontconfig:=[${MULTILIB_USEDEP}] )
	gphoto2? ( media-libs/libgphoto2:=[${MULTILIB_USEDEP}] )
	gsm? ( media-sound/gsm:=[${MULTILIB_USEDEP}] )
	gstreamer? (
		media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
		media-plugins/gst-plugins-meta:1.0[${MULTILIB_USEDEP}]
	)
	jpeg? ( virtual/jpeg:0=[${MULTILIB_USEDEP}] )
	lcms? ( media-libs/lcms:2=[${MULTILIB_USEDEP}] )
	ldap? ( net-nds/openldap:=[${MULTILIB_USEDEP}] )
	mp3? ( >=media-sound/mpg123-1.5.0[${MULTILIB_USEDEP}] )
	ncurses? ( >=sys-libs/ncurses-5.2:0=[${MULTILIB_USEDEP}] )
	netapi? ( net-fs/samba[netapi(+),${MULTILIB_USEDEP}] )
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	odbc? ( dev-db/unixODBC:=[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	opencl? ( virtual/opencl[${MULTILIB_USEDEP}] )
	opengl? (
		virtual/glu[${MULTILIB_USEDEP}]
		virtual/opengl[${MULTILIB_USEDEP}]
	)
	osmesa? ( >=media-libs/mesa-13[osmesa,${MULTILIB_USEDEP}] )
	pcap? ( net-libs/libpcap[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )
	scanner? ( media-gfx/sane-backends:=[${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	staging? ( sys-apps/attr[${MULTILIB_USEDEP}] )
	themes? (
		dev-libs/glib:2[${MULTILIB_USEDEP}]
		x11-libs/cairo[${MULTILIB_USEDEP}]
		x11-libs/gtk+:3[${MULTILIB_USEDEP}]
	)
	truetype? ( >=media-libs/freetype-2.0.5[${MULTILIB_USEDEP}] )
	udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	v4l? ( media-libs/libv4l[${MULTILIB_USEDEP}] )
	vaapi? ( x11-libs/libva[X,${MULTILIB_USEDEP}] )
	xcomposite? ( x11-libs/libXcomposite[${MULTILIB_USEDEP}] )
	xinerama? ( x11-libs/libXinerama[${MULTILIB_USEDEP}] )
	xml? (
		dev-libs/libxml2[${MULTILIB_USEDEP}]
		dev-libs/libxslt[${MULTILIB_USEDEP}]
	)
	abi_x86_32? (
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-baselibs-20140508-r14
		!app-emulation/emul-linux-x86-db[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-db-20140508-r3
		!app-emulation/emul-linux-x86-medialibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-medialibs-20140508-r6
		!app-emulation/emul-linux-x86-opengl[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-opengl-20140508-r1
		!app-emulation/emul-linux-x86-sdl[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-sdl-20140508-r1
		!app-emulation/emul-linux-x86-soundlibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-soundlibs-20140508
		!app-emulation/emul-linux-x86-xlibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-xlibs-20140508
	)"

RDEPEND="${COMMON_DEPEND}
	dos? ( >=games-emulation/dosbox-0.74_p20160629 )
	gecko? ( app-emulation/wine-gecko:2.40[abi_x86_32?,abi_x86_64?] )
	mono? ( app-emulation/wine-mono:4.5.6 )
	perl? (
		dev-lang/perl
		dev-perl/XML-Simple
	)
	pulseaudio? (
		realtime? ( sys-auth/rtkit )
	)
	s3tc? ( >=media-libs/libtxc_dxtn-1.0.1-r1[${MULTILIB_USEDEP}] )
	samba? ( >=net-fs/samba-3.0.25[winbind] )
	selinux? ( sec-policy/selinux-wine )
	udisks? ( sys-fs/udisks:2 )"

# tools/make_requests requires perl
DEPEND="${COMMON_DEPEND}
	dev-util/patchbin
	dev-lang/perl
	dev-perl/XML-Simple
	>=sys-devel/flex-2.5.33
	>=sys-kernel/linux-headers-2.6
	virtual/pkgconfig
	virtual/yacc
	X? (
		x11-proto/inputproto
		x11-proto/xextproto
		x11-proto/xf86vidmodeproto
	)
	prelink? ( sys-devel/prelink )
	xinerama? ( x11-proto/xineramaproto )"

S="${WORKDIR}/${MY_P}"

wine_env_vcs_variable_prechecks() {
	local pn_live_variable="${MY_PN//[-+]/_}_LIVE_COMMIT"
	local pn_live_value="${!pn_live_variable}"
	local env_error=0

	if [[ ! -z "${pn_live_value}" ]] && use staging; then
		eerror "Because ${PN} is multi-repository based, ${pn_live_variable}"
		eerror "cannot be used to set the commit."
		env_error=1
	fi
	[[ ! -z ${EGIT_COMMIT} || ! -z ${EGIT_BRANCH} ]] \
		&& env_error=1
	if (( env_error )); then
		eerror "Git commit (and branch) overrides must now be specified"
		eerror "using ONE of following the environmental variables:"
		eerror "  EGIT_WINE_COMMIT or EGIT_WINE_BRANCH (Wine)"
		eerror "  EGIT_STAGING_COMMIT or EGIT_STAGING_BRANCH (Wine Staging)."
		eerror
		return 1
	fi
}

wine_build_environment_prechecks() {
	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	local using_gcc using_clang gcc_major_version gcc_minor_version clang_major_version clang_minor_version
	using_gcc=$(tc-is-gcc)
	using_clang=$(tc-is-clang)
	gcc_major_version=$(gcc-major-version)
	gcc_minor_version=$(gcc-minor-version)
	clang_major_version=$(clang-major-version)
	clang_minor_version=$(clang-minor-version)

	if use abi_x86_64; then
		if (( using_gcc && ( gcc_major_version < 4 || (gcc_major_version == 4 && gcc_minor_version < 4) ) )); then
			eerror "You need >=sys-devel/gcc-4.4.x to compile 64-bit Wine"
			die "wine_build_environment_prechecks() failed"
		elif (( using_clang && ( clang_major_version < 3 || (clang_major_version == 3 && clang_minor_version < 8) ) )); then
			eerror "You need >=sys-devel/clang-3.8 to compile 64-bit wine"
			die "wine_build_environment_prechecks() failed"
		fi
		if (( using_gcc && (gcc_major_version == 5 && gcc_minor_version <= 3) )); then
			ewarn "=sys-devel/gcc-5.0.x ... =sys-devel/gcc-5.3.x - introduced compilation bugs"
			ewarn "and are no longer supported byGentoo's Toolchain Team."
			ewarn "If your ebuild fails the compiler checks in the src-configure phase then:"
			ewarn "update your compiler, switch to <sys-devel-gcc-5.0.x or >=sys-devel/gcc-5.4.x"
			ewarn "See https://bugs.gentoo.org/610752"
		fi
		if use abi_x86_32 && use opencl && [[ "$(eselect opencl show 2>/dev/null)" == "intel" ]]; then
			eerror "You cannot build wine with USE=+opencl because dev-util/intel-ocl-sdk is 64-bit only."
			eerror "See https://bugs.gentoo.org/487864"
			eerror
			return 1
		fi
	fi
}

wine_gcc_specific_pretests() {
	( [[ "${MERGE_TYPE}" = "binary" ]] || ! tc-is-gcc ) && return 0

	local using_abi_x86_64 gcc_major_version gcc_minor_version
	using_abi_x86_64=$(use abi_x86_64)
	gcc_major_version=$(gcc-major-version)
	gcc_minor_version=$(gcc-minor-version)

	# bug #549768
	if (( using_abi_x86_64 && (gcc_major_version == 5 && gcc_minor_version <= 2) )); then
		ebegin "(subshell): checking for =sys-devel/gcc-5.1.x , =sys-devel/gcc-5.2.0 MS X86_64 ABI compiler bug ..."
		( # Run in a subshell to prevent "Aborted" message
			$(tc-getCC) -O2 "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/files/pr66838.c" -o "${T}/pr66838" || die "cc compilation failed: pr66838 test"
			"${T}"/pr66838 &>/dev/null || die "pr66838 test failed"
		)
		if ! eend $?; then
			eerror "(subshell): =sys-devel/gcc-5.1.x , =sys-devel/gcc-5.2.0 MS X86_64 ABI compiler bug detected."
			eerror "64-bit wine cannot be built with =sys-devel/gcc-5.1 or initial patchset of =sys-devel/gcc-5.2.0."
			eerror "Please re-emerge wine using an unaffected version of gcc or apply"
			eerror "Re-emerge the latest =sys-devel/gcc-5.2.0 ebuild,"
			eerror "or use gcc-config to select a different compiler version."
			eerror "See https://bugs.gentoo.org/549768"
			eerror
			return 1
		fi
	fi

	# bug #574044
	if (( using_abi_x86_64 && (gcc_major_version == 5) && (gcc_minor_version == 3) )); then
		ebegin "(subshell): checking for =sys-devel/gcc-5.3.0 X86_64 misaligned stack compiler bug ..."
		( # Compile in a subshell to prevent "Aborted" message
			$(tc-getCC) -O2 -mincoming-stack-boundary=3 "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/files/pr69140.c" -o "${T}"/pr69140 &>/dev/null \
				|| die "pr69140 test failed"
		)
		if ! eend $?; then
			eerror "(subshell): =sys-devel/gcc-5.3.0 X86_64 misaligned stack compiler bug detected."
			eerror "Please re-emerge the latest =sys-devel/gcc-5.3.0 ebuild,"
			eerror "or use gcc-config to select a different compiler version."
			eerror "See https://bugs.gentoo.org/574044"
			eerror
			return 1
		fi
	fi
}

wine_generic_compiler_pretests() {
	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	if use abi_x86_64; then
		ebegin "(subshell): checking compiler support for (64-bit) builtin_ms_va_list ..."
		( # Compile in a subshell to prevent "Aborted" message
			$(tc-getCC) -O2 "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/files/builtin_ms_va_list.c" -o "${T}"/builtin_ms_va_list &>/dev/null || die "test for builtin_ms_va_list support failed"
		)
		if ! eend $?; then
			eerror "(subshell): $(tc-getCC) does not support builtin_ms_va_list."
			eerror "Please re-emerge using a compiler (version) that supports building 64-bit Wine."
			eerror "Use >=sys-devel/gcc-4.4 or >=sys-devel/clang-3.8 to build ${CATEGORY}/${PN}."
			eerror
			return 1
		fi
	fi
}

pkg_pretend() {
	if use oss && ! use kernel_FreeBSD && ! has_version '>=media-sound/oss-4'; then
		eerror "You cannot build ${CATEGORY}/${PN} with USE=+oss without having support from a FreeBSD kernel"
		eerror "or >=media-sound/oss-4 (only available through an Overlay)."
		die "USE=+oss currently unsupported on this system."
	fi

	einfo "For information about the packaging of Wine in the ::bobwya Overlay"
	einfo "please read the Github homepage overview: https://github.com/bobwya/bobwya"
}

pkg_setup() {
	wine_env_vcs_variable_prechecks || die "wine_env_vcs_variable_prechecks() failed"
	wine_build_environment_prechecks || die "wine_build_environment_prechecks() failed"
}

src_unpack() {
	default
	if [[ "${MY_PV}" == "9999" ]]; then
		# Fully Mirror git tree, Wine, so we can access commits in all branches
		EGIT_MIN_CLONE_TYPE="mirror"
		EGIT_CHECKOUT_DIR="${S}"
		if ! use staging; then
			wine_git_unpack "${S}"
		elif [[ ! -z "${EGIT_STAGING_COMMIT:-${EGIT_STAGING_BRANCH}}" ]]; then
			# References are relative to Wine Staging git tree (checkout Wine Staging git tree first)
			# Use env variables "EGIT_STAGING_COMMIT" or "EGIT_STAGING_BRANCH" to reference Wine Staging git tree
			# Use git-r3 internal functions for secondary Wine Staging repository. See #588604
			ebegin "(subshell): Wine Staging git reference specified. Building Wine git with Wine Staging patchset ..."
			(
				# shellcheck source=/dev/null
				source "${WORKDIR%/}/${WINE_STAGING_GIT_HELPER_P%/}/${WINE_STAGING_GIT_HELPER_PN}.sh" || die
				if [[ ! -z "${EGIT_STAGING_COMMIT}" ]]; then
					ewarn "Building Wine against Wine Staging git commit EGIT_STAGING_COMMIT=\"${EGIT_STAGING_COMMIT}\" ."
					git-r3_fetch "${STAGING_EGIT_REPO_URI}" "${EGIT_STAGING_COMMIT}"
				else
					ewarn "Building Wine against Wine Staging git branch EGIT_STAGING_BRANCH=\"${EGIT_STAGING_BRANCH}\" ."
					git-r3_fetch "${STAGING_EGIT_REPO_URI}" "refs/heads/${EGIT_STAGING_BRANCH}"
				fi
				git-r3_checkout "${STAGING_EGIT_REPO_URI}" "${STAGING_DIR}"
				wine_staging_target_commit="${EGIT_VERSION}"
				get_upstream_wine_commit  "${STAGING_DIR}" "${wine_staging_target_commit}" "wine_commit"
				EGIT_COMMIT="${wine_commit}" git-r3_src_unpack
				einfo "Building Wine commit \"${wine_commit}\" referenced by Wine Staging commit \"${wine_staging_target_commit}\" ..."
			)
			eend $? || die "(subshell): ... failed to determine target Wine commit."
		else
			# References are relative to Wine git tree (post-checkout Wine Staging git tree)
			# Use env variables "EGIT_WINE_COMMIT" or "EGIT_WINE_BRANCH" to reference Wine git tree
			# Use git-r3 internal functions for secondary Wine Staging repository. See #588604
			ebegin "(subshell): Wine git reference specified or inferred. Building Wine git with with Wine Staging patchset ..."
			(
				# shellcheck source=/dev/null
				source "${WORKDIR%/}/${WINE_STAGING_GIT_HELPER_P%/}/${WINE_STAGING_GIT_HELPER_PN}.sh" || die
				wine_git_unpack "${S}"
				wine_commit="${EGIT_VERSION}"
				wine_target_commit="${wine_commit}"
				git-r3_fetch "${STAGING_EGIT_REPO_URI}" "HEAD"
				git-r3_checkout "${STAGING_EGIT_REPO_URI}" "${STAGING_DIR}"
				wine_staging_commit=""; wine_commit_offset=""
				if ! walk_wine_staging_git_tree "${STAGING_DIR}" "${S}" "${wine_commit}" "wine_staging_commit" ; then
					find_closest_wine_commit "${STAGING_DIR}" "${S}" "wine_commit" "wine_staging_commit" "wine_commit_offset" \
						&& display_closest_wine_commit_message "${wine_commit}" "${wine_staging_commit}" "${wine_commit_offset}"
					die "Failed to find Wine Staging git commit corresponding to supplied Wine git commit \"${wine_target_commit}\" ."
				fi
				einfo "Building Wine Staging commit \"${wine_staging_commit}\" corresponding to Wine commit \"${wine_target_commit}\" ..."
			)
			eend $? || die "(subshell): ... failed to determine target Wine Staging commit."
		fi
	fi

	l10n_find_plocales_changes "${S}/po" "" ".po"
}

src_prepare() {

	eapply_bin() {
		local patch
		# shellcheck disable=SC2068
		for patch in ${PATCHES_BIN[@]}; do
			patchbin --nogit < "${patch}" || die "patchbin failed"
		done
	}

	local md5hash
	md5hash="$(md5sum server/protocol.def || die "md5sum")"
	[[ ! -z "${STABLE_PREFIX}" ]] && sed -i -e 's/[\-\.[:alnum:]]\+$/'"${MY_PV}"'/' "${S}/VERSION"
	local -a PATCHES PATCHES_BIN
	PATCHES+=(
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.8_winecfg_detailed_version.patch"
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.5.26-winegcc.patch" #260726
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.6-memset-O3.patch" #480508
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.9.13-gnutls-3.5-compat.patch" #587028
	)
	if use truetype; then
		PATCHES+=(
			"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.18-freetype-2.8.1-segfault.patch"    # 631676
			"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.18-freetype-2.8.1-drop-glyphs.patch" # 631676
		)
		PATCHES_BIN+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.18-freetype-2.8.1-implement_minimum_em_size_required_by_opentype_1.8.2.patch" ) #631376
	fi
	use osmesa && PATCHES+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.7-osmesa-configure_support_recent_versions.patch" ) #429386

	# https://bugs.winehq.org/show_bug.cgi?id=40851
	use cups && PATCHES+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.9.14-cups-2.2-cupsgetppd-build-fix.patch" )

	# https://bugs.winehq.org/show_bug.cgi?id=31836
	use gstreamer && PATCHES+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.8-gstreamer-1.0_"{01,02,03,04,05,06,07,09,10,11}".patch" )

	[[ "${MY_PV}" == "9999" ]] && sieve_patchset_array_by_git_commit "${S}" "PATCHES" "PATCHES_BIN"

	#395615 - run bash/sed script, combining both versions of the multilib-portage.patch
	ebegin "(subshell) script: \"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/scripts/${MY_PN}-multilib-portage-sed.sh\" ..."
	(
		# shellcheck disable=SC1090
		source "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/scripts/${MY_PN}-multilib-portage-sed.sh" || die
	)
	eend $? || die "(subshell) script: \"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/scripts/${MY_PN}-multilib-portage-sed.sh\"."

	if use staging; then
		ewarn "Applying the Wine Staging patchset. Any bug reports to Wine Bugzilla"
		ewarn "should explicitly state that Wine Staging was used."

		# Declare Wine Staging excluded patchsets
		local -a STAGING_EXCLUDE_PATCHSETS=( "configure-OSMesa" "winhlp32-Flex_Workaround" )
		use gstreamer && STAGING_EXCLUDE_PATCHSETS+=( "quartz-NULL_TargetFormat" )
		use cuda || STAGING_EXCLUDE_PATCHSETS+=( "nvapi-Stub_DLL" "nvcuda-CUDA_Support" "nvcuvid-CUDA_Video_Support" "nvencodeapi-Video_Encoder" )
		use pipelight || STAGING_EXCLUDE_PATCHSETS+=( "Pipelight" )

		# Process Wine Staging exluded patchsets
		local indices=( ${!STAGING_EXCLUDE_PATCHSETS[*]} )
		for ((i=0; i<${#indices[*]}; i++)); do
			if grep -q "${STAGING_EXCLUDE_PATCHSETS[indices[i]]}" "${STAGING_DIR}/patches/patchinstall.sh"; then
				einfo "Excluding Wine Staging patchset: \"${STAGING_EXCLUDE_PATCHSETS[indices[i]]}\""
			else
				unset -v 'STAGING_EXCLUDE_PATCHSETS[indices[i]]'
			fi
		done

		# Launch wine-staging patcher in a subshell, using epatch as a backend, and gitapply.sh as a backend for binary patches
		ebegin "Running Wine-Staging patch installer"
		(
			# shellcheck disable=SC2068
			set -- DESTDIR="${S}" --backend=epatch --no-autoconf --all ${STAGING_EXCLUDE_PATCHSETS[@]/#/-W }
			cd "${STAGING_DIR}/patches" || die "cd failed"
			# shellcheck source=/dev/null
			source "${STAGING_DIR}/patches/patchinstall.sh"
		)
		eend $? || die "(subshell) script: failed to apply Wine Staging patches (excluding: \"${STAGING_EXCLUDE_PATCHSETS[*]}\")."

		# Apply Staging branding to reported Wine version...
		sed -r -i -e '/^AC_INIT\(.*\)$/{s/\[Wine\]/\[Wine Staging\]/}' "${S}/configure.ac" || die "sed failed"
		if [[ ! -z "${STAGING_SUFFIX}" ]]; then
			sed -i -e 's/Staging/Staging'"${STAGING_SUFFIX}"'/' "${S}/libs/wine/Makefile.in" || die "sed failed"
		fi
	fi

	default

	eapply_bin
	eautoreconf

	# Modification of the server protocol requires regenerating the server requests
	if ! md5sum -c - <<<"${md5hash}" &>/dev/null; then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die "tools/make_requests failed" #432348
	fi
	sed -i '/^UPDATE_DESKTOP_DATABASE/s:=.*:=true:' tools/Makefile.in || die "sed failed"
	if ! use run-exes; then
		sed -i '/^MimeType/d' "${S}/loader/wine.desktop" || die "sed failed" #117785
	fi

	# hi-res default icon, #472990, https://bugs.winehq.org/show_bug.cgi?id=24652
	cp "${EROOT%/}/usr/share/wine/icons/oic_winlogo.ico" dlls/user32/resources/ || die "cp failed"

	l10n_get_locales > "${S}/po/LINGUAS" || die "l10n_get_locales failed" # Make Wine respect LINGUAS
}

src_configure() {
	wine_gcc_specific_pretests || die "wine_gcc_specific_pretests() failed"
	wine_generic_compiler_pretests || die "wine_generic_compiler_pretests() failed"

	export LDCONFIG="/bin/true"
	use custom-cflags || strip-flags

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local myconf=(
		$(use_with alsa)
		$(use_with capi)
		$(use_with lcms cms)
		$(use_with cups)
		$(use_with ncurses curses)
		$(use_with fontconfig)
		$(use_with ssl gnutls)
		$(use_enable gecko mshtml)
		$(use_with gphoto2 gphoto)
		$(use_with gsm)
		$(use_with gstreamer)
		--without-hal
		$(use_with jpeg)
		$(use_with ldap)
		$(use_enable mono mscoree)
		$(use_with mp3 mpg123)
		$(use_with netapi)
		$(use_with nls gettext)
		$(use_with openal)
		$(use_with opencl)
		$(use_with opengl)
		$(use_with osmesa)
		$(use_with oss)
		$(use_with pcap)
		$(use_with png)
		$(use_with pulseaudio pulse)
		$(use_with threads pthread)
		$(use_with scanner sane)
		$(use_enable test tests)
		$(use_with truetype freetype)
		$(use_with udisks dbus)
		$(use_with v4l)
		$(use_with X x)
		$(use_with xcomposite)
		$(use_with xinerama)
		$(use_with xml)
		$(use_with xml xslt)
	)

	use staging && myconf+=(
		--with-xattr
		$(use_with themes gtk3)
		$(use_with vaapi va)
	)

	local PKG_CONFIG AR RANLIB
	# Avoid crossdev's i686-pc-linux-gnu-pkg-config if building wine32 on amd64; #472038
	# set AR and RANLIB to make QA scripts happy; #483342
	tc-export PKG_CONFIG AR RANLIB

	if use amd64; then
		if [[ ${ABI} == amd64 ]]; then
			myconf+=( --enable-win64 )
		else
			myconf+=( --disable-win64 )
		fi

		# Note: using --with-wine64 results in problems with multilib.eclass
		# CC/LD hackery. We're using separate tools instead.
	fi

	ECONF_SOURCE=${S} \
		econf "${myconf[@]}"
	emake depend
}

multilib_src_test() {
	# FIXME: win32-only; wine64 tests fail with "could not find the Wine loader"
	if [[ "${ABI}" == "x86" ]]; then
		if [[ "$(id -u)" == "0" ]]; then
			ewarn "Skipping tests since they cannot be run under the root user."
			ewarn "To run the test ${MY_PN} suite, add userpriv to FEATURES in make.conf"
			return
		fi
		WINEPREFIX="${T}/.wine-${ABI}" \
			Xemake test
	fi
}

multilib_src_install_all() {
	DOCS=( "ANNOUNCE" "AUTHORS" "README" )
	add_locale_docs() {
		local locale_doc="documentation/README.${1}"
		[[ ! -e "S{S}/${locale_doc}" ]] || DOCS+=( "${locale_doc}" )
	}
	l10n_for_each_locale_do add_locale_docs

	einstalldocs
	unset -v DOCS

	prune_libtool_files --all

	if ! use perl; then  # winedump calls function_grep.pl, and winemaker is a perl script
		rm "${D%/}/usr/bin"/{wine{dump,maker},function_grep.pl} || die "rm failed"
		rm "${D%/}/usr/share/man/man1/wine"{dump,maker}.1 || die "rm failed"
	fi

	# Remove wineconsole if neither backend is installed #551124
	if ! use X && ! use ncurses; then
		rm "${D%/}/usr/bin/wineconsole"* || die "rm failed"
		rm "${D%/}/usr/share/man/man1/wineconsole"* || die "rm failed"

		rm_wineconsole() {
			rm "/usr/$(get_libdir)/wine"/{,fakedlls/}wineconsole.exe* || die "rm failed"
		}
		multilib_foreach_abi rm_wineconsole
	fi

	use abi_x86_32 && pax-mark psmr "${D%/}/usr/bin/wine"{,-preloader}   #255055
	use abi_x86_64 && pax-mark psmr "${D%/}/usr/bin/wine64"{,-preloader} #255055

	if use abi_x86_64 && ! use abi_x86_32; then
		dosym "wine64" "/usr/bin/wine"                     #404331
		dosym "wine64-preloader" "/usr/bin/wine-preloader" #404331
	fi

	# respect LINGUAS when installing man pages, #469418
	local locale_man locale_man_directory
	for locale_man in "de" "fr" "pl"; do
		while IFS= read -r -d '' locale_man_directory; do
			use linguas_${locale_man} && continue

			rm -r "${locale_man_directory}" || die "rm failed"
		done < <(find "${D%/}/usr/share/man" -mindepth 1 -maxdepth 1 -type d \
			\( -name "${locale_man}" -o -name "${locale_man}.*" \) -print0 -exec false {} + \
				&& die "find failed - no \"${locale_man}\" locale manpage directory matches in \"${D%/}/usr/share/man\""
			)
	done
}

pkg_postinst() {
	xdg_mimeinfo_database_update

	if ! use gecko; then
		ewarn "Without Wine Gecko, wine prefixes will not have a default"
		ewarn "implementation of iexplore.  Many older windows applications"
		ewarn "rely upon the existence of an iexplore implementation, so"
		ewarn "you will likely need to install an external one, using winetricks."
	fi
	if ! use mono; then
		ewarn "Without Wine Mono, wine prefixes will not have a default"
		ewarn "implementation of .NET.  Many windows applications rely upon"
		ewarn "the existence of a .NET implementation, so you will likely need"
		ewarn "to install an external one, using winetricks."
	fi
}
pkg_postrm() {
	xdg_mimeinfo_database_update
}

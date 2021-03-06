# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

DESCRIPTION="Tool and library to extract CAB files from InstallShield installers"
HOMEPAGE="https://github.com/twogood/unshield"

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/twogood/${PN}.git"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
else
	SRC_URI="https://github.com/twogood/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~hppa ~ppc ~x86"
fi

LICENSE="MIT"
SLOT="0"

IUSE="libressl static-libs"

RDEPEND="
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	sys-libs/zlib"
DEPEND="${RDEPEND}"

src_prepare() {
	eapply_user
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		--with-ssl
		$(use_with static-libs static)
	)
	cmake-utils_src_configure
}

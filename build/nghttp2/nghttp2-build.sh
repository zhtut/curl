#!/bin/bash
# This script downlaods and builds the iOS  nghttp2 libraries
#
# Credits:
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
#
# NGHTTP2 - https://github.com/nghttp2/nghttp2
#

# > nghttp2 is an implementation of HTTP/2 and its header
# > compression algorithm HPACK in C
#
# NOTE: pkg-config is required

# --- Edit this to update version ---

NGHTTP2_VERSION="nghttp2-1.55.1"
DEVELOPER=$(xcode-select -print-path)

# Check to see if pkg-config is already installed
if (type "pkg-config" >/dev/null); then
	echo "pkg-config already installed"
else
	echo -e "${alertdim}** WARNING: pkg-config not installed... attempting to install.${dim}"

	# Check to see if Brew is installed
	if ! type "brew" >/dev/null; then
		echo -e "${alert}** FATAL ERROR: brew not installed - unable to install pkg-config - exiting.${normal}"
		exit
	else
		echo "  brew installed - using to install pkg-config"
		brew install pkg-config
	fi

	# Check to see if installation worked
	if (type "pkg-config" >/dev/null); then
		echo "  SUCCESS: pkg-config installed"
	else
		echo -e "${alert}** FATAL ERROR: pkg-config failed to install - exiting.${normal}"
		exit
	fi
fi

build() {
	ARCH=$1
	PLATFORM=$2

	pushd . >/dev/null
	cd "${NGHTTP2_VERSION}"

	CC_BITCODE_FLAG="-fembed-bitcode"

	sdk_cfg="-isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
	arch_cfg="-arch ${ARCH}"
	if [[ "${PLATFORM}" == "MacOSX" ]]; then
		export DEPLOYMENT_TARGET=10.13
		min_version="-mmacosx-version-min=$DEPLOYMENT_TARGET"
	else
		export DEPLOYMENT_TARGET=9.0
		if [[ "${PLATFORM}" == "iPhoneOS" ]]; then
			min_version="-miphoneos-version-min=$DEPLOYMENT_TARGET"
		else
			min_version="-miphonesimulator-version-min=$DEPLOYMENT_TARGET"
		fi
	fi
	export CFLAGS="${arch_cfg} ${sdk_cfg} ${CC_BITCODE_FLAG} ${min_version}"

	echo -e "Building ${NGHTTP2_VERSION} for ${PLATFORM} ${ARCH}"

	host_cfg="--host=${ARCH}-apple-darwin"

	common_cfg="--disable-shared --enable-lib-only"
	destination_path="${build_dir}/${PLATFORM}/${ARCH}"
	mkdir -p ${destination_path}
	prefix_cfg="--prefix=${destination_path}"
	./configure ${common_cfg} ${prefix_cfg} ${host_cfg}
	if [[ $? == 0 ]]; then
		echo "./configure 完成，开始make"
	else
		echo "./configure 失败"
		exit 1
	fi

	make -j8
	if [[ $? == 0 ]]; then
		echo "make完成，开始install"
	else
		echo "make失败"
		exit 1
	fi

	make install
	if [[ $? == 0 ]]; then
		echo "install完成，开始clean"
	else
		echo "install失败"
		exit 1
	fi

	make clean
	popd >/dev/null
}

build_dir="$(pwd)/build"

echo -e "${bold}Cleaning up${dim}"
rm -rf ${build_dir}

mkdir -p ${build_dir}

rm -rf "${NGHTTP2_VERSION}"

if [ ! -e ${NGHTTP2_VERSION}.tar.gz ]; then
	echo "Downloading ${NGHTTP2_VERSION}.tar.gz"
	version_number=${NGHTTP2_VERSION#*-}
	curl -LO https://github.com/nghttp2/nghttp2/releases/download/v${version_number}/${NGHTTP2_VERSION}.tar.gz
else
	echo "Using ${NGHTTP2_VERSION}.tar.gz"
fi

echo "Unpacking nghttp2"
tar xfz "${NGHTTP2_VERSION}.tar.gz"

echo -e "${bold}Building iOS libraries (bitcode)${dim}"
build "armv7" "iPhoneOS"
build "arm64" "iPhoneSimulator"
build "arm64" "iPhoneOS"
build "x86_64" "iPhoneSimulator"
build "arm64" "MacOSX"
build "x86_64" "MacOSX"

rm -rf "${NGHTTP2_VERSION}.tar.gz"
rm -rf "${NGHTTP2_VERSION}"

echo -e "${normal}Done"

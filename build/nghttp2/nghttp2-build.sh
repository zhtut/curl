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

set -e

NGHTTP2_VERSION="nghttp2-1.58.0"

CC_BITCODE_FLAG="-fembed-bitcode"
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
	min_version=$3

	sdk_cfg="-isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
	arch_cfg="-arch ${ARCH}"

	export CFLAGS="${arch_cfg} ${sdk_cfg} ${CC_BITCODE_FLAG} ${min_version}"

	echo -e "Building ${NGHTTP2_VERSION} for ${PLATFORM} ${ARCH}"

#	host_cfg="--host=${ARCH}-apple-darwin"
	host_cfg="--host=arm64-apple-darwin"

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

cd "${NGHTTP2_VERSION}"
build "armv7" "iPhoneOS" "-miphoneos-version-min=9.0"
build "arm64" "iPhoneOS" "-miphoneos-version-min=9.0"
build "arm64" "iPhoneSimulator" "-miphonesimulator-version-min=9.0"
build "x86_64" "iPhoneSimulator" "-miphonesimulator-version-min=9.0"
build "arm64" "MacOSX" "-mmacosx-version-min=10.13"
build "x86_64" "MacOSX" "-mmacosx-version-min=10.13"
build "arm64" "AppleTVOS" "-mappletvos-version-min=9.0"
build "arm64" "AppleTVSimulator" "-mappletvsimulator-version-min=9.0"
build "x86_64" "AppleTVSimulator" "-mappletvsimulator-version-min=9.0"
build "arm64" "WatchOS" "-mwatchos-version-min=4.0"
build "arm64_32" "WatchOS" "-mwatchos-version-min=4.0"
build "arm64" "WatchSimulator" "-mwatchsimulator-version-min=4.0"
build "x86_64" "WatchSimulator" "-mwatchsimulator-version-min=4.0"
cd ..

echo -e "Cleaning up"
rm -rf "${NGHTTP2_VERSION}.tar.gz"
rm -rf "${NGHTTP2_VERSION}"

echo -e "${normal}Done"

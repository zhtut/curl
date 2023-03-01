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

NGHTTP2_VERNUM="1.52.0"
IOS_MIN_SDK_VERSION="7.1"

# --- Edit this to update version ---

NGHTTP2_VERSION="nghttp2-${NGHTTP2_VERNUM}"
DEVELOPER=$(xcode-select -print-path)

# Check to see if pkg-config is already installed
if (type "pkg-config" >/dev/null); then
	echo "  pkg-config already installed"
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

	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} ${CC_BITCODE_FLAG}"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"

	log_path="${build_dir}/${NGHTTP2_VERSION}-${PLATFORM}-${ARCH}.log"

	echo -e "${subbold}Building ${NGHTTP2_VERSION} for ${PLATFORM} ${archbold}${ARCH}${dim}"

	# if [[ "${ARCH}" == "arm64" || "${ARCH}" == "arm64e" ]]; then
	# 	host_cfg=--host="arm-apple-darwin"
	# else
	host_cfg=--host="${ARCH}-apple-darwin"
	# fi

	common_cfg="--disable-shared --disable-app --disable-threads --enable-lib-only"
	./configure ${common_cfg} --prefix="${build_dir}/${PLATFORM}/${ARCH}" "${host_cfg}" &>"${log_path}"
	if [[ $? == 0 ]]; then
		echo "./configure 完成，开始make"
	else
		echo "./configure 失败"
		exit 1
	fi

	make -j8 >>"${log_path}" 2>&1
	if [[ $? == 0 ]]; then
		echo "make完成，开始install"
	else
		echo "make失败"
		exit 1
	fi

	make install >>"${log_path}" 2>&1
	if [[ $? == 0 ]]; then
		echo "install完成，开始clean"
	else
		echo "install失败"
		exit 1
	fi
	make clean >>"${log_path}" 2>&1
	popd >/dev/null
}

build_dir="$(pwd)/build"

echo -e "${bold}Cleaning up${dim}"
rm -rf ${build_dir}

mkdir -p ${build_dir}

rm -rf "${NGHTTP2_VERSION}"

if [ ! -e ${NGHTTP2_VERSION}.tar.gz ]; then
	echo "Downloading ${NGHTTP2_VERSION}.tar.gz"
	curl -LO https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERNUM}/${NGHTTP2_VERSION}.tar.gz
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

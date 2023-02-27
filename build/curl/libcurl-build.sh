#!/bin/bash

# This script downlaods and builds the Mac, iOS and tvOS libcurl libraries with Bitcode enabled

# Credits:
#
# Felix Schwarz, IOSPIRIT GmbH, @@felix_schwarz.
#   https://gist.github.com/c61c0f7d9ab60f53ebb0.git
# Bochun Bai
#   https://github.com/sinofool/build-libcurl-ios
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
# Preston Jennings
#   https://github.com/prestonj/Build-OpenSSL-cURL

set -e

# Formatting
default="\033[39m"
wihte="\033[97m"
green="\033[32m"
red="\033[91m"
yellow="\033[33m"

bold="\033[0m${green}\033[1m"
subbold="\033[0m${green}"
archbold="\033[0m${yellow}\033[1m"
normal="${white}\033[0m"
dim="\033[0m${white}\033[2m"
alert="\033[0m${red}\033[1m"
alertdim="\033[0m${red}\033[2m"

CURL_VERSION="curl-7.88.1"
IOS_SDK_VERSION=""
IOS_MIN_SDK_VERSION="7.1"
IPHONEOS_DEPLOYMENT_TARGET="9.0"

DEVELOPER=$(xcode-select -print-path)

build_dir="build"
mkdir -p ${build_dir}

buildIOS() {
	ARCH=$1
	BITCODE=$2

	pushd . >/dev/null
	cd "${CURL_VERSION}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi

	CC_BITCODE_FLAG="-fembed-bitcode"

	NGHTTP2CFG="--with-nghttp2=${NGHTTP2}/iOS/${ARCH}"
	NGHTTP2LIB="-L${NGHTTP2}/iOS/${ARCH}/lib"

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} ${NGHTTP2LIB}"

	echo -e "${subbold}Building ${CURL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim} ${BITCODE}"

	# 用编译出来的一直找不到error: --with-openssl was given but OpenSSL could not be detected，说明--with-openssl用法有问题，还不如用系统的签
	SSL_CFG="--with-secure-transport"

	if [[ "${ARCH}" == *"arm64"* || "${ARCH}" == "arm64e" ]]; then
		./configure -prefix="${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}" --disable-shared --enable-static -with-random=/dev/urandom ${SSL_CFG} ${NGHTTP2CFG} --host="arm-apple-darwin" &>"${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	else
		./configure -prefix="${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}" --disable-shared --enable-static -with-random=/dev/urandom ${SSL_CFG} ${NGHTTP2CFG} --host="${ARCH}-apple-darwin" &>"${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	fi

	make -j8 >>"${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make install >>"${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make clean >>"${build_dir}/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	popd >/dev/null
}

echo -e "${bold}Cleaning up${dim}"
rm -rf include/curl/* lib/*

mkdir -p lib
mkdir -p include/curl/

rm -rf "${build_dir}/${CURL_VERSION}-*"
rm -rf "${build_dir}/${CURL_VERSION}-*.log"

rm -rf "${CURL_VERSION}"

if [ ! -e ${CURL_VERSION}.tar.gz ]; then
	echo "Downloading ${CURL_VERSION}.tar.gz"
	curl -LO https://curl.haxx.se/download/${CURL_VERSION}.tar.gz
else
	echo "Using ${CURL_VERSION}.tar.gz"
fi

echo "Unpacking curl"
tar xfz "${CURL_VERSION}.tar.gz"

echo -e "${bold}Building iOS libraries (bitcode)${dim}"
buildIOS "armv7" "bitcode"
buildIOS "armv7s" "bitcode"
buildIOS "arm64" "bitcode"
buildIOS "arm64e" "bitcode"
buildIOS "x86_64" "bitcode"
buildIOS "i386" "bitcode"

lipo \
	"${build_dir}/${CURL_VERSION}-iOS-armv7-bitcode/lib/libcurl.a" \
	"${build_dir}/${CURL_VERSION}-iOS-armv7s-bitcode/lib/libcurl.a" \
	"${build_dir}/${CURL_VERSION}-iOS-i386-bitcode/lib/libcurl.a" \
	"${build_dir}/${CURL_VERSION}-iOS-arm64-bitcode/lib/libcurl.a" \
	"${build_dir}/${CURL_VERSION}-iOS-arm64e-bitcode/lib/libcurl.a" \
	"${build_dir}/${CURL_VERSION}-iOS-x86_64-bitcode/lib/libcurl.a" \
	-create -output lib/libcurl_iOS.a

echo -e "${bold}Cleaning up${dim}"
# rm -rf ${build_dir}/${CURL_VERSION}-*
# rm -rf ${CURL_VERSION}

echo "Checking libraries"
xcrun -sdk iphoneos lipo -info lib/*.a

#reset trap
trap - INT TERM EXIT

echo -e "${normal}Done"

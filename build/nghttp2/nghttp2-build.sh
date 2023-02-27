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

# set trap to help debug build errors
trap 'echo -e "${alert}** ERROR with Build - Check /tmp/nghttp2*.log${alertdim}"; tail -3 /tmp/nghttp2*.log' INT TERM EXIT

NGHTTP2_VERNUM="1.40.0"
IOS_MIN_SDK_VERSION="7.1"
IOS_SDK_VERSION=""

usage() {
	echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-v ${dim}<nghttp2 version>${normal}] [-s ${dim}<iOS SDK version>${normal}] [-t ${dim}<tvOS SDK version>${normal}] [-x] [-h]"
	echo
	echo "         -v   version of nghttp2 (default $NGHTTP2_VERNUM)"
	echo "         -s   iOS SDK version (default $IOS_MIN_SDK_VERSION)"
	echo "         -t   tvOS SDK version (default $TVOS_MIN_SDK_VERSION)"
	echo "         -x   disable color output"
	echo "         -h   show usage"
	echo
	trap - INT TERM EXIT
	exit 127
}

while getopts "v:s:t:xh\?" o; do
	case "${o}" in
	v)
		NGHTTP2_VERNUM="${OPTARG}"
		;;
	s)
		IOS_SDK_VERSION="${OPTARG}"
		;;
	t)
		TVOS_SDK_VERSION="${OPTARG}"
		;;
	x)
		bold=""
		subbold=""
		normal=""
		dim=""
		alert=""
		alertdim=""
		archbold=""
		;;
	*)
		usage
		;;
	esac
done
shift $((OPTIND - 1))

# --- Edit this to update version ---

NGHTTP2_VERSION="nghttp2-${NGHTTP2_VERNUM}"
DEVELOPER=$(xcode-select -print-path)

NGHTTP2="${PWD}/../nghttp2"

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

buildIOS() {
	ARCH=$1
	BITCODE=$2

	pushd . >/dev/null
	cd "${NGHTTP2_VERSION}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi

	if [[ "${BITCODE}" == "nobitcode" ]]; then
		CC_BITCODE_FLAG=""
	else
		CC_BITCODE_FLAG="-fembed-bitcode"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"

	echo -e "${subbold}Building ${NGHTTP2_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim}"
	if [[ "${ARCH}" == "arm64" || "${ARCH}" == "arm64e" ]]; then
		./configure --disable-shared --disable-app --disable-threads --enable-lib-only --prefix="${NGHTTP2}/iOS/${ARCH}" --host="arm-apple-darwin" &>"/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	else
		./configure --disable-shared --disable-app --disable-threads --enable-lib-only --prefix="${NGHTTP2}/iOS/${ARCH}" --host="${ARCH}-apple-darwin" &>"/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	fi

	make -j8 >>"/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make install >>"/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make clean >>"/tmp/${NGHTTP2_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	popd >/dev/null
}

echo -e "${bold}Cleaning up${dim}"
rm -rf include/nghttp2/* lib/*
rm -fr iOS

mkdir -p lib

rm -rf "/tmp/${NGHTTP2_VERSION}-*"
rm -rf "/tmp/${NGHTTP2_VERSION}-*.log"

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
buildIOS "armv7" "bitcode"
buildIOS "armv7s" "bitcode"
buildIOS "arm64" "bitcode"
buildIOS "arm64e" "bitcode"
buildIOS "x86_64" "bitcode"
buildIOS "i386" "bitcode"

lipo \
	"${NGHTTP2}/iOS/armv7/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/armv7s/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/i386/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/arm64e/lib/libnghttp2.a" \
	"${NGHTTP2}/iOS/x86_64/lib/libnghttp2.a" \
	-create -output "${NGHTTP2}/lib/libnghttp2_iOS.a"

echo -e "${bold}Cleaning up${dim}"
rm -rf /tmp/${NGHTTP2_VERSION}-*
rm -rf ${NGHTTP2_VERSION}

#reset trap
trap - INT TERM EXIT

echo -e "${normal}Done"

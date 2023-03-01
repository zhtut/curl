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

CURL_VERSION="curl-7.88.1"
IOS_SDK_VERSION=""
IOS_MIN_SDK_VERSION="7.1"
IPHONEOS_DEPLOYMENT_TARGET="9.0"

DEVELOPER=$(xcode-select -print-path)

CC_BITCODE_FLAG="-fembed-bitcode"

NGHTTP2="$(pwd)/../nghttp2/build"

build() {
	ARCH="$1"
	PLATFORM="$2"

	pushd . >/dev/null
	cd "${CURL_VERSION}"

	NGHTTP2CFG="--with-nghttp2=${NGHTTP2}/${PLATFORM}/${ARCH}"
	NGHTTP2LIB="-L${NGHTTP2}/${PLATFORM}/${ARCH}/lib"

	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} ${CC_BITCODE_FLAG}"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} ${NGHTTP2LIB}"

	echo -e "${subbold}Building ${CURL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}"

	# 用编译出来的一直找不到error: --with-openssl was given but OpenSSL could not be detected，说明--with-openssl用法有问题，还不如用系统的签
	SSL_CFG="--with-secure-transport"

	log_path="${build_dir}/${CURL_VERSION}-${PLATFORM}-${ARCH}.log"

	host_cfg=""

	# if [[ "${ARCH}" == "arm64" || "${ARCH}" == "arm64e" ]]; then
	# 	host_cfg="--host=arm-apple-darwin"
	# else
	host_cfg="--host=${ARCH}-apple-darwin" #等号右边的双引号不能省略，要不然传值容易出现问题
	# fi

	echo "准备./configure"

	common_cfg="--disable-shared --enable-static -with-random=/dev/urandom"
	prefix_cfg="-prefix=${build_dir}/${PLATFORM}/${ARCH}"
	./configure ${prefix_cfg} ${common_cfg} ${SSL_CFG} ${NGHTTP2CFG} ${host_cfg} &>${log_path}
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

rm -rf "${CURL_VERSION}"

if [ ! -e ${CURL_VERSION}.tar.gz ]; then
	echo "Downloading ${CURL_VERSION}.tar.gz"
	curl -LO https://curl.haxx.se/download/${CURL_VERSION}.tar.gz
else
	echo "Using ${CURL_VERSION}.tar.gz"
fi

echo "Unpacking curl"
tar xfz "${CURL_VERSION}.tar.gz"

echo -e "${bold}Building iOS libraries${dim}"
build "armv7" "iPhoneOS"
build "arm64" "iPhoneSimulator"
build "arm64" "iPhoneOS"
build "x86_64" "iPhoneSimulator"
build "arm64" "MacOSX"
build "x86_64" "MacOSX"

echo -e "${bold}Cleaning up${dim}"
rm -rf ${CURL_VERSION}
rm -rf "${CURL_VERSION}.tar.gz"

echo -e "Done"

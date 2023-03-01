#!/bin/zsh

if [[ -e "nghttp2/build/iPhoneOS" ]]; then
	echo 'nghttp2已编译好'
else
	echo -e "${bold}Building nghttp2 for HTTP2 support${normal}"
	cd nghttp2
	./nghttp2-build.sh
	cd ..
fi

if [[ -e "curl/build/iPhoneOS" ]]; then
	echo 'curl已编译好'
else
	## Curl Build
	echo -e "${bold}Building Curl${normal}"
	cd curl
	./libcurl-build.sh
	cd ..
fi

curl_version='7.88.1'

modules_info="""framework module curl {
  umbrella header \"curl-umbrella.h\"

  export *
  module * { export * }
}
"""
umbrella_header_str='''#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "stdcheaders.h"
#import "header.h"
#import "options.h"
#import "mprintf.h"
#import "easy.h"
#import "curl.h"
#import "websockets.h"
#import "curlver.h"
#import "system.h"
#import "typecheck-gcc.h"
#import "multi.h"
#import "urlapi.h"

FOUNDATION_EXPORT double curlVersionNumber;
FOUNDATION_EXPORT const unsigned char curlVersionString[];
'''

make_IOS_framework() {
	platform="$1"
	version="$2"

	rm -rf ${platform}
	mkdir -p ${platform}/${framework_name}/Headers
	mkdir -p ${platform}/${framework_name}/Modules
	lipo -create \
		$(ls curl/build/${platform}/*/lib/libcurl.a) \
		-output ${platform}/${framework_name}/curl
	cp -r curl/build/${platform}/arm64/include/curl/ ${platform}/${framework_name}/Headers
	echo "${umbrella_header_str}" >${platform}/${framework_name}/Headers/curl-umbrella.h
	echo "${modules_info}" >${platform}/${framework_name}/Modules/module.modulemap

	info_path="Resources/${platform}.plist"
	cp "${info_path}" ${platform}/${framework_name}/info.plist
}

make_mac_framework() {

}

framework_name="curl.xcframework"
echo "开始制作frameworks"
make_framework iPhoneOS iphoneos16.2
make_framework iPhoneSimulator iphonesimulator16.2
make_framework MacOSX macosx13.2.1

echo "开始合并成xcframework"
rm -rf curl.xcframework
xcodebuild -create-xcframework -output curl.xcframework \
	-framework iPhoneOS/${framework_name} \
	-framework iPhoneSimulator/${framework_name} \
	-framework MacOSX/${framework_name}
if [[ $? != 0 ]]; then
	echo "合成失败"
	exit 1
fi
echo "copy to root"
rm -rf ../curl.xcframework
cp -r curl.xcframework ../curl.xcframework

echo "done"

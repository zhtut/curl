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

    echo "开始制作IOS的${platform}framework"

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
    echo "开始制作Mac的framework"
    platform="MacOSX"

    rm -rf ${platform}
    framework_path="$(pwd)/${platform}/${framework_name}"
    mkdir -p ${framework_path}/Versions/A/Headers
    mkdir -p ${framework_path}/Versions/A/Modules
    mkdir -p ${framework_path}/Versions/A/Resources

    lipo -create \
        $(ls curl/build/${platform}/*/lib/libcurl.a) \
        -output ${framework_path}/Versions/A/curl
    cp -r curl/build/${platform}/arm64/include/curl/ ${framework_path}/Versions/A/Headers
    echo "${umbrella_header_str}" >${framework_path}/Versions/A/Headers/curl-umbrella.h
    echo "${modules_info}" >${framework_path}/Versions/A/Modules/module.modulemap

    info_path="Resources/${platform}.plist"
    cp "${info_path}" ${framework_path}/Versions/A/Resources/info.plist

    ln -s ${framework_path}/Versions/A ${framework_path}/Versions/Current
    ln -s ${framework_path}/Versions/A/Headers ${framework_path}/Headers
    ln -s ${framework_path}/Versions/A/curl ${framework_path}/curl
    ln -s ${framework_path}/Versions/A/Resources ${framework_path}/Resources
    ln -s ${framework_path}/Versions/A/Modules ${framework_path}/Modules
}

curl_version=$(grep CURL_VERSION= curl/libcurl-build.sh)
curl_version=${curl_version#*curl-}
curl_version=${curl_version%\"*}
echo "查找到curl的版本号：${curl_version}"

echo "将版本号写到info.plist中"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${curl_version}" Resources/iPhoneOS.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${curl_version}" Resources/iPhoneSimulator.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${curl_version}" Resources/MacOSX.plist

framework_name="curl.framework"
echo "开始制作frameworks"
make_IOS_framework iPhoneOS
make_IOS_framework iPhoneSimulator
make_mac_framework

echo "开始合并成xcframework"
out_xcframework="curl.xcframework"
rm -rf ${out_xcframework}
xcodebuild -create-xcframework -output ${out_xcframework} \
    -framework iPhoneOS/${framework_name} \
    -framework iPhoneSimulator/${framework_name} \
    -framework MacOSX/${framework_name}
if [[ $? != 0 ]]; then
    echo "合成失败"
    exit 1
fi
echo "copy to root"
rm -rf ../${out_xcframework}
cp -r ${out_xcframework} ../${out_xcframework}

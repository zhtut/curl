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

iphone_os=iPhoneOS
rm -rf ${iphone_os}
mkdir ${iphone_os}
lipo -create \
	"curl/build/${iphone_os}/arm64/lib/libcurl.a" \
	"curl/build/${iphone_os}/armv7/lib/libcurl.a" \
	-output ${iphone_os}/libcurl.a

iphone_simulator="iPhoneSimulator"
rm -rf ${iphone_simulator}
mkdir ${iphone_simulator}
lipo -create \
	"curl/build/${iphone_simulator}/arm64/lib/libcurl.a" \
	"curl/build/${iphone_simulator}/x86_64/lib/libcurl.a" \
	-output ${iphone_simulator}/libcurl.a

mac_osx="MacOSX"
rm -rf ${mac_osx}
mkdir ${mac_osx}
lipo -create \
	"curl/build/${mac_osx}/arm64/lib/libcurl.a" \
	"curl/build/${mac_osx}/x86_64/lib/libcurl.a" \
	-output ${mac_osx}/libcurl.a

rm -rf curl.xcframework
xcodebuild -create-xcframework -output curl.xcframework \
	-library ${iphone_os}/libcurl.a -headers curl/build/${iphone_os}/arm64/include/curl \
	-library ${iphone_simulator}/libcurl.a -headers curl/build/${iphone_simulator}/arm64/include/curl \
	-library ${mac_osx}/libcurl.a -headers curl/build/${mac_osx}/arm64/include/curl

echo "copy to root"
rm -rf ../curl.xcframework
cp -r curl.xcframework ../curl.xcframework

echo "done"

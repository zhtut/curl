echo "clean up"
iphone_os=iPhoneOS
rm -rf ${iphone_os}
iphone_simulator="iPhoneSimulator"
rm -rf ${iphone_simulator}
rm -rf "nghttp2/build"
rm -rf "curl/build"
rm -rf curl.xcframework
echo "done"

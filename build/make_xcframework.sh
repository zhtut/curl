modules_info() {
    echo """framework module ${name} {
  umbrella header \"${name}.h\"

  export *
  module * { export * }
}
"""
}

make_IOS_framework() {
    platform="$1"

    echo "开始制作IOS的${platform}framework"

    rm -rf ${platform}
    mkdir -p ${platform}/${framework_name}/Headers
    mkdir -p ${platform}/${framework_name}/Modules
    lipo -create \
        $(ls ${name}/build/${platform}/*/lib/lib${name}.a) \
        -output ${platform}/${framework_name}/${name}
    cp -r ${name}/build/${platform}/arm64/include/${name}/ ${platform}/${framework_name}/Headers
    echo "$(modules_info)" >${platform}/${framework_name}/Modules/module.modulemap

    info_path="Resources/${platform}.plist"
    cp "${info_path}" ${platform}/${framework_name}/info.plist
}

make_stand_in() {
    framework_path="$1"

    rm -rf ${framework_path}/Versions/Current
    rm -rf ${framework_path}/Headers
    rm -rf ${framework_path}/${name}
    rm -rf ${framework_path}/Resources
    rm -rf ${framework_path}/Modules

    ln -s ${framework_path}/Versions/A ${framework_path}/Versions/Current
    ln -s ${framework_path}/Versions/A/Headers ${framework_path}/Headers
    ln -s ${framework_path}/Versions/A/${name} ${framework_path}/${name}
    ln -s ${framework_path}/Versions/A/Resources ${framework_path}/Resources
    ln -s ${framework_path}/Versions/A/Modules ${framework_path}/Modules
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
        $(ls ${name}/build/${platform}/*/lib/lib${name}.a) \
        -output ${framework_path}/Versions/A/${name}
    cp -r ${name}/build/${platform}/arm64/include/${name}/ ${framework_path}/Versions/A/Headers
    echo "$(modules_info)" >${framework_path}/Versions/A/Modules/module.modulemap

    info_path="Resources/${platform}.plist"
    cp "${info_path}" ${framework_path}/Versions/A/Resources/info.plist

    make_stand_in ${framework_path}
}

make_frameworks() {
    export name="$1"

    version=$(grep VERSION= ${name}/${name}-build.sh)
    version=${version#*${name}-}
    version=${version%\"*}
    echo "查找到${name}的版本号：${version}"

    echo "将版本号写到info.plist中"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" Resources/iPhoneOS.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" Resources/iPhoneSimulator.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version}" Resources/MacOSX.plist

    framework_name="${name}.framework"
    echo "开始制作frameworks"
    make_IOS_framework iPhoneOS
    make_IOS_framework iPhoneSimulator
    make_mac_framework

    echo "开始合并成xcframework"
    out_xcframework="${name}.xcframework"
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
    cp -rP ${out_xcframework} ../${out_xcframework} #默认-r会把替身变成文件，加-P就不会了

    echo "制作Mac的替身"
    mac_framework_path="$(pwd)/../${out_xcframework}/macos-arm64_x86_64/${name}.framework"
    make_stand_in ${mac_framework_path}

    rm -rf iPhoneOS
    rm -rf iPhoneSimulator
    rm -rf MacOSX

    rm -rf ${out_xcframework}
}

make_frameworks nghttp2
make_frameworks curl

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

echo "done"

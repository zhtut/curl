#!/bin/bash

# This script builds openssl+libcurl libraries for MacOS, iOS and tvOS
#
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL
#

################################################
# EDIT this section to Select Default Versions #
################################################

LIBCURL="7.88.1" # https://curl.haxx.se/download.html
NGHTTP2="1.52.0" # https://nghttp2.org/

################################################

# Global flags
engine=""
buildnghttp2="-n"
disablebitcode=""
colorflag=""

# Formatting
default="\033[39m"
wihte="\033[97m"
green="\033[32m"
red="\033[91m"
yellow="\033[33m"

bold="\033[0m${white}\033[1m"
subbold="\033[0m${green}"
normal="${white}\033[0m"
dim="\033[0m${white}\033[2m"
alert="\033[0m${red}\033[1m"
alertdim="\033[0m${red}\033[2m"

usage() {
	echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-o ${dim}<libressl version>${normal}] [-c ${dim}<curl version>${normal}] [-n ${dim}<nghttp2 version>${normal}] [-d] [-e] [-x] [-h]"
	echo
	echo "         -l <version>   Build libressl version (default $LIBRESSL)"
	echo "         -c <version>   Build curl version (default $LIBCURL)"
	echo "         -n <version>   Build nghttp2 version (default $NGHTTP2)"
	echo "         -d             Compile without HTTP2 support"
	echo "         -e             Compile with libressl engine support"
	echo "         -b             Compile without bitcode"
	echo "         -x             No color output"
	echo "         -h             Show usage"
	echo
	exit 127
}

while getopts "o:c:n:dexh\?" o; do
	case "${o}" in
	l)
		LIBRESSL="${OPTARG}"
		;;
	c)
		LIBCURL="${OPTARG}"
		;;
	n)
		NGHTTP2="${OPTARG}"
		;;
	d)
		buildnghttp2=""
		;;
	e)
		engine="-e"
		;;
	b)
		disablebitcode="-b"
		;;
	x)
		bold=""
		subbold=""
		normal=""
		dim=""
		alert=""
		alertdim=""
		colorflag="-x"
		;;
	*)
		usage
		;;
	esac
done
shift $((OPTIND - 1))

## Welcome
echo -e "${bold}Build-libressl-cURL${dim}"
echo "This script builds libressl, nghttp2 and libcurl for MacOS (OS X), iOS and tvOS devices."
echo "Targets: x86_64, armv7, armv7s, arm64 and arm64e"
echo

# ## OpenSSL Build
# echo
# cd libressl
# echo -e "${bold}Building libressl${normal}"
# ./libressl-build.sh -v "$LIBRESSL" $engine $colorflag
# cd ..

## Nghttp2 Build

if [[ -e "nghttp2/iOS" ]]; then
	echo 'nghttp2已编译好'
else
	echo -e "${bold}Building nghttp2 for HTTP2 support${normal}"
	cd nghttp2
	./nghttp2-build.sh -v "$NGHTTP2" $colorflag
	cd ..
fi

## Curl Build
echo
echo -e "${bold}Building Curl${normal}"
cd curl
./libcurl-build.sh -v "$LIBCURL" $disablebitcode $colorflag $buildnghttp2
cd ..

echo "done"

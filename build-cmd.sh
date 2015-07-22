#!/bin/sh

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

# load autobuild provided shell functions and variables
# first remap the autobuild env to fix the path for sickwin
if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

JSONCPP_VERSION="1.6.1"

stage="$(pwd)/stage"
LIBRARY_DIRECTORY_DEBUG=$stage/lib/debug
LIBRARY_DIRECTORY_RELEASE=$stage/lib/release
INCLUDE_DIRECTORY=$stage/include/jsoncpp
mkdir -p "$LIBRARY_DIRECTORY_DEBUG"
mkdir -p "$LIBRARY_DIRECTORY_RELEASE"
mkdir -p "$INCLUDE_DIRECTORY"

echo "${JSONCPP_VERSION}" > "${stage}/VERSION.txt"

pushd "jsoncpp"
case "$AUTOBUILD_PLATFORM" in
    "windows")
        load_vsvars
        cmake . -G"Visual Studio 14"
		
        build_sln "jsoncpp.sln" "Debug|Win32"
        build_sln "jsoncpp.sln" "Release|Win32"

        cp -a src/lib_json/Debug/jsoncpp.lib $LIBRARY_DIRECTORY_DEBUG/jsoncppd.lib
        cp -a src/lib_json/Release/*.lib $LIBRARY_DIRECTORY_RELEASE
        cp -a include/json/*.h $INCLUDE_DIRECTORY
    ;;
    "windows64")
        load_vsvars
        cmake . -G"Visual Studio 14 Win64"
		
        build_sln "jsoncpp.sln" "Debug|x64"
        build_sln "jsoncpp.sln" "Release|x64"

        cp -a src/lib_json/Debug/jsoncpp.lib $LIBRARY_DIRECTORY_DEBUG/jsoncppd.lib
        cp -a src/lib_json/Release/*.lib $LIBRARY_DIRECTORY_RELEASE
        cp -a include/json/*.h $INCLUDE_DIRECTORY
    ;;
    "darwin")
        cmake -DCMAKE_OSX_ARCHITECTURES='i386;x86_64' -DCMAKE_OSX_DEPLOYMENT_TARGET='10.8' \
			-DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++" -DCMAKE_INSTALL_PREFIX:PATH="$stage" .
        make
        make install
        # Fudge this
        mv "${stage}/include/json/"* "${stage}/include/jsoncpp"
        rmdir "${stage}/include/json"
        mv "${stage}/lib/libjsoncpp.a" "${stage}/lib/release/libjsoncpp.a"
    ;;
    "linux64")
        HARDENED="-fstack-protector-strong -D_FORTIFY_SOURCE=2"
        CFLAGS="-m64 -O3 -g $HARDENED -fPIC -DPIC" CXXFLAGS="-m64 -O3 -g $HARDENED -fPIC -DPIC -std=c++11" cmake -DCMAKE_INSTALL_PREFIX:PATH="$stage" .
        make
        make install
        # Fudge this
        mv "${stage}/include/json/"* "${stage}/include/jsoncpp"
        rmdir "${stage}/include/json"
        mv "${stage}/lib/libjsoncpp.a" "${stage}/lib/release/libjsoncpp.a"
    ;;
esac

mkdir -p $stage/LICENSES
cp LICENSE $stage/LICENSES/jsoncpp.txt
popd
pass

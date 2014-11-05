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

stage="$(pwd)/stage"
LIBRARY_DIRECTORY_DEBUG=$stage/lib/debug
LIBRARY_DIRECTORY_RELEASE=$stage/lib/release
INCLUDE_DIRECTORY=$stage/include/jsoncpp
mkdir -p "$LIBRARY_DIRECTORY_DEBUG"
mkdir -p "$LIBRARY_DIRECTORY_RELEASE"
mkdir -p "$INCLUDE_DIRECTORY"
pushd "jsoncpp"
case "$AUTOBUILD_PLATFORM" in
    "windows")
        load_vsvars
        cmake . -G"Visual Studio 12"
		
        build_sln "jsoncpp.sln" "Debug|Win32"
        build_sln "jsoncpp.sln" "Release|Win32"

        cp -a lib/Debug/*.lib $LIBRARY_DIRECTORY_DEBUG
        cp -a lib/Release/*.lib $LIBRARY_DIRECTORY_RELEASE
        cp -a include/json/*.h $INCLUDE_DIRECTORY
    ;;
    "windows64")   
        load_vsvars
        cmake . -G"Visual Studio 12 Win64"
		
        build_sln "jsoncpp.sln" "Debug|x64"
        build_sln "jsoncpp.sln" "Release|x64"

        cp -a lib/Debug/*.lib $LIBRARY_DIRECTORY_DEBUG
        cp -a lib/Release/*.lib $LIBRARY_DIRECTORY_RELEASE
        cp -a include/json/*.h $INCLUDE_DIRECTORY
    ;;
    darwin)

    ;;
    linux)

    ;;
esac

mkdir -p $stage/LICENSES
cp LICENSE $stage/LICENSES/jsoncpp.txt
popd
pass

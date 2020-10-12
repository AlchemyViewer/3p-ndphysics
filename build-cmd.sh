#!/usr/bin/env bash

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about undefined vars
set -u

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

stage="$(pwd)"

# load autbuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

NDSTUB_VERSION="0.1.2"

echo "${NDSTUB_VERSION}" > "${stage}/VERSION.txt"

mkdir -p "$stage/lib/release"
case "$AUTOBUILD_PLATFORM" in
	windows*)
        if [ "$AUTOBUILD_ADDRSIZE" = 32 ]
        then
            archflags=""
        else
            archflags=""
        fi
        cmake -E env CFLAGS="$archflags /Z7" CXXFLAGS="$archflags /Z7" \
        cmake -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" ..

        cmake --build . --config "Debug" -j --clean-first
        cmake --build . --config "Release" -j --clean-first

	    cp "$stage/Source/lib/Release/nd_hacdConvexDecomposition.lib" "$stage/lib/release/"
	    cp "$stage/Source/Pathing/Release/nd_Pathing.lib" "$stage/lib/release/"
	    cp "$stage/Source/HACD_Lib/Release/hacd.lib" "$stage/lib/release/"
	;;
	"darwin")
	    cmake -DCMAKE_OSX_ARCHITECTURES='x86_64' \
            -DCMAKE_OSX_DEPLOYMENT_TARGET='10.13' \
            -DCMAKE_CXX_FLAGS="${LL_BUILD_RELEASE}" ../
	    make

	    # Copy the new libs
	    cp "$stage/Source/lib/libnd_hacdConvexDecomposition.a" "$stage/lib/release/"
	    cp "$stage/Source/Pathing/libnd_Pathing.a" "$stage/lib/release/"
	    cp "$stage/Source/HACD_Lib/libhacd.a" "$stage/lib/release/"
	;;
	"linux")
	    cmake ../
	    CFLAGS="-m32 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC -DPIC -O2 -g" \
                CXXFLAGS="-m32 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC -DPIC -O2 -g -std=c++11" \
                make

	    cp "$stage/Source/lib/libnd_hacdConvexDecomposition.a" "$stage/lib/release/"
	    cp "$stage/Source/Pathing/libnd_Pathing.a" "$stage/lib/release/"
	    cp "$stage/Source/HACD_Lib/libhacd.a" "$stage/lib/release/"
	;;
	"linux64")
	    cmake ../
	    CFLAGS="-m64 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC -DPIC -O2 -g" \
                CXXFLAGS="-m64 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIC -DPIC -O2 -g -std=c++11" \
                make

	    cp "$stage/Source/lib/libnd_hacdConvexDecomposition.a" "$stage/lib/release/"
	    cp "$stage/Source/Pathing/libnd_Pathing.a" "$stage/lib/release/"
	    cp "$stage/Source/HACD_Lib/libhacd.a" "$stage/lib/release/"
	;;
esac

# Copy headers
mkdir -p "$stage/include"
cp "$stage/../Source/lib/llconvexdecomposition.h" "$stage/include/"
cp "$stage/../Source/lib/ndConvexDecomposition.h" "$stage/include/"
cp "$stage/../Source/Pathing/llpathinglib.h" "$stage/include/"
cp "$stage/../Source/Pathing/llphysicsextensions.h" "$stage/include/"


mkdir -p "$stage/LICENSES"
cp "../COPYING.LESSER" "$stage/LICENSES/ndphysicsstub.txt"


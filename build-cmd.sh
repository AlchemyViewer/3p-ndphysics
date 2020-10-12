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
srcdir="$stage/.."

# load autbuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

NDSTUB_VERSION="0.1.2"

echo "${NDSTUB_VERSION}" > "${stage}/VERSION.txt"

mkdir -p "$stage/lib/release"
case "$AUTOBUILD_PLATFORM" in
	windows*)

            load_vsvars

            if [ "$AUTOBUILD_ADDRSIZE" = 32 ]
            then
                archflags=""
            else
                archflags=""
            fi

            # Create staging dirs
            mkdir -p "${stage}/lib/debug"
            mkdir -p "${stage}/lib/release"

            # Debug Build
            mkdir -p "build_debug"
            pushd "build_debug"

                cmake -E env CFLAGS="$archflags /Z7" CXXFLAGS="$archflags /Z7" LDFLAGS="/DEBUG:FULL" \
                cmake $(cygpath -w "$srcdir") -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m "$stage")"

                cmake --build . --config Debug --clean-first

	    		cp "Source/lib/Debug/nd_hacdConvexDecomposition.lib" "$stage/lib/debug/"
	    		cp "Source/Pathing/Debug/nd_Pathing.lib" "$stage/lib/debug/"
	    		cp "Source/HACD_Lib/Debug/hacd.lib" "$stage/lib/debug/"
            popd

            # Release Build
            mkdir -p "build_release"
            pushd "build_release"

                cmake -E env CFLAGS="$archflags /O2 /Ob3 /Gy /Z7" CXXFLAGS="$archflags /O2 /Ob3 /Gy /Z7 /std:c++17 /permissive-" LDFLAGS="/OPT:REF /OPT:ICF /DEBUG:FULL" \
                cmake $(cygpath -w "$srcdir") -G "$AUTOBUILD_WIN_CMAKE_GEN" -A "$AUTOBUILD_WIN_VSPLATFORM" \
                    -DCMAKE_INSTALL_PREFIX="$(cygpath -m "$stage")"

                cmake --build . --config Release --clean-first
				
	    		cp "Source/lib/Release/nd_hacdConvexDecomposition.lib" "$stage/lib/release/"
	    		cp "Source/Pathing/Release/nd_Pathing.lib" "$stage/lib/release/"
	    		cp "Source/HACD_Lib/Release/hacd.lib" "$stage/lib/release/"
            popd
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


#!/usr/bin/env bash

# turn on verbose debugging output for parabuild logs.
exec 4>&1
export BASH_XTRACEFD=4
set -x
# make errors fatal
set -e
# complain about undefined vars
set -u

if [ -z "$AUTOBUILD" ]; then
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ]; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

stage="$(pwd)"
srcdir="$stage/.."

# load autbuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment >"$source_environment_tempfile"
. "$source_environment_tempfile"

NDSTUB_VERSION="0.1.2"

echo "${NDSTUB_VERSION}" >"${stage}/VERSION.txt"

mkdir -p "$stage/lib/release"
case "$AUTOBUILD_PLATFORM" in
windows*)
    load_vsvars

    # Create staging dirs
    mkdir -p "${stage}/lib/debug"
    mkdir -p "${stage}/lib/release"

    # Release Build
    mkdir -p "build_release"
    pushd "build_release"
        cmake $(cygpath -w "$srcdir") -G "Ninja Multi-Config" \
            -DCMAKE_INSTALL_PREFIX="$(cygpath -m "$stage")"

        cmake --build . --config Debug
        cmake --build . --config Release

        cp "Source/lib/Debug/nd_hacdConvexDecomposition.lib" "$stage/lib/debug/"
        cp "Source/Pathing/Debug/nd_Pathing.lib" "$stage/lib/debug/"
        cp "Source/HACD_Lib/Debug/hacd.lib" "$stage/lib/debug/"

        cp "Source/lib/Release/nd_hacdConvexDecomposition.lib" "$stage/lib/release/"
        cp "Source/Pathing/Release/nd_Pathing.lib" "$stage/lib/release/"
        cp "Source/HACD_Lib/Release/hacd.lib" "$stage/lib/release/"
    popd
    ;;
darwin*)
    # Setup build flags
    C_OPTS_X86="-arch x86_64 $LL_BUILD_RELEASE_CFLAGS"
    C_OPTS_ARM64="-arch arm64 $LL_BUILD_RELEASE_CFLAGS"
    CXX_OPTS_X86="-arch x86_64 $LL_BUILD_RELEASE_CXXFLAGS"
    CXX_OPTS_ARM64="-arch arm64 $LL_BUILD_RELEASE_CXXFLAGS"
    LINK_OPTS_X86="-arch x86_64 $LL_BUILD_RELEASE_LINKER"
    LINK_OPTS_ARM64="-arch arm64 $LL_BUILD_RELEASE_LINKER"

    # deploy target
    export MACOSX_DEPLOYMENT_TARGET=${LL_BUILD_DARWIN_BASE_DEPLOY_TARGET}

    # Create staging dirs
    mkdir -p "${stage}/lib/release"

    # Release Build
    mkdir -p "build_release"
    pushd "build_release"
        CFLAGS="$C_OPTS_X86" \
        CXXFLAGS="$CXX_OPTS_X86" \
        LDFLAGS="$LINK_OPTS_X86" \
        cmake $srcdir -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_FLAGS="$C_OPTS_X86" \
            -DCMAKE_CXX_FLAGS="$CXX_OPTS_X86" \
            -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
            -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
            -DCMAKE_MACOSX_RPATH=YES \
            -DCMAKE_INSTALL_PREFIX=$stage

        cmake --build . --config Release

        # Copy the new libs
        cp "Source/lib/libnd_hacdConvexDecomposition.a" "$stage/lib/release/"
        cp "Source/Pathing/libnd_Pathing.a" "$stage/lib/release/"
        cp "Source/HACD_Lib/libhacd.a" "$stage/lib/release/"
    popd
    ;;
linux*)
    # Linux build environment at Linden comes pre-polluted with stuff that can
    # seriously damage 3rd-party builds.  Environmental garbage you can expect
    # includes:
    #
    #    DISTCC_POTENTIAL_HOSTS     arch           root        CXXFLAGS
    #    DISTCC_LOCATION            top            branch      CC
    #    DISTCC_HOSTS               build_name     suffix      CXX
    #    LSDISTCC_ARGS              repo           prefix      CFLAGS
    #    cxx_version                AUTOBUILD      SIGN        CPPFLAGS
    #
    # So, clear out bits that shouldn't affect our configure-directed build
    # but which do nonetheless.
    #
    unset DISTCC_HOSTS CFLAGS CPPFLAGS CXXFLAGS

    # Default target per --address-size
    opts_c="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE_CFLAGS}"
    opts_cxx="${TARGET_OPTS:--m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE_CXXFLAGS}"

    # Handle any deliberate platform targeting
    if [ -z "${TARGET_CPPFLAGS:-}" ]; then
        # Remove sysroot contamination from build environment
        unset CPPFLAGS
    else
        # Incorporate special pre-processing flags
        export CPPFLAGS="$TARGET_CPPFLAGS"
    fi

    # Release
    mkdir -p "build_release"
    pushd "build_release"
        CFLAGS="$opts_c" \
        CXXFLAGS="$opts_cxx" \
        cmake $srcdir -G Ninja -DCMAKE_INSTALL_PREFIX="$stage" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_FLAGS="$opts_c" \
            -DCMAKE_CXX_FLAGS="$opts_cxx"

        cmake --build . --config Release

        mkdir -p ${stage}/lib/release
        cp "Source/lib/libnd_hacdConvexDecomposition.a" "$stage/lib/release/"
        cp "Source/Pathing/libnd_Pathing.a" "$stage/lib/release/"
        cp "Source/HACD_Lib/libhacd.a" "$stage/lib/release/"
    popd
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

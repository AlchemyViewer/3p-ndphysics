cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

project(ndPhysicsStub)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set( CMAKE_PROJECT_NAME ndPhysicsStub )

if( PACKAGE_FOR_LL )
  set( ND_LIBDIR "lib/release")
else( PACKAGE_FOR_LL )
  set( ND_LIBDIR "lib/")
endif( PACKAGE_FOR_LL )

include_directories( Source/HACD_Lib/inc )

add_subdirectory(Source/lib)
add_subdirectory(Source/HACD_Lib)
add_subdirectory(Source/Pathing)

set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY 0)
set(CPACK_GENERATOR "TBZ2")
set(CPACK_STRIP_FILES TRUE )
include(CPack)

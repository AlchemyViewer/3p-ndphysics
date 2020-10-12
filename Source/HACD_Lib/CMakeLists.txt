project(HACD_LIB CXX C)

if( MSVC )
   add_definitions(-D_HAS_ITERATOR_DEBUGGING=0 -D_SECURE_SCL=0 -D_CRT_SECURE_NO_WARNINGS=1)
endif( MSVC )

set (SOURCE_FILES src/hacdGraph.cpp  src/hacdHACD.cpp  src/hacdICHull.cpp  src/hacdManifoldMesh.cpp src/hacdMeshDecimator.cpp src/hacdMicroAllocator.cpp src/hacdRaycastMesh.cpp )
file (GLOB INCLUDE_FILES inc/*.h )

add_library(hacd STATIC ${SOURCE_FILES} ${INCLUDE_FILES} )

install( TARGETS hacd DESTINATION ${ND_LIBDIR} )

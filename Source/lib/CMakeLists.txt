cmake_minimum_required(VERSION 2.6.4)

if( MSVC )
   add_definitions(-D_HAS_ITERATOR_DEBUGGING=0 -D_SECURE_SCL=0 -D_CRT_SECURE_NO_WARNINGS=1)
endif( MSVC )

set (SOURCE_FILES llconvexdecomposition.cpp nd_hacdConvexDecomposition.cpp nd_hacdStructs.cpp nd_hacdUtils.cpp nd_EnterExitTracer.cpp nd_StructTracer.cpp )
file(GLOB HEADER_FILES *.h)

add_library( nd_hacdConvexDecomposition STATIC ${SOURCE_FILES} ${HEADER_FILES})

install( TARGETS nd_hacdConvexDecomposition DESTINATION ${ND_LIBDIR} )
install( FILES llconvexdecomposition.h DESTINATION include )
install( FILES ndConvexDecomposition.h DESTINATION include )

# mlir_gen_iface(Cinm TilingInterface op)
add_mlir_interface(CinmTilingInterface
  TD_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/TilingInterface.td
  DIALECTS Cinm
  DEPENDS  MLIRIR
)
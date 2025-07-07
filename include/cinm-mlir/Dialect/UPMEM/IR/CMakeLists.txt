mlir_gen_ir(UPMEM)
# mlir_gen_iface(UPMEM AsyncOpInterface op)
add_mlir_interface(AsyncOpInterface
  TD_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/AsyncOpInterface.td
  DIALECTS UPMEM
  DEPENDS  MLIRIR
)
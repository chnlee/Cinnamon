mlir_gen_ir(Cinm)
# mlir_gen_iface(Cinm TilingInterface op)
add_mlir_interface(TilingInterface
  TD_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/TilingInterface.td  # 인터페이스 정의 .td
  DIALECTS Cinm                                            # 연결할 Dialect
)
function(mlir_gen_ir prefix)
  string(TOLOWER ${prefix} filter)

  set(LLVM_TARGET_DEFINITIONS ${prefix}Ops.td)

  mlir_tablegen(${prefix}Base.h.inc -gen-dialect-decls -dialect=${filter})
  mlir_tablegen(${prefix}Base.cpp.inc -gen-dialect-defs -dialect=${filter})
  mlir_tablegen(${prefix}Types.h.inc -gen-typedef-decls -typedefs-dialect=${filter})
  mlir_tablegen(${prefix}Types.cpp.inc -gen-typedef-defs -typedefs-dialect=${filter})
  mlir_tablegen(${prefix}Attributes.h.inc -gen-attrdef-decls -attrdefs-dialect=${filter})
  mlir_tablegen(${prefix}Attributes.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${filter})
  mlir_tablegen(${prefix}Ops.h.inc -gen-op-decls -dialect=${filter})
  mlir_tablegen(${prefix}Ops.cpp.inc -gen-op-defs -dialect=${filter})

  set(LLVM_TARGET_DEFINITIONS ${prefix}Attributes.td)
  mlir_tablegen(${prefix}Enums.h.inc -gen-enum-decls -dialect=${filter})
  mlir_tablegen(${prefix}Enums.cpp.inc -gen-enum-defs -dialect=${filter})

  # 🎯 먼저 IRIncGen 정의
  add_public_tablegen_target(${prefix}IRIncGen)

  # 🎯 Base.td가 존재하면 타입 정의를 추가로 생성
  if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${prefix}Base.td)
    set(LLVM_TARGET_DEFINITIONS ${prefix}Base.td)
    mlir_tablegen(${prefix}BaseTypes.h.inc -gen-typedef-decls)
    mlir_tablegen(${prefix}BaseTypes.cpp.inc -gen-typedef-defs)
    add_public_tablegen_target(${prefix}BaseIncGen)

    # 안전하게 타겟 존재 확인 후 종속성 연결
    if(TARGET ${prefix}IRIncGen)
      add_dependencies(${prefix}IRIncGen ${prefix}BaseIncGen)
    endif()
  endif()

  # 항상 최종적으로 IncGen → IRIncGen 종속 연결
  add_dependencies(${prefix}IncGen ${prefix}IRIncGen)
endfunction()
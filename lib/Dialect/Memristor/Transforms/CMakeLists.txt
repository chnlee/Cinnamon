add_mlir_dialect_library(MemristorTransforms
    dummy.cpp

DEPENDS
    MemristorIncGen
    MemristorTransformPassesIncGen

LINK_LIBS PUBLIC
    MLIRIR
    MemristorIR
    MLIRMemRefDialect
    MLIRLLVMDialect
    MLIRAffineDialect
    MLIRLinalgDialect
    MLIRSPIRVTarget
    MLIRTransformUtils
)

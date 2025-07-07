add_mlir_conversion_library(MLIRCinmToCnm
    CinmToCnm.cpp

    ADDITIONAL_HEADER_DIRS
    ${MLIR_MAIN_INCLUDE_DIR}/cnm/Conversion/CinmToCnm

    DEPENDS
    CinmConversionPassIncGen
    CnmIncGen
    CimIncGen
    
    LINK_COMPONENTS
    Core

    LINK_LIBS PUBLIC
    CnmIR
    CimIR
    CinmUtils
    CinmIR
    MLIRDialectUtils
    MLIRFuncDialect
    MLIRLinalgDialect
    MLIRTensorDialect
    MLIRTransformUtils
    MLIRReconcileUnrealizedCasts
)

add_mlir_conversion_library(MLIRCnmToUPMEM
    CnmToUPMEM.cpp

    ADDITIONAL_HEADER_DIRS
    ${MLIR_MAIN_INCLUDE_DIR}/cnm/Conversion/CnmToUPMEM

    DEPENDS
    CnmConversionPassIncGen
    UPMEMIncGen

    LINK_COMPONENTS
    Core

    LINK_LIBS PUBLIC
    CinmCommonPatterns
    CnmIR
    UPMEMIR
    MLIRDialectUtils
    MLIRFuncDialect
    MLIRTransformUtils
    MLIRReconcileUnrealizedCasts
)

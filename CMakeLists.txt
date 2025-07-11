################################################################################
# cinm-mlir
#
################################################################################

cmake_minimum_required(VERSION 3.22)

# Add custom modules to the search path.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(cmake/MLIRUtils.cmake)
# include(MLIRUtils)

project(cinm-mlir
    VERSION     0.2.0
    LANGUAGES   C CXX
)

option(CINM_BUILD_GPU_SUPPORT "Enable vulkan runner and GPU libs" OFF)
option(TORCH_MLIR_DIR "Directory of the Torch-MLIR installation" "")
option(UPMEM_DIR "Directory of the UPMEM installation" "")

if (CINM_BUILD_GPU_SUPPORT)
    add_compile_definitions(CINM_GPU_SUPPORT)
endif()

if (TORCH_MLIR_DIR)
    add_compile_definitions(CINM_TORCH_MLIR_ENABLED)

    set(TORCH_MLIR_INCLUDE_DIR "${TORCH_MLIR_DIR}/include")
    set(TORCH_MLIR_LIB_DIR "${TORCH_MLIR_DIR}/lib")
    include_directories(SYSTEM ${TORCH_MLIR_INCLUDE_DIR})
    link_directories(${TORCH_MLIR_LIB_DIR})

    file(GLOB TORCH_MLIR_LIBS "${TORCH_MLIR_LIB_DIR}/*.a")

    get_property(CINM_DEPENDENCY_LIBS GLOBAL PROPERTY CINM_DEPENDENCY_LIBS)
    list(APPEND CINM_DEPENDENCY_LIBS ${TORCH_MLIR_LIBS})
    set_property(GLOBAL PROPERTY CINM_DEPENDENCY_LIBS ${CINM_DEPENDENCY_LIBS})
    
else()
    message(WARNING "TORCH_MLIR_DIR not set, torch frontend wont be available.")
endif()

# Set global language standard to C++20.
set(CMAKE_CXX_STANDARD 20 CACHE STRING "C++ standard to conform to")

# Detect if this is a stand-alone build.
if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    # Set shared output directories.
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/bin)
endif()

# Fix for MLIR:
# CMP0116: Ninja generators transform `DEPFILE`s from `add_custom_command()`
# New in CMake 3.20. https://cmake.org/cmake/help/latest/policy/CMP0116.html
if(POLICY CMP0116)
    cmake_policy(SET CMP0116 OLD)
endif()

# Find MLIR.
find_package(MLIR REQUIRED CONFIG)
message(STATUS "Using MLIRConfig.cmake in: ${MLIR_DIR}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# Load LLVM and MLIR CMake modules.
list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(TableGen)
include(AddLLVM)
include(AddMLIR)
# include(MLIRTableGen)
include(HandleLLVMOptions)

# Apply target properties for LLVM/MLIR globally.
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
include_directories(SYSTEM ${MLIR_INCLUDE_DIRS})
link_directories(${LLVM_BUILD_LIBRARY_DIR})
add_definitions(${LLVM_DEFINITIONS})

# Apply target properties for this project globally.
include_directories(SYSTEM ${PROJECT_BINARY_DIR}/include)
include_directories(${PROJECT_SOURCE_DIR}/include)

add_compile_options(
    # NOTE: C++20 warning adjustments for this project.
    -Wall
    -Wextra
    -Wno-ambiguous-reversed-operator
    # NOTE: GDB < 10.x can't handle DWARFv5 correctly.
    $<$<CXX_COMPILER_ID:Clang>:-fdebug-default-version=4>
    $<$<CXX_COMPILER_ID:Clang>:-fcolor-diagnostics>
)

get_property(LTY GLOBAL PROPERTY LINKER_TYPE)
if (LTY STREQUAL "LLD")
    add_link_options(--for-linker --color-diagnostics=always)
endif()

if (TORCH_MLIR_DIR)
    set_property(GLOBAL PROPERTY TORCH_MLIR_ENABLED ON)
    set(TORCH_MLIR_INCLUDE_DIR "${TORCH_MLIR_DIR}/include")
    # include_directories(SYSTEM ${TORCH_MLIR_INCLUDE_DIR})

    add_library(Torch::TorchMLIRTorchDialect STATIC IMPORTED GLOBAL)
    set_property(TARGET Torch::TorchMLIRTorchDialect PROPERTY
                 IMPORTED_LOCATION ${TORCH_MLIR_DIR}/lib/libTorchMLIRTorchDialect.a)
    add_library(Torch::TorchMLIRTorchUtils STATIC IMPORTED GLOBAL)
    set_property(TARGET Torch::TorchMLIRTorchUtils PROPERTY
                 IMPORTED_LOCATION ${TORCH_MLIR_DIR}/lib/libTorchMLIRTorchUtils.a)
    add_library(Torch::TorchMLIRTorchConversionDialect STATIC IMPORTED GLOBAL)
    set_property(TARGET Torch::TorchMLIRTorchConversionDialect PROPERTY
                 IMPORTED_LOCATION ${TORCH_MLIR_DIR}/lib/libTorchMLIRTorchConversionDialect.a)
                
    add_library(Torch::All INTERFACE IMPORTED)
    set_property(TARGET Torch::All PROPERTY
      INTERFACE_LINK_LIBRARIES Torch::TorchMLIRTorchDialect 
            Torch::TorchMLIRTorchUtils 
            Torch::TorchMLIRTorchConversionDialect)
    target_include_directories(Torch::All INTERFACE ${TORCH_MLIR_INCLUDE_DIR})

else()
    set_property(GLOBAL PROPERTY TORCH_MLIR_ENABLED OFF)
    message(WARNING "TORCH_MLIR_DIR not set")
endif()

if (UPMEM_DIR)
    add_library(Upmem::dpu SHARED IMPORTED GLOBAL)
    set_property(TARGET Upmem::dpu PROPERTY
                 IMPORTED_LOCATION ${UPMEM_DIR}/lib/libdpu.so)
    target_include_directories(Upmem::dpu INTERFACE ${UPMEM_DIR}/include/dpu)
    add_subdirectory(runtime/Upmem)
else()
    message(WARNING "UPMEM_DIR not set, runtime lib will not be compiled.")
endif()


add_subdirectory(include)
add_subdirectory(lib)
add_subdirectory(test)
add_subdirectory(tools)

add_subdirectory(runtime/Memristor)

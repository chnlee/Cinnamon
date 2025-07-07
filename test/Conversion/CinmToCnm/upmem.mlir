#map = affine_map<(d0, d1, d2) -> (d1 mod 8)>
#map1 = affine_map<(d0, d1, d2) -> (d1)>
#map2 = affine_map<(d0, d1, d2) -> (d0, d1)>
#map3 = affine_map<(d0) -> (d0)>
#map4 = affine_map<(d0) -> ()>
module {
  func.func @mm_dimm8_nopt(%arg0: tensor<8x1024xi32>, %arg1: tensor<1024x128xi32>) -> tensor<8x128xi32> {
    %0 = upmem.alloc_dpus : !upmem.hierarchy<8x128x1>
    %1 = tensor.empty() : tensor<128x1024xi32>
    %transposed = linalg.transpose ins(%arg1 : tensor<1024x128xi32>) outs(%1 : tensor<128x1024xi32>) permutation = [1, 0] 
    %2 = builtin.unrealized_conversion_cast %arg0 : tensor<8x1024xi32> to memref<8x1024xi32>
    upmem.scatter %2[0, 1024, #map] onto %0 : memref<8x1024xi32> onto !upmem.hierarchy<8x128x1>
    %3 = builtin.unrealized_conversion_cast %transposed : tensor<128x1024xi32> to memref<128x1024xi32>
    upmem.scatter %3[4096, 1024, #map1] onto %0 : memref<128x1024xi32> onto !upmem.hierarchy<8x128x1>
    %cst = arith.constant dense<0> : tensor<8x128xi32>
    %4 = builtin.unrealized_conversion_cast %cst : tensor<8x128xi32> to memref<8x128xi32>
    upmem.scatter %4[8192, 1, #map2] onto %0 : memref<8x128xi32> onto !upmem.hierarchy<8x128x1>
    upmem.launch_func  @dpu_kernels::@mm_dimm8_nopt %0 : !upmem.hierarchy<8x128x1> 
    %alloc = memref.alloc() : memref<8x128xi32>
    upmem.gather %alloc[8192, 1, #map2] from %0 : memref<8x128xi32> from !upmem.hierarchy<8x128x1>
    %5 = builtin.unrealized_conversion_cast %alloc : memref<8x128xi32> to tensor<8x128xi32>
    upmem.free_dpus %0 : !upmem.hierarchy<8x128x1>
    return %5 : tensor<8x128xi32>
  }
  upmem.module @dpu_kernels {
    upmem.func @mm_dimm8_nopt() attributes {num_tasklets = 1 : i64} {
      %0 = upmem.dpu_heap_base_addr : index
      %1 = upmem.tasklet_id : index
      %c4096 = arith.constant 4096 : index
      %2 = arith.muli %1, %c4096 : index
      %3 = arith.addi %0, %2 : index
      %c1024 = arith.constant 1024 : index
      %4 = upmem.pwram_alloc : memref<1024xi32>
      %5 = arith.addi %0, %c4096 : index
      %6 = arith.addi %5, %2 : index
      %7 = upmem.pwram_alloc : memref<1024xi32>
      %8 = arith.addi %5, %c4096 : index
      %c8 = arith.constant 8 : index
      %9 = arith.muli %1, %c8 : index
      %10 = arith.addi %8, %9 : index
      %c2 = arith.constant 2 : index
      %11 = upmem.pwram_alloc : memref<i32>
      upmem.memcpy  mram_to_wram %4, %c1024, %3 : memref<1024xi32>, index, index
      upmem.memcpy  mram_to_wram %7, %c1024, %6 : memref<1024xi32>, index, index
      linalg.contract indexing_maps = [#map3, #map3, #map4] ins(%4, %7 : memref<1024xi32>, memref<1024xi32>) outs(%11 : memref<i32>)
      upmem.memcpy  wram_to_mram %11, %c2, %10 : memref<i32>, index, index
      upmem.return
    }
  }
}


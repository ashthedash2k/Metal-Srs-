#include <metal_stdlib>
using namespace metal;

kernel void doubleArray(device float* array [[buffer(0)]],
                        uint id [[thread_position_in_grid]]) {
    array[id] *= 2.0;
}



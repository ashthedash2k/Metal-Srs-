import SwiftUI
import Metal
struct ContentView: View {
    @State private var metalCompute: MetalCompute? = nil
    @State private var currentResults: [Float] = [1, 2, 3, 4, 5]
    @State private var iterationCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Doubling an Array")
                .font(.title)
            
            Text("Iteration: \(iterationCount)")
                .font(.headline)
            
            Text("Current Values:")
                .font(.subheadline)
            
            Text(currentResults.map { String(format: "%.1f", $0) }.joined(separator: ", "))
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Button("Double Values") {
                if let compute = metalCompute {
                    currentResults = compute.doubleValues(currentResults)
                    iterationCount += 1
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Reset") {
                currentResults = [1, 2, 3, 4, 5]
                iterationCount = 0
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .onAppear {
            metalCompute = MetalCompute()
        }
    }
}

class MetalCompute {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return nil
        }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            print("Failed to create command queue")
            return nil
        }
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "doubleArray"),
              let pipelineState = try? device.makeComputePipelineState(function: function) else {
            print("Failed to create compute pipeline")
            return nil
        }
        self.pipelineState = pipelineState
    }
    
    func doubleValues(_ input: [Float]) -> [Float] {
        guard let buffer = device.makeBuffer(
            bytes: input,
            length: MemoryLayout<Float>.size * input.count,
            options: []
        ) else {
            print("Failed to create buffer")
            return input
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Failed to create command buffer or encoder")
            return input
        }
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setBuffer(buffer, offset: 0, index: 0)
        
        let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
        let threadgroupsPerGrid = MTLSize(width: input.count, height: 1, depth: 1)
        
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let resultPointer = buffer.contents().bindMemory(to: Float.self, capacity: input.count)
        return Array(UnsafeBufferPointer(start: resultPointer, count: input.count))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

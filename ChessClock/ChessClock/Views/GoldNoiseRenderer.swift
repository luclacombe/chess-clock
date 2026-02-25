import IOSurface
import Metal
import QuartzCore

/// Renders animated simplex noise mapped to gold colors using Metal compute shaders.
/// Uses double-buffered IOSurface-backed textures for zero-copy GPU→CALayer display.
/// Designed for the minute ring in GoldRingLayerView.
final class GoldNoiseRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    private let startTime: CFTimeInterval

    /// Double-buffered IOSurface + MTLTexture pairs
    private let surfaces: [IOSurface]
    private let textures: [MTLTexture]
    private var bufferIndex: Int = 0

    /// Noise spatial frequency (larger = finer detail). Default 0.012 for large liquid features.
    var scale: Float = 0.012
    /// Time animation speed (larger = faster flow). Default 0.22 for slow liquid gold.
    var speed: Float = 0.22

    /// Color scheme selection: 0 = gold, 1 = marble.
    var colorScheme: Float = 0
    /// Tint color RGB components and blend strength (0 = no tint, 1 = full tint).
    var tintR: Float = 0
    var tintG: Float = 0
    var tintB: Float = 0
    var tintStrength: Float = 0

    /// Render dimensions (fixed at init time)
    private let renderWidth: Int
    private let renderHeight: Int

    init?(width: Int = 200, height: Int = 200) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "goldNoise"),
              let pipeline = try? device.makeComputePipelineState(function: function) else {
            return nil
        }

        self.device = device
        self.commandQueue = queue
        self.pipelineState = pipeline
        self.startTime = CACurrentMediaTime()
        self.renderWidth = width
        self.renderHeight = height

        // Pre-allocate 2 IOSurface + MTLTexture pairs
        var allocatedSurfaces: [IOSurface] = []
        var allocatedTextures: [MTLTexture] = []

        // Metal requires bytesPerRow aligned to 16 bytes
        let bytesPerRow = ((width * 4 + 15) / 16) * 16

        for _ in 0..<2 {
            let properties: [IOSurfacePropertyKey: Any] = [
                .width: width,
                .height: height,
                .bytesPerElement: 4,
                .bytesPerRow: bytesPerRow,
                .pixelFormat: Int(1111970369), // kCVPixelFormatType_32BGRA (0x42475241)
            ]

            guard let surface = IOSurface(properties: properties) else {
                return nil
            }

            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: width,
                height: height,
                mipmapped: false
            )
            descriptor.usage = [.shaderWrite]

            guard let texture = device.makeTexture(
                descriptor: descriptor,
                iosurface: surface,
                plane: 0
            ) else {
                return nil
            }

            allocatedSurfaces.append(surface)
            allocatedTextures.append(texture)
        }

        self.surfaces = allocatedSurfaces
        self.textures = allocatedTextures
    }

    /// Renders one frame of gold noise asynchronously.
    /// Alternates between two IOSurface-backed textures (double-buffer).
    /// Calls `completion` on GPU completion with the IOSurface containing rendered pixels.
    func renderFrame(completion: @escaping (IOSurface) -> Void) {
        let currentIndex = bufferIndex
        bufferIndex = (bufferIndex + 1) % 2

        let texture = textures[currentIndex]
        let surface = surfaces[currentIndex]

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        var time = Float(CACurrentMediaTime() - startTime)
        var scale = self.scale
        var speed = self.speed
        var colorScheme = self.colorScheme
        var tintR = self.tintR
        var tintG = self.tintG
        var tintB = self.tintB
        var tintStrength = self.tintStrength

        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 1)
        encoder.setBytes(&speed, length: MemoryLayout<Float>.size, index: 2)
        encoder.setBytes(&colorScheme, length: MemoryLayout<Float>.size, index: 3)
        encoder.setBytes(&tintR, length: MemoryLayout<Float>.size, index: 4)
        encoder.setBytes(&tintG, length: MemoryLayout<Float>.size, index: 5)
        encoder.setBytes(&tintB, length: MemoryLayout<Float>.size, index: 6)
        encoder.setBytes(&tintStrength, length: MemoryLayout<Float>.size, index: 7)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (renderWidth + 15) / 16,
            height: (renderHeight + 15) / 16,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        commandBuffer.addCompletedHandler { _ in
            completion(surface)
        }
        commandBuffer.commit()
    }
}

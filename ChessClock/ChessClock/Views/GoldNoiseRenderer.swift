import AppKit
import Metal
import QuartzCore

/// Renders animated simplex noise mapped to gold colors using Metal compute shaders.
/// Designed for the minute ring in GoldRingLayerView.
final class GoldNoiseRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    private let startTime: CFTimeInterval

    /// Noise spatial frequency (larger = finer detail). Default 0.02 for large liquid features.
    var scale: Float = 0.02
    /// Time animation speed (larger = faster flow). Default 0.15 for slow liquid gold.
    var speed: Float = 0.15

    init?() {
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
    }

    /// Renders one frame of gold noise at half the given size (for efficiency).
    /// The caller should use `layer.contentsGravity = .resize` to upscale.
    func renderFrame(size: CGSize) -> CGImage? {
        // Render at half resolution for efficiency
        let width = max(Int(size.width / 2), 1)
        let height = max(Int(size.height / 2), 1)

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width, height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderWrite]

        guard let texture = device.makeTexture(descriptor: descriptor),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }

        var time = Float(CACurrentMediaTime() - startTime)
        var scale = self.scale
        var speed = self.speed

        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.setBytes(&scale, length: MemoryLayout<Float>.size, index: 1)
        encoder.setBytes(&speed, length: MemoryLayout<Float>.size, index: 2)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (width + 15) / 16,
            height: (height + 15) / 16,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureToImage(texture, width: width, height: height)
    }

    /// Convert MTLTexture to CGImage by reading pixel bytes
    private func textureToImage(_ texture: MTLTexture, width: Int, height: Int) -> CGImage? {
        let bytesPerRow = width * 4
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        texture.getBytes(
            &pixelData,
            bytesPerRow: bytesPerRow,
            from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                           size: MTLSize(width: width, height: height, depth: 1)),
            mipmapLevel: 0
        )

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &pixelData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        return context.makeImage()
    }
}

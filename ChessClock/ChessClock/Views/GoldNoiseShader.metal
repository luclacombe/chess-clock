#include <metal_stdlib>
using namespace metal;

// MARK: - Simplex Noise Helpers (Gustavson/McEwan adapted to MSL)

static float4 permute(float4 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

static float4 taylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

// MARK: - 3D Simplex Noise

static float snoise(float3 v) {
    const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
    const float4 D = float4(0.0, 0.5, 1.0, 2.0);

    // First corner
    float3 i = floor(v + dot(v, float3(C.y)));
    float3 x0 = v - i + dot(i, float3(C.x));

    // Other corners
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    float3 x1 = x0 - i1 + C.x;
    float3 x2 = x0 - i2 + C.y;   // 2.0 * C.x = 1/3
    float3 x3 = x0 - D.yyy;      // -1.0 + 3.0 * C.x = -0.5

    // Permutations
    i = fmod(i, 289.0);
    float4 p = permute(permute(permute(
        i.z + float4(0.0, i1.z, i2.z, 1.0))
      + i.y + float4(0.0, i1.y, i2.y, 1.0))
      + i.x + float4(0.0, i1.x, i2.x, 1.0));

    // Gradients: 7x7 points over a square, mapped onto an octahedron
    float n_ = 0.142857142857;  // 1.0 / 7.0
    float3 ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);

    float4 x = x_ * ns.x + ns.yyyy;
    float4 y = y_ * ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0) * 2.0 + 1.0;
    float4 s1 = floor(b1) * 2.0 + 1.0;
    float4 sh = -step(h, float4(0.0));

    float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    // Normalise gradients
    float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// MARK: - Fractal Brownian Motion (2 octaves)

static float fbm(float3 p) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    const float persistence = 0.5;
    const float lacunarity = 2.0;

    for (int i = 0; i < 2; i++) {
        value += amplitude * snoise(p * frequency);
        amplitude *= persistence;
        frequency *= lacunarity;
    }
    return value;
}

// MARK: - Gold Color Ramp

static float3 goldColorRamp(float t) {
    // 5 gold tones mapped across [0,1]
    const float3 deep    = float3(138.0, 111.0, 31.0) / 255.0;
    const float3 cool    = float3(155.0, 125.0, 40.0) / 255.0;
    const float3 primary = float3(191.0, 155.0, 48.0) / 255.0;
    const float3 warm    = float3(220.0, 190.0, 90.0) / 255.0;
    const float3 light   = float3(212.0, 185.0, 78.0) / 255.0;

    float3 color;
    if (t < 0.25) {
        color = mix(deep, cool, smoothstep(0.0, 0.25, t));
    } else if (t < 0.5) {
        color = mix(cool, primary, smoothstep(0.25, 0.5, t));
    } else if (t < 0.75) {
        color = mix(primary, warm, smoothstep(0.5, 0.75, t));
    } else {
        color = mix(warm, light, smoothstep(0.75, 1.0, t));
    }
    return color;
}

// MARK: - Marble Color Ramp

static float3 marbleColorRamp(float t) {
    // 5 cool white/gray tones mapped across [0,1]
    const float3 deep    = float3(175.0, 170.0, 165.0) / 255.0;
    const float3 cool    = float3(195.0, 190.0, 186.0) / 255.0;
    const float3 primary = float3(215.0, 212.0, 208.0) / 255.0;
    const float3 warm    = float3(232.0, 230.0, 226.0) / 255.0;
    const float3 light   = float3(242.0, 240.0, 237.0) / 255.0;

    float3 color;
    if (t < 0.25) {
        color = mix(deep, cool, smoothstep(0.0, 0.25, t));
    } else if (t < 0.5) {
        color = mix(cool, primary, smoothstep(0.25, 0.5, t));
    } else if (t < 0.75) {
        color = mix(primary, warm, smoothstep(0.5, 0.75, t));
    } else {
        color = mix(warm, light, smoothstep(0.75, 1.0, t));
    }
    return color;
}

// MARK: - Compute Kernel

kernel void goldNoise(
    texture2d<float, access::write> output [[texture(0)]],
    constant float &time [[buffer(0)]],
    constant float &scale [[buffer(1)]],
    constant float &speed [[buffer(2)]],
    constant float &colorScheme [[buffer(3)]],
    constant float &tintR [[buffer(4)]],
    constant float &tintG [[buffer(5)]],
    constant float &tintB [[buffer(6)]],
    constant float &tintStrength [[buffer(7)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Bounds check
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) return;

    float2 pos = float2(gid);
    float n = fbm(float3(pos.x * scale, pos.y * scale, time * speed));
    n = n * 0.5 + 0.5; // normalize to [0,1]
    n = saturate(n);    // clamp

    float3 baseColor = (colorScheme < 0.5) ? goldColorRamp(n) : marbleColorRamp(n);
    float3 finalColor = mix(baseColor, float3(tintR, tintG, tintB), tintStrength);
    output.write(float4(finalColor, 1.0), gid);
}

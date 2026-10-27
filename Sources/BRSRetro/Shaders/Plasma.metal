#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Classic demoscene plasma: a few overlapping sine fields mapped through a
// three-color cosine palette.
[[ stitchable ]] half4 plasma(float2 position,
                              half4 color,
                              float4 bounds,
                              float time,
                              float scale,
                              half4 c1,
                              half4 c2,
                              half4 c3) {
    float2 uv = (position - bounds.xy) / bounds.w * scale;
    float t = time;

    float v = sin(uv.x + t);
    v += sin((uv.y + t) * 0.7);
    v += sin((uv.x + uv.y + t) * 0.5);
    float2 c = uv - float2(sin(t * 0.3) * 2.0, cos(t * 0.4) * 2.0);
    v += sin(length(c) * 1.3 + t);
    float phase = v * 0.125 + 0.5;   // v is in -4...4

    // Cycle c1 -> c2 -> c3 -> c1 as the phase wraps, so colors stay saturated.
    float p3 = fract(phase) * 3.0;
    float f = smoothstep(0.0, 1.0, fract(p3));
    float3 stops[3] = { float3(c1.rgb), float3(c2.rgb), float3(c3.rgb) };
    int i = int(floor(p3)) % 3;
    float3 col = mix(stops[i], stops[(i + 1) % 3], f);

    return half4(half3(col), 1.0h) * color.a;
}

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

static float crtHash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// Full CRT / VHS treatment applied to a layer: barrel curvature, RGB split,
// scanlines, vignette, grain, flicker and a slow rolling tracking bar.
[[ stitchable ]] half4 crt(float2 position,
                           SwiftUI::Layer layer,
                           float4 bounds,
                           float time,
                           float curvature,
                           float chroma,
                           float scanlines,
                           float scanlinePitch,
                           float vignette,
                           float noise,
                           float flicker,
                           float rollingBar) {
    float2 uv = (position - bounds.xy) / bounds.zw;
    float2 c = uv * 2.0 - 1.0;
    float r2 = dot(c, c);
    c *= 1.0 + curvature * 0.12 * r2;
    float2 duv = c * 0.5 + 0.5;

    // Outside the curved picture is the bezel.
    if (duv.x < 0.0 || duv.x > 1.0 || duv.y < 0.0 || duv.y > 1.0) {
        return half4(0.0h, 0.0h, 0.0h, 1.0h);
    }

    float2 p = bounds.xy + duv * bounds.zw;
    float2 lo = bounds.xy;
    float2 hi = bounds.xy + bounds.zw - 1.0;
    float off = chroma * (1.0 + r2 * 2.0);
    half4 center = layer.sample(p);
    half rr = layer.sample(clamp(p + float2(off, 0.0), lo, hi)).r;
    half bb = layer.sample(clamp(p - float2(off, 0.0), lo, hi)).b;
    float3 col = float3(rr, center.g, bb);

    // Scanlines: darken every other band of `scanlinePitch` points.
    float scan = 0.5 + 0.5 * sin(p.y * 6.28318 / max(scanlinePitch, 1.0));
    col *= 1.0 - scanlines * 0.45 * scan;

    // Rolling tracking bar.
    float barPos = fract(time * 0.08);
    float bar = 1.0 - smoothstep(0.0, 0.10, abs(duv.y - barPos));
    col += rollingBar * 0.10 * bar;
    col *= 1.0 - rollingBar * 0.25 * bar * (0.5 + 0.5 * sin(p.y * 4.0 + time * 30.0));

    // Grain and flicker.
    // Grain on a 2-point cell so every sub-layer sees the same pattern.
    float2 grain = floor(p * 0.5) + float2(fract(time) * 37.0, fract(time * 0.7) * 91.0);
    float n = crtHash(grain) - 0.5;
    col += n * noise * 0.2;
    col *= 1.0 - flicker * 0.06 * (0.5 + 0.5 * sin(time * 60.0));

    // Vignette.
    float v = 1.0 - vignette * smoothstep(0.45, 1.5, length(c));
    col *= v;

    return half4(half3(clamp(col, 0.0, 1.0)), center.a);
}

// Cheap overlay variant that only draws scanlines and a vignette on top of
// whatever is underneath. Returns premultiplied black with varying alpha.
[[ stitchable ]] half4 scanlineOverlay(float2 position,
                                       half4 color,
                                       float4 bounds,
                                       float time,
                                       float scanlines,
                                       float scanlinePitch,
                                       float vignette,
                                       float flicker) {
    float2 uv = (position - bounds.xy) / bounds.zw;
    float2 c = uv * 2.0 - 1.0;

    float scan = 0.5 + 0.5 * sin(position.y * 6.28318 / max(scanlinePitch, 1.0));
    float dark = scanlines * 0.45 * scan;
    dark += vignette * smoothstep(0.45, 1.5, length(c));
    dark += flicker * 0.06 * (0.5 + 0.5 * sin(time * 60.0));
    dark = clamp(dark, 0.0, 1.0);

    return half4(0.0h, 0.0h, 0.0h, half(dark)) * color.a;
}

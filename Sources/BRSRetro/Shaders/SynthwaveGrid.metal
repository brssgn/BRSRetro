#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Synthwave sunset: gradient sky, striped sun on the horizon, perspective grid
// scrolling toward the camera below it.
[[ stitchable ]] half4 synthwaveGrid(float2 position,
                                     half4 color,
                                     float4 bounds,
                                     float time,
                                     float horizon,
                                     half4 skyTop,
                                     half4 skyBottom,
                                     half4 sunTop,
                                     half4 sunBottom,
                                     half4 gridColor,
                                     half4 groundColor) {
    float2 uv = (position - bounds.xy) / bounds.zw;
    float aspect = bounds.z / bounds.w;
    float3 col;

    if (uv.y < horizon) {
        float t = uv.y / horizon;
        col = mix(float3(skyTop.rgb), float3(skyBottom.rgb), smoothstep(0.0, 1.0, t));

        // Stars: sparse hash-based points that fade out toward the horizon.
        float2 field = uv * float2(aspect, 1.0) * 60.0;
        float2 cell = floor(field);
        float h = fract(sin(dot(cell, float2(127.1, 311.7))) * 43758.5453);
        float2 inCell = fract(field) - float2(fract(h * 7.0), fract(h * 13.0));
        float pointSize = 0.08 + 0.06 * fract(h * 3.0);
        float dot = 1.0 - smoothstep(0.0, pointSize, length(inCell));
        float twinkle = 0.5 + 0.5 * sin(time * 2.0 + h * 40.0);
        float star = step(0.93, h) * dot * twinkle * (1.0 - t);
        col += star * 0.9;

        // Sun.
        float sunRadius = 0.22;
        float2 sunCenter = float2(0.5, horizon - 0.11);
        float2 d = (uv - sunCenter) * float2(aspect, 1.0);
        float r = length(d);
        float st = clamp((uv.y - (sunCenter.y - sunRadius)) / (2.0 * sunRadius), 0.0, 1.0);
        float3 sunCol = mix(float3(sunTop.rgb), float3(sunBottom.rgb), st);

        float stripe = 1.0;
        if (st > 0.48) {
            float band = (st - 0.48) * 14.0 - time * 0.4;
            float f = fract(band);
            float width = 0.10 + (st - 0.48) * 1.1;
            stripe = step(width, f);
        }
        float edge = 1.0 - smoothstep(sunRadius - 0.004, sunRadius + 0.004, r);
        col = mix(col, sunCol, edge * stripe);
        col += float3(sunBottom.rgb) * exp(-r * 5.0) * 0.35 * (1.0 - edge);
    } else {
        float dy = max(uv.y - horizon, 1e-4);
        float z = 0.5 / dy;                   // depth, larger near the horizon
        float wx = (uv.x - 0.5) * z * aspect * 2.4;

        // Horizontal lines scroll toward the viewer.
        float lz = fract(z - time * 1.2);
        float distZ = min(lz, 1.0 - lz);
        float thickZ = (1.5 / bounds.w) * 0.5 / (dy * dy);
        float lineZ = 1.0 - smoothstep(0.0, thickZ, distZ);
        float glowZ = 1.0 - smoothstep(0.0, thickZ * 5.0, distZ);

        float lx = fract(wx);
        float distX = min(lx, 1.0 - lx);
        float thickX = (1.5 / bounds.z) * z * aspect * 2.4;
        float lineX = 1.0 - smoothstep(0.0, thickX, distX);
        float glowX = 1.0 - smoothstep(0.0, thickX * 5.0, distX);

        float fade = smoothstep(0.0, 0.10, dy);
        float line = max(lineZ, lineX) * fade;
        float glow = max(glowZ, glowX) * fade * 0.45;

        float3 ground = mix(float3(skyBottom.rgb) * 0.6, float3(groundColor.rgb), fade);
        col = ground + float3(gridColor.rgb) * (line + glow);

        // Horizon glow bleeding onto the ground.
        col += float3(sunBottom.rgb) * exp(-dy * 18.0) * 0.5;
    }

    return half4(half3(col), 1.0h) * color.a;
}

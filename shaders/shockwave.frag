// Shockwave: expanding thin ring for coin pickup
// Uses Flutter runtime_effect API
#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uProgress; // 0..1
uniform vec2 uCenter; // uv coords (0..1)
uniform float uMaxRadius; // in uv space (0..1)
uniform float uWidth; // ring width in uv

out vec4 fragColor;

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 uv = pos / uSize;
  vec2 p = uv - uCenter;
  // preserve aspect
  p.x *= uSize.x / uSize.y;
  float dist = length(p);

  // Use a small ramp so we don't have a zero-radius edge case when uProgress==0
  float ramp = smoothstep(0.02, 1.0, uProgress);
  float radius = uMaxRadius * ramp;

  // subtle animated ripple (small perturbation)
  float ripple = (uMaxRadius * 0.01) * sin(40.0 * dist - 6.0 * uProgress + uTime * 6.0);

  // ring width shrinks slightly as it expands
  float w = max(0.001, uWidth * (1.0 - uProgress * 0.8));

  // robust ring via distance to the desired radius
  float d = abs(dist - radius + ripple);
  float ring = 1.0 - smoothstep(0.5 * w, 1.5 * w, d);

  // fade overall as progress finishes; multiply by ramp so nothing shows until ramp>0
  float fade = ramp * (1.0 - uProgress);

  float alpha = clamp(ring * fade, 0.0, 1.0);

  vec3 color = vec3(1.0, 0.95, 0.7);
  // Use a smooth mask instead of discard (SkSL/runtime_effect doesn't allow discard)
  float mask = smoothstep(0.001, 0.004, alpha);
  vec3 premult = color * alpha * mask;
  float outAlpha = alpha * mask;
  fragColor = vec4(premult, outAlpha);
}

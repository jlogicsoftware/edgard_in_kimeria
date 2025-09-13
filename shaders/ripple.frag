// Background displacement shockwave (samples the background texture)
#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uSize; // draw rect size in pixels
uniform vec2 uCenter; // uv center (0..1)
uniform float uTime;
uniform float uProgress; // 0..1
uniform float uMaxRadius; // in uv units (0..1)
uniform float uStrength; // displacement amplitude in uv units
uniform float uFrequency; // ripple frequency
uniform float uDecay; // how fast ripple decays from ring

out vec4 fragColor;

void main() {
  vec2 pos = FlutterFragCoord().xy;
  vec2 uv = pos / uSize;
  vec2 p = uv - uCenter;
  // correct aspect
  p.x *= uSize.x / uSize.y;
  float dist = length(p);

  float radius = uMaxRadius * uProgress;

  // distance from the ring
  float d = dist - radius;

  // radial ripple: sinusoidal displacement centered on ring
  float ripple = sin(d * uFrequency - uTime * 6.0);

  // envelope: strongest near the ring, decays away
  float env = exp(-abs(d) * uDecay);

  float disp = uStrength * ripple * env;

  // move UV outward along radial direction
  vec2 dir = (dist > 0.0001) ? normalize(p) : vec2(0.0);
  vec2 offset = dir * disp;

  // account aspect when sampling back
  offset.x *= uSize.y / uSize.x;

  vec2 sampleUV = uv + offset;

  // sample background texture
  vec4 color = texture(uTexture, sampleUV);

  fragColor = color;
}

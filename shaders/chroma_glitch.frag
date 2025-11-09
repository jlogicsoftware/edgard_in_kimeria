#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uIntensity;
uniform float uShiftIntensity;

uniform sampler2D tGameCanvas;

out vec4 fragColor;

// Hash function for pseudo-random numbers
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Random function based on UV coordinates and time
float random(vec2 uv, float time) {
    return hash(dot(uv, vec2(12.9898, 78.233)) + time);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Calculate RGB channel shifts on X axis (controlled from Dart)
    float redShift = uIntensity * uShiftIntensity;   // Red shifts right
    float blueShift = -uIntensity * uShiftIntensity; // Blue shifts left
    // Green stays in center

    // Calculate horizontal shake offset (proportional to shift intensity)
    float shakeX = sin(uTime * 15.0) * (uShiftIntensity * 0.25) * uIntensity;

    // Apply shake to base UV
    vec2 shakenUV = uv + vec2(shakeX, 0.0);

    // Sample RGB channels from shifted positions
    vec2 redUV = shakenUV + vec2(redShift, 0.0);
    vec2 greenUV = shakenUV; // Green channel unshifted
    vec2 blueUV = shakenUV + vec2(blueShift, 0.0);

    // Clamp UV coordinates to prevent sampling outside texture
    redUV = clamp(redUV, vec2(0.0), vec2(1.0));
    greenUV = clamp(greenUV, vec2(0.0), vec2(1.0));
    blueUV = clamp(blueUV, vec2(0.0), vec2(1.0));

    // Use UV coordinates directly (they are already normalized)
    vec2 redTexCoord = redUV;
    vec2 greenTexCoord = greenUV;
    vec2 blueTexCoord = blueUV;

    // Sample the rendered subtree texture at shifted coordinates
    float red = texture(tGameCanvas, redTexCoord).r;
    float green = texture(tGameCanvas, greenTexCoord).g;
    float blue = texture(tGameCanvas, blueTexCoord).b;

    // Get original alpha from center position
    float alpha = texture(tGameCanvas, greenTexCoord).a;

    // Combine channels with chromatic aberration
    vec3 color = vec3(red, green, blue);

    fragColor = vec4(color, alpha);
}
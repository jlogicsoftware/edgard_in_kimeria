import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

class ChromaGlitchPostProcess extends PostProcess {
  ChromaGlitchPostProcess({
    required this.fragmentProgram,
    this.shiftIntensity = 0.002,
  });

  final FragmentProgram fragmentProgram;

  // Chromatic aberration intensity (controlled from Dart)
  double shiftIntensity;

  late final FragmentShader shader = fragmentProgram.fragmentShader();

  // State variables
  double _time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    // Always get the rendered subtree - this is required for content to appear
    final preRenderedSubtree = rasterizeSubtree();

    // Use the actual image dimensions for shader uniforms
    final imageSize = Vector2(preRenderedSubtree.width.toDouble(),
        preRenderedSubtree.height.toDouble());

    // Apply the chromatic aberration effect with dynamic shift intensity
    shader
      ..setFloatUniforms((value) {
        value
          ..setVector(imageSize)
          ..setFloat(_time)
          ..setFloat(1.0) // Base intensity (always 1.0 when active)
          ..setFloat(
              shiftIntensity); // X-axis shift intensity controlled from Dart
      })
      ..setImageSampler(0, preRenderedSubtree);

    // Draw using the shader (with FilterQuality.none for pixel-perfect rendering)
    canvas.drawRect(
      Offset.zero & size.toSize(),
      Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.none,
    );
  }
}

import 'dart:ui';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// ShockwaveEffect
/// Displays a simple expanding ring using a fragment shader.
class ShockwaveEffect extends PositionComponent {
  final double duration;
  final double maxRadius; // in pixels
  final double ringWidth; // in pixels
  final String shaderAsset;
  final bool loop;
  late FragmentProgram _program;
  late FragmentShader _shader;
  double _elapsed = 0.0;
  double _progress = 0.0;
  bool _isLoaded = false;

  ShockwaveEffect({
    required Vector2 position,
    this.duration = 0.6,
    this.maxRadius = 64.0,
    this.ringWidth = 8.0,
    this.shaderAsset = 'shaders/shockwave.frag',
    this.loop = false,
  }) : super(
          position: position,
          size: Vector2.all(maxRadius * 2.0),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    priority = 100;
    _program = await FragmentProgram.fromAsset(shaderAsset);
    _shader = _program.fragmentShader();
    _isLoaded = true;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    _progress = (_elapsed / duration).clamp(0.0, 1.0);
    if (_progress >= 1.0) {
      if (loop) {
        // restart loop
        _elapsed = 0.0;
        _progress = 0.0;
      } else {
        removeFromParent();
      }
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;
    // size is in pixels; compute center in uv coords
    final uSizeX = size.x;
    final uSizeY = size.y;
    // center should be in uv of the drawn rect (0.5,0.5)
    final center = Vector2(0.5, 0.5);

    _shader.setFloat(0, uSizeX);
    _shader.setFloat(1, uSizeY);
    _shader.setFloat(2, _elapsed);
    _shader.setFloat(3, _progress);
    _shader.setFloat(4, center.x);
    _shader.setFloat(5, center.y);
    // convert maxRadius and ringWidth (pixels) to uv space by dividing by max(size.x,size.y)
    final maxDim = max(uSizeX, uSizeY);
    _shader.setFloat(6, (maxRadius / maxDim).clamp(0.0, 1.0));
    _shader.setFloat(7, (ringWidth / maxDim).clamp(0.001, 1.0));

    final paint = Paint()
      ..shader = _shader
      // Use additive blending so the ring glows over the background and
      // transparent areas don't show as a fog rectangle.
      ..blendMode = BlendMode.plus;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

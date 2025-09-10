import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// BombExplosionEffect
/// Displays a sparkly cartoon explosion using a fragment shader.
class BombExplosionEffect extends PositionComponent {
  final double duration;
  late FragmentProgram _program;
  late FragmentShader _shader;
  double _elapsed = 0.0;
  double _progress = 0.0;
  bool _isLoaded = false;

  BombExplosionEffect({
    required Vector2 position,
    double size = 64.0,
    this.duration = 0.7,
  }) : super(
          position: position,
          size: Vector2.all(size),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    priority = 100;
    _program = await FragmentProgram.fromAsset('shaders/bomb_explosion.frag');
    _shader = _program.fragmentShader();
    _isLoaded = true;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    _progress = (_elapsed / duration).clamp(0.0, 1.0);
    if (_progress >= 1.0) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Only render if the shader is loaded
    if (!_isLoaded) return;
    // Set shader uniforms
    _shader.setFloat(0, size.x); // uSize.x
    _shader.setFloat(1, size.y); // uSize.y
    _shader.setFloat(2, _elapsed); // uTime
    _shader.setFloat(3, _progress); // uProgress
    final paint = Paint()..shader = _shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

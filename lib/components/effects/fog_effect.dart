import 'dart:ui';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// A post-processing fog effect using a fragment shader.
class FogEffect extends PositionComponent
    with HasGameReference<EdgardInKimeria> {
  late FragmentProgram _program;
  late FragmentShader _shader;
  double _time = 0.0;

  FogEffect();

  @override
  Future<void> onLoad() async {
    _program = await FragmentProgram.fromAsset('shaders/fog.frag');
    _shader = _program.fragmentShader();
    priority = 10000; // Render on top
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // Always match camera viewport
    final rect = game.camera.visibleWorldRect;
    size = Vector2(rect.width, rect.height);
    position = Vector2(rect.left, rect.top);
  }

  @override
  void render(Canvas canvas) {
    // Set shader uniforms for the current viewport
    _shader.setFloat(0, size.x); // uSize.x
    _shader.setFloat(1, size.y); // uSize.y
    _shader.setFloat(2, 0.0); // uGroundPos
    _shader.setFloat(3, 0.0); // uGroundAdd
    _shader.setFloat(4, 1.0); // uFade
    _shader.setFloat(5, _time); // uTime
    final paint = Paint()..shader = _shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

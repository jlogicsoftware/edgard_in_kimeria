import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';

/// RippleEffect
/// Captures the given TiledComponent into a ui.Image each frame (using the
/// current camera transform) and runs a displacement shader sampling that
/// image. The ripple is centered at [centerWorld] (world coordinates) so it
/// moves with the camera.
class RippleEffect extends PositionComponent
    with HasGameReference<EdgardInKimeria> {
  final TiledComponent tiled;
  final Vector2 centerWorld;
  final double duration;
  final double maxRadius; // pixels
  final double strength; // pixels
  final double frequency;
  final double decay;

  late ui.FragmentProgram _program;
  late ui.FragmentShader _shader;
  ui.Image? _image;
  double _elapsed = 0.0;
  double _progress = 0.0;
  bool _isLoaded = false;
  bool _capturing = false;

  RippleEffect({
    required this.tiled,
    required this.centerWorld,
    this.duration = 1.0,
    this.maxRadius = 120.0,
    this.strength = 12.0,
    this.frequency = 60.0,
    this.decay = 30.0,
  });

  @override
  Future<void> onLoad() async {
    _program = await ui.FragmentProgram.fromAsset('shaders/ripple.frag');
    _shader = _program.fragmentShader();
    // Render above the tilemap (which uses the default priority 0) but
    // below actors (many game actors use priority = 1). Setting priority
    // to 0 ensures the ripple draws after the tilemap but before actors.
    priority = 0;
    _isLoaded = true;
    await super.onLoad();
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    _progress = (_elapsed / duration).clamp(0.0, 1.0);
    if (_progress >= 1.0) {
      removeFromParent();
      return;
    }
    // sync to camera viewport
    final rect = game.camera.visibleWorldRect;
    position = Vector2(rect.left, rect.top);
    size = Vector2(rect.width, rect.height);

    // Start a capture if not already capturing
    if (!_capturing) {
      _capturing = true;
      _captureFrame().whenComplete(() => _capturing = false);
    }
    super.update(dt);
  }

  Future<void> _captureFrame() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Translate so tiled renders relative to the viewport top-left
      canvas.translate(-position.x, -position.y);
      // Render only the tiled component (so we don't include effects or sprites)
      tiled.render(canvas);
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.x.toInt(), size.y.toInt());
      _image = img;
      // set the sampler on the shader (if loaded)
      if (_isLoaded && _image != null) {
        _shader.setImageSampler(0, _image!);
      }
    } catch (e) {
      // ignore capture errors; will retry next frame
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded || _image == null) return;
    final uSizeX = size.x;
    final uSizeY = size.y;
    _shader.setFloat(0, uSizeX);
    _shader.setFloat(1, uSizeY);
    // center in UV relative to viewport
    final centerUv =
        Vector2(centerWorld.x - position.x, centerWorld.y - position.y);
    _shader.setFloat(2, centerUv.x / uSizeX);
    _shader.setFloat(3, centerUv.y / uSizeY);
    _shader.setFloat(4, _elapsed);
    _shader.setFloat(5, _progress);
    final maxDim = max(uSizeX, uSizeY);
    _shader.setFloat(6, (maxRadius / maxDim).clamp(0.0, 1.0));
    _shader.setFloat(7, (strength / maxDim).clamp(0.0, 1.0));
    _shader.setFloat(8, frequency);
    _shader.setFloat(9, decay);

    final paint = ui.Paint()..shader = _shader;
    // draw into the viewport-local rect
    canvas.drawRect(Rect.fromLTWH(0, 0, uSizeX, uSizeY), paint);
  }
}

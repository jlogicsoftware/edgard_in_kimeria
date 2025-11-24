import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/rendering.dart';

class RippleDecorator extends Decorator {
  RippleDecorator();

  static final _paint = Paint();
  ui.FragmentShader? _shader;

  // We support one active ripple for now for simplicity,
  // but this could be a list if the shader supported multiple.
  // Or we could just take the "strongest" one.
  RippleData? _activeRipple;

  void setShader(ui.FragmentShader shader) {
    _shader = shader;
  }

  void addRipple(RippleData ripple) {
    _activeRipple = ripple;
  }

  void removeRipple(RippleData ripple) {
    if (_activeRipple == ripple) {
      _activeRipple = null;
    }
  }

  @override
  void applyChain(void Function(Canvas) draw, Canvas canvas) {
    if (_shader == null || _activeRipple == null) {
      draw(canvas);
      return;
    }

    final ripple = _activeRipple!;

    // Capture the scene
    final recorder = ui.PictureRecorder();
    final recorderCanvas = Canvas(recorder);
    draw(recorderCanvas);
    final picture = recorder.endRecording();

    final width = ripple.screenSize.x;
    final height = ripple.screenSize.y;

    final img = picture.toImageSync(width.toInt(), height.toInt());

    _shader!.setImageSampler(0, img);
    _shader!.setFloat(0, width);
    _shader!.setFloat(1, height);
    _shader!.setFloat(2, ripple.center.x / width); // center in UV
    _shader!.setFloat(3, ripple.center.y / height);
    _shader!.setFloat(
        4, 0.0); // time (unused in this shader version or handled by progress)
    _shader!.setFloat(5, ripple.progress);
    _shader!.setFloat(6, ripple.maxRadius / width); // rough approx for UV
    _shader!.setFloat(7, ripple.strength / width);
    _shader!.setFloat(8, ripple.frequency);
    _shader!.setFloat(9, ripple.decay);

    _paint.shader = _shader;

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), _paint);

    // Cleanup
    img.dispose();
    picture.dispose();
  }
}

class RippleData {
  final Vector2 center;
  final Vector2 screenSize;
  final double maxRadius;
  double strength;
  final double frequency;
  final double decay;
  double progress;

  RippleData({
    required this.center,
    required this.screenSize,
    required this.maxRadius,
    required this.strength,
    required this.frequency,
    required this.decay,
    this.progress = 0.0,
  });
}

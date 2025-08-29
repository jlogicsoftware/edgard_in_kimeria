import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class Firefly extends Component {
  final Vector2 area;
  Component? _particle;
  double _timer = 0;
  double _hideTime = 0;
  double _flyTime = 0;
  bool _isFlying = false;
  final Random _rand = Random();
  Vector2 _start = Vector2.zero();
  Vector2 _end = Vector2.zero();
  bool debug = false;

  Firefly({required this.area});

  @override
  Future<void> onLoad() async {
    _startHide();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    // Only update if in viewport
    if (_isFlying && _timer > _flyTime) {
      _startHide();
    } else if (!_isFlying && _timer > _hideTime) {
      // Only spawn if in viewport
      final hasGameRef = findParent<HasGameReference>();
      final camera = hasGameRef?.game.camera;
      if (camera != null) {
        final viewRect = camera.visibleWorldRect;
        // Only spawn if inside viewport
        if (viewRect.contains(_start.toOffset())) {
          _startFly();
        } else {
          // Try again next frame
          _hideTime = 0.1;
        }
      } else {
        _startFly();
      }
    }
  }

  void _startFly() {
    _timer = 0;
    _isFlying = true;
    // Lifespan 2-5x longer
    _flyTime = 3.0 + _rand.nextDouble() * 4.0; // 3-7 sec
    // Start/end in viewport
    _start = Vector2(_rand.nextDouble() * area.x, _rand.nextDouble() * area.y);
    // Curve: control point offset
    final control = _start +
        Vector2(_rand.nextDouble() * 60 - 30, _rand.nextDouble() * 60 - 30);
    _end = _start +
        Vector2(_rand.nextDouble() * 40 - 20, _rand.nextDouble() * 40 - 20);
    _particle?.removeFromParent();
    _particle = ParticleSystemComponent(
      particle: ComputedParticle(
        lifespan: _flyTime,
        renderer: (canvas, particle) {
          final t = particle.progress;
          // Quadratic Bezier curve
          final pos = _start * (1 - t) * (1 - t) +
              control * 2 * (1 - t) * t +
              _end * t * t;
          double opacity = 1.0;
          if (t < 0.5) {
            opacity = t * 2; // fade in
          } else {
            opacity = (1 - t) * 2; // fade out
          }
          // Main black dot, more opaque, no blur
          final paint = Paint()
            ..color = Colors.black.withAlpha((opacity * 255).toInt());
          // Optional debug: red dot overlay
          if (debug) {
            final debugPaint = Paint()..color = Colors.red.withAlpha(180);
            canvas.drawCircle(pos.toOffset(), 3, debugPaint);
          }
          // 2-3px size
          final radius = 2 + _rand.nextDouble();
          canvas.drawCircle(pos.toOffset(), radius, paint);
        },
      ),
    );
    add(_particle!);
  }

  void _startHide() {
    _timer = 0;
    _isFlying = false;
    _hideTime = 1.0 + _rand.nextDouble() * 1.0; // 1-2 sec
    _particle?.removeFromParent();
    _particle = null;
    // Pick new start for next fly
    _start = Vector2(_rand.nextDouble() * area.x, _rand.nextDouble() * area.y);
  }
}

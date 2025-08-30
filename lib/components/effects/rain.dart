import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class RainDrop extends Component {
  static int initialDrops = 60;
  static bool initialized = false;
  // Remove global drop management, restore per-drop timer
  // Stable wind for all drops
  static double? stableWind;
  final Vector2 area;
  Component? _particle;
  final Random _rand = Random();

  RainDrop({required this.area});

  @override
  Future<void> onLoad() async {
    // Only spawn initial drops once per session
    if (!initialized) {
      initialized = true;
      for (int i = 0; i < initialDrops; i++) {
        final delay = (_rand.nextDouble() * 0.8);
        Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
          if (parent != null) {
            (parent as Component).add(RainDrop(area: area));
          }
        });
      }
    }
    _startRain();
  }

  void _startRain() {
    // Always start above the viewport, relative to camera
    double xStart = _rand.nextDouble() * area.x;
    // If parent is World, get camera offset
    if (parent != null && parent is HasGameReference) {
      final camera = (parent as HasGameReference).game.camera;
      xStart += camera.visibleWorldRect.left;
    }
    final start = Vector2(xStart, -20.0);
    // Stable wind: set once for all drops
    stableWind ??= (_rand.nextDouble() - 0.5) * 48.0;
    final wind = stableWind!;
    // Always fall for full screen height, regardless of camera movement
    final end = Vector2(start.x + wind, area.y + 40.0);
    // Duration based on distance for smoothness
    final fallDistance = end.y - start.y;
    final speed = 400.0 + _rand.nextDouble() * 80.0; // px/sec
    final duration = fallDistance / speed;
    _particle?.removeFromParent();
    _particle = ParticleSystemComponent(
      particle: MovingParticle(
        from: start,
        to: end,
        child: ComputedParticle(
          lifespan: duration,
          renderer: (canvas, particle) {
            // Solid black for prototype
            final paint = Paint()..color = Colors.black;
            // Longer drop for smoother motion
            canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: 1.2, height: 14.0),
              paint,
            );
          },
        ),
      ),
    );
    add(_particle!);
    Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
      if (parent != null) {
        (parent as Component).add(RainDrop(area: area));
      }
    });
  }
}

import 'dart:async';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Bat extends SpriteAnimationComponent
    with HasGameReference<EdgardInKimeria> {
  final bool isVertical;
  final double offNeg;
  final double offPos;
  Bat({
    this.isVertical = false,
    this.offNeg = 0,
    this.offPos = 0,
    super.position,
    super.size,
  }) : super(anchor: Anchor.topLeft);

  static const double batSpeed = 0.03;
  static const moveSpeed = 50;
  static const tileSize = 16;
  double moveDirection = 1;
  double rangeNeg = 0;
  double rangePos = 0;

  @override
  FutureOr<void> onLoad() {
    priority = 1;
    add(CircleHitbox());
    debugMode = true;

    if (isVertical) {
      rangeNeg = position.y - offNeg * tileSize;
      rangePos = position.y + offPos * tileSize;
    } else {
      rangeNeg = position.x - offNeg * tileSize;
      rangePos = position.x + offPos * tileSize;
    }

    animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('enemy/Bat.png'),
        SpriteAnimationData.sequenced(
          amount: 5,
          stepTime: batSpeed,
          textureSize: Vector2.all(16),
        ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Use scaled dt for movement logic, but unscaled dt for animation
    final scaledDt = dt * game.timeScale;
    if (isVertical) {
      _moveVertically(scaledDt);
    } else {
      _moveHorizontally(scaledDt);
    }
    // Always update animation with real dt for smoothness
    super.update(dt);
  }

  void _moveVertically(double dt) {
    if (position.y >= rangePos) {
      moveDirection = -1;
    } else if (position.y <= rangeNeg) {
      moveDirection = 1;
    }
    position.y += moveDirection * moveSpeed * dt;
  }

  void _moveHorizontally(double dt) {
    if (position.x >= rangePos) {
      moveDirection = -1;
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
    }
    position.x += moveDirection * moveSpeed * dt;
  }
}

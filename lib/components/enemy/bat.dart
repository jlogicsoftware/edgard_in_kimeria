import 'dart:async';

import 'package:edgard_in_kimeria/components/custom_hitbox.dart';
import 'package:edgard_in_kimeria/components/enemy/enemy.dart';
import 'package:flame/components.dart';

class Bat extends Enemy {
  final bool isVertical;

  Bat({
    this.isVertical = false,
    super.offNeg = 0,
    super.offPos = 0,
    super.spriteName = 'Bat',
    required super.position,
    super.size,
  }) : super();

  static const double batSpeed = 0.03;
  static const moveSpeed = 50;
  static const tileSize = 16;

  @override
  FutureOr<void> onLoad() {
    moveDirection = 1;

    priority = 1;
    debugMode = true;

    if (isVertical) {
      rangeNeg = position.y - offNeg * tileSize;
      rangePos = position.y + offPos * tileSize;
    } else {
      rangeNeg = position.x - offNeg * tileSize;
      rangePos = position.x + offPos * tileSize;
    }

    idleAnimation =
        spriteAnimation('Idle', 5, batSpeed, Vector2.all(16), Vector2.zero());
    runAnimation = spriteAnimation(
        'Run', 5, batSpeed, Vector2.all(16), Vector2(0, 32 * 1));
    hitAnimation =
        spriteAnimation('Hit', 4, batSpeed, Vector2.all(16), Vector2(0, 32 * 2))
          ..loop = false;
    animations = {
      State.idle: idleAnimation,
      State.run: runAnimation,
      State.hit: hitAnimation,
    };
    current = State.idle;

    hitbox = CustomHitbox(radius: 8);

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

import 'dart:async';

import 'package:edgard_in_kimeria/components/environment/collidable.dart';
import 'package:edgard_in_kimeria/components/items/actionable.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum State { idle, run }

class Escalator extends SpriteAnimationGroupComponent
    with Actionable, HasGameReference<EdgardInKimeria>
    implements Collidable {
  Escalator({
    required Vector2 position,
    required Vector2 size,
    String targetId = '',
    this.offNeg = 0,
    this.offPos = 0,
    this.stepTime = 0.05,
    this.isVertical = false,
    this.moveSpeed = 50,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        ) {
    this.targetId = targetId;
  }

  @override
  bool isActive = true;

  @override
  bool isPlatform = false;

  @override
  bool isQuickSand = false;

  @override
  bool isWall = false;

  @override
  bool isEscalator = true;

  final bool isVertical;
  final double offNeg;
  final double offPos;
  final double stepTime;
  final double moveSpeed;
  double rangeNeg = 0;
  double rangePos = 0;
  final double tileSize = 32;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;

  int moveDirection = 1;

  @override
  FutureOr<void> onLoad() {
    priority = 1;
    add(
      RectangleHitbox(
        position: Vector2(0, 0),
        size: size,
      ),
    );
    debugMode = true;

    if (isVertical) {
      rangeNeg = position.y - offNeg * tileSize;
      rangePos = position.y + offPos * tileSize;
    } else {
      rangeNeg = position.x - offNeg * tileSize;
      rangePos = position.x + offPos * tileSize;
    }

    idleAnimation =
        spriteAnimation('idle', 1, stepTime, Vector2(32, 16), Vector2(0, 0));
    runAnimation =
        spriteAnimation('run', 8, stepTime, Vector2(32, 16), Vector2(0, 0));

    animations = {
      State.idle: idleAnimation,
      State.run: runAnimation,
    };
    current = State.run;

    return super.onLoad();
  }

  /// Returns the current move direction of the escalator.
  /// (1, 0) for horizontal escalators moving right
  /// (-1, 0) for horizontal escalators moving left
  /// (0, 1) for vertical escalators moving down
  /// (0, -1) for vertical escalators moving up
  Vector2 get currentMoveDirection {
    if (isVertical) {
      return Vector2(0, moveDirection.toDouble());
    }
    return Vector2(moveDirection.toDouble(), 0);
  }

  SpriteAnimation spriteAnimation(String spriteName, int amount, stepTime,
      Vector2 textureSize, Vector2 texturePosition) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache(
          'objects/${'idle' == spriteName ? 'Grey Off' : 'Grey On (32x8)'}.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
        texturePosition: texturePosition,
      ),
    );
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
      flipHorizontallyAroundCenter();
    } else if (position.x <= rangeNeg) {
      moveDirection = 1;
      flipHorizontallyAroundCenter();
    }
    position.x += moveDirection * moveSpeed * dt;
  }

  void _changeState() {
    if (current == State.idle) {
      current = State.run;
    } else {
      current = State.idle;
    }
  }

  @override
  void performAction() {
    _changeState();
  }
}

import 'dart:async';
import 'dart:ui';

import 'package:edgard_in_kimeria/components/enemy/enemy.dart';
// import 'package:edgard_in_kimeria/components/player.dart';
// import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum State { idle, run, hit }

class YellowMob extends Enemy {
  // final double offNeg;
  // final double offPos;

  YellowMob({
    required super.position,
    Vector2? size,
    super.offNeg = 0,
    super.offPos = 0,
  }) : super(
          size: size ?? Vector2(48, 32),
          spriteName: 'yellow_mob',
        );

  static const kStepTime = 0.05;
  static const tileSize = 16;
  static const runSpeed = 80;
  static const _bounceHeight = 260.0;

  // Vector2 velocity = Vector2.zero();
  // double rangeNeg = 0;
  // double rangePos = 0;
  double targetDirection = -1;
  bool gotStomped = false;

  // late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _hitAnimation;

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    priority = 1;
    player = game.player;
    moveDirection = 0;

    add(
      RectangleHitbox(
        position: Vector2(10, 6),
        size: Vector2(14, 26),
      ),
    );
    _loadAllAnimations();
    _calculateRange();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      _updateState();
      _movement(dt);
    }

    super.update(dt);
  }

  void _loadAllAnimations() {
    _idleAnimation = spriteAnimation(
        'Idle', 4, kStepTime, Vector2.array([48, 32]), Vector2(0, 32 * 5));
    _runAnimation = spriteAnimation(
        'Run', 4, kStepTime, Vector2.array([48, 32]), Vector2(0, 32 * 1));
    _hitAnimation = spriteAnimation(
        'Hit', 4, kStepTime, Vector2.array([48, 32]), Vector2(0, 32 * 4))
      ..loop = false;

    animations = {
      State.idle: _idleAnimation,
      State.run: _runAnimation,
      State.hit: _hitAnimation,
    };

    current = State.idle;
  }

  // SpriteAnimation _spriteAnimation(String state, int amount, Vector2 position) {
  //   return SpriteAnimation.fromFrameData(
  //     game.images.fromCache('enemy/yellow_mob.png'),
  //     SpriteAnimationData.sequenced(
  //       amount: amount,
  //       stepTime: kStepTime,
  //       textureSize: Vector2.array([48, 32]),
  //       texturePosition: Vector2(position.x, position.y),
  //     ),
  //   );
  // }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  void _movement(double dt) {
    // set velocity to 0;
    velocity.x = 0;

    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double yellowMobOffset = (scale.x > 0) ? 0 : -width;

    if (_playerInRange()) {
      // player in range
      targetDirection =
          (player.x + playerOffset < position.x + yellowMobOffset) ? -1 : 1;
      velocity.x = targetDirection * runSpeed;
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;

    position.x += velocity.x * dt;
  }

  bool _playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;

    return player.x + playerOffset >= rangeNeg &&
        player.x + playerOffset <= rangePos &&
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  void _updateState() {
    current = (velocity.x != 0) ? State.run : State.idle;

    if ((moveDirection < 0 && scale.x > 0) ||
        (moveDirection > 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  @override
  void collidedWithPlayer({bool gotHit = false}) async {
    if (gotHit ||
        (player.velocity.y > 0 && player.y + player.height > position.y)) {
      if (game.playSounds) {
        game.bouncePool.start(volume: game.soundVolume);
      }
      gotStomped = true;
      current = State.hit;
      if (!gotHit) player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }
}

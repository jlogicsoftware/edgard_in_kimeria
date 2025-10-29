import 'dart:async';
import 'dart:ui';

import 'package:edgard_in_kimeria/components/enemy/enemy.dart';
// import 'package:edgard_in_kimeria/components/player.dart';
// import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum State { idle, run, hit, attack }

class RedMob extends Enemy {
  RedMob({
    required super.position,
    Vector2? size,
    super.offNeg = 0,
    super.offPos = 0,
  }) : super(
          size: size ?? Vector2(48, 32),
          spriteName: 'mobs',
        );

  static const kStepTime = 0.1;
  static const tileSize = 16;
  static const runSpeed = 80;
  static const _bounceHeight = 260.0;

  double targetDirection = -1;
  bool gotStomped = false;
  bool isAttacking = false;

  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _attackAnimation;

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
      _checkAttackCollision();
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
    _attackAnimation = spriteAnimation(
        'Attack', 4, kStepTime * 2, Vector2.array([48, 32]), Vector2(0, 32 * 2))
      ..loop = false;

    animations = {
      State.idle: _idleAnimation,
      State.run: _runAnimation,
      State.hit: _hitAnimation,
      State.attack: _attackAnimation,
    };

    current = State.idle;
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  void _movement(double dt) {
    if (isAttacking) {
      // don't move while attacking
      return;
    }

    // set velocity to 0;
    velocity.x = 0;

    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double redMobOffset = (scale.x > 0) ? 0 : -width;

    if (_playerInAttackRange()) {
      // player in attack range
      _performAttack();
      return;
    } else if (_playerInRange()) {
      // player in range
      targetDirection =
          (player.x + playerOffset < position.x + redMobOffset) ? -1 : 1;
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

  bool _playerInAttackRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    const attackRange = 65;

    final double playerLeft = player.x + playerOffset;
    final double playerRight = playerLeft + player.width;
    final double mobLeft = position.x - attackRange;
    final double mobRight = position.x + attackRange;
    final double mobTop = position.y;
    final double mobBottom = position.y + height;

    return playerLeft >= mobLeft &&
        playerRight <= mobRight &&
        player.y + player.height > mobTop &&
        player.y < mobBottom;
  }

  void _updateState() {
    if (isAttacking) return;

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

  void _performAttack() {
    if (isAttacking) return;

    isAttacking = true;
    current = State.attack;

    animationTicker?.completed.then((_) {
      isAttacking = false;
      current = State.idle;
      // back to initial position after attack
      position.x = -100;
    });
  }

  void _checkAttackCollision() {
    if (isAttacking) {
      if (_playerInAttackRange()) {
        player.collidedWithEnemy();
      }
    }
  }
}

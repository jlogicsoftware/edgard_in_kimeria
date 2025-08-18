import 'dart:async';

import 'package:edgard_in_kimeria/components/bat.dart';
import 'package:edgard_in_kimeria/components/collectable.dart';
import 'package:edgard_in_kimeria/components/collision_block.dart';
import 'package:edgard_in_kimeria/components/custom_hitbox.dart';
import 'package:edgard_in_kimeria/components/yellow_mob.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:edgard_in_kimeria/components/utils.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  disappearing
}

enum PlayerDirection {
  left,
  right,
  up,
  down,
  none,
}

class Player extends SpriteAnimationGroupComponent
    with
        HasGameReference<EdgardInKimeria>,
        KeyboardHandler,
        CollisionCallbacks {
  Player({Vector2? position})
      : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(48),
          anchor: Anchor.topLeft,
        );

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;

  static const kStepTime = 0.1;
  static const kWalkSpeed = 50.0;
  static const kRunSpeed = 100.0;

  var playerDirection = PlayerDirection.none;
  bool isPlayerFacingRight = true;

  static const kGravity = 9.8;
  static const kJumpForce = 260.0;
  static const kTerminalVelocity = 300.0;

  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 16,
    offsetY: 20,
    width: 15,
    height: 28,
  );
  static const kFixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  bool isInQuickSand = false;

  static const kLeftFollow = 200;
  static const kUpFollow = 200;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = true;

    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));

    game.camera.moveTo(
      startingPosition - Vector2.array([200, 200]),
      speed: 500,
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;
    _updateCameraPosition();

    while (accumulatedTime >= kFixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(kFixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(kFixedDeltaTime);
        _checkVerticalCollisions();
      }

      accumulatedTime -= kFixedDeltaTime;
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    // return super.onKeyEvent(event, keysPressed);
    return false;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Collectable) other.collideWithPlayer();
      if (other is Bat) _respawn();
      if (other is YellowMob) other.collidedWithPlayer();
      // if (other is Checkpoint) _reachedCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 9));
    runningAnimation = _spriteAnimation(
      image: 'hero/Player.png',
      amount: 4,
      position: Vector2(0, 48 * 0),
    );
    jumpingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 1, position: Vector2(0, 48 * 8));
    fallingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 1, position: Vector2(0, 48 * 4));
    hitAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 2, position: Vector2(0, 48 * 4))
      ..loop = false;
    appearingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 6));
    disappearingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 6));

    // List of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
    };
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(
      {required String image, required int amount, required Vector2 position}) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache(image),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: kStepTime,
        textureSize: Vector2.all(48),
        texturePosition: Vector2(position.x, position.y),
        loop: true,
      ),
    );
  }

  void _updateCameraPosition() {
    if (isPlayerFacingRight) {
      game.camera.moveTo(
        Vector2(
          position.x - kLeftFollow - hitbox.width,
          position.y - kUpFollow,
        ),
        speed: 500,
      );
    } else {
      game.camera.moveTo(
        Vector2(
          position.x - kLeftFollow * 2 - hitbox.width * 3,
          position.y - kUpFollow,
        ),
        speed: 500,
      );
    }
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
      isPlayerFacingRight = false;
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
      isPlayerFacingRight = true;
    }

    // Check if moving, set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    // check if Falling set to falling
    if (velocity.y > 0) playerState = PlayerState.falling;

    // Checks if jumping, set to jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);

    if (velocity.y > kGravity * 15) isOnGround = false; // Coyote Time

    velocity.x = horizontalMovement * moveSpeed;
    if (isInQuickSand) {
      velocity.x *= 0.1; // Strong slow down movement in quicksand
    }
    position.x += velocity.x * dt;

    // if player's position is outside the screen (Y > 380), respawn
    if (position.y > 380) {
      _respawn();
    }
  }

  void _playerJump(double dt) {
    if (game.playSounds) {
      game.jumpPool.start(volume: game.soundVolume);
    }
    velocity.y = -kJumpForce;
    if (isInQuickSand) {
      velocity.y *= 0.5; // Slow down jump in quicksand
    }
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform && !block.isQuickSand) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      } else if (block.isQuickSand) {
        if (checkCollision(this, block)) {
          isInQuickSand = true;
        } else {
          isInQuickSand = false;
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += kGravity;
    velocity.y = velocity.y.clamp(-kJumpForce, kTerminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else if (block.isQuickSand) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            isOnGround = true;
            break;
          }
          // Removed velocity.x *= 0.1; from here for consistency
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  void _respawn() async {
    if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
    const canMoveDuration = Duration(milliseconds: 400);
    gotHit = true;
    current = PlayerState.hit;

    await animationTicker?.completed;
    animationTicker?.reset();

    // scale.x = 1;
    // position = startingPosition + Vector2.all(32);
    // current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition - Vector2.all(16);
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
    game.camera.moveTo(Vector2.all(0), speed: 500);
  }

  void _reachedCheckpoint() async {
    reachedCheckpoint = true;
    if (game.playSounds) {
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640);

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
  }

  void collidedWithEnemy() {
    _respawn();
  }
}

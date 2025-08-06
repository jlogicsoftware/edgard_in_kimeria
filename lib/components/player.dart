import 'dart:async';

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

  final kStepTime = 0.1;
  var playerDirection = PlayerDirection.none;
  final walkSpeed = 50.0;
  final runSpeed = 100.0;
  // var velocity = Vector2.zero();
  bool isPlayerFacingRight = true;

  final double _gravity = 9.8;
  final double _jumpForce = 260;
  final double _terminalVelocity = 300;
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
  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  bool isInQuickSand = false;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = true;

    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }

      accumulatedTime -= fixedDeltaTime;
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

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      // if (other is Fruit) other.collidedWithPlayer();
      // if (other is Saw) _respawn();
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
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 6));
    fallingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 6));
    hitAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 6))
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

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
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

    if (velocity.y > _gravity * 15) isOnGround = false; // Coyote Time

    velocity.x = horizontalMovement * moveSpeed;
    if (isInQuickSand) {
      velocity.x *= 0.5; // Slow down movement in quicksand
    }
    position.x += velocity.x * dt;

    // if player's position is outside the screen (Y > 380), respawn
    if (position.y > 380) {
      _respawn();
      // return;
    }
  }

  void _playerJump(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = -_jumpForce;
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
            print(
                'Collided with block on right ${block.isPlatform} ${block.isQuickSand}');
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            print('Collided with block on left');
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
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          print('Collided with platform');
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else if (block.isQuickSand) {
        if (checkCollision(this, block)) {
          print('Collided with quicksand');
          if (velocity.y > 0) {
            velocity.y = 0;
            isOnGround = true;
            break;
          }
          // Slow down the player in quicksand
          velocity.x *= 0.1;
        }
      } else {
        if (checkCollision(this, block)) {
          print('Collided with block');
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
    // const canMoveDuration = Duration(milliseconds: 400);
    // gotHit = true;
    // current = PlayerState.hit;

    // await animationTicker?.completed;
    // animationTicker?.reset();

    // scale.x = 1;
    position = startingPosition - Vector2.all(32);
    current = PlayerState.appearing;

    // await animationTicker?.completed;
    // animationTicker?.reset();

    velocity = Vector2.zero();
    // position = startingPosition;
    // _updatePlayerState();
    // Future.delayed(canMoveDuration, () => gotHit = false);
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

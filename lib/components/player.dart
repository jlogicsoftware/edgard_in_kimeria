import 'dart:async';
import 'dart:math';

import 'package:edgard_in_kimeria/components/actor.dart';
import 'package:edgard_in_kimeria/components/custom_hitbox.dart';
import 'package:edgard_in_kimeria/components/enemy/bat.dart';
import 'package:edgard_in_kimeria/components/enemy/enemy.dart';
import 'package:edgard_in_kimeria/components/environment/checkpoint.dart';
import 'package:edgard_in_kimeria/components/items/bomb.dart';
import 'package:edgard_in_kimeria/components/items/collectable.dart';
import 'package:edgard_in_kimeria/components/enemy/yellow_mob.dart';
import 'package:edgard_in_kimeria/components/items/trigger.dart';
import 'package:edgard_in_kimeria/components/mixins/collide_mixin.dart';
import 'package:edgard_in_kimeria/components/mixins/gravity_mixin.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

class Player extends Actor
    with
        HasGameReference<EdgardInKimeria>,
        KeyboardHandler,
        CollisionCallbacks,
        GravityMixin,
        CollideMixin {
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
  late final SpriteAnimation attackingAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;
  late final SpriteAnimation climbingAnimation;

  static const kStepTime = 0.1;
  static const kWalkSpeed = 50.0;
  static const kRunSpeed = 100.0;

  var playerDirection = ActorDirection.none;
  bool isPlayerFacingRight = true;

  static const kGravity = 9.8;
  static const kJumpForce = 260.0;
  static const kTerminalVelocity = 300.0;

  static const kNumberOfTries = 3;
  int numberOfLives = kNumberOfTries;

  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 startingPosition = Vector2.zero();
  @override
  Vector2 velocity = Vector2.zero();
  @override
  bool isOnGround = false;
  bool isJumping = false;
  bool isAttacking = false;
  bool isAttackHitboxAdded = false;
  late RectangleHitbox attackHitbox;
  bool isGotHit = false;
  bool isReachedCheckpoint = false;
  String collideWithTriggerId = "";

  // Add movement input tracking
  bool _isMovementInputActive = false;
  ActorDirection _inputDirection = ActorDirection.none;

  static const kFixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  static const kLeftFollow = 200;
  static const kUpFollow = 200;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = true;
    priority = 1;

    startingPosition = Vector2(position.x, position.y);

    hitbox = CustomHitbox(
      offsetX: 18,
      offsetY: 26,
      width: 11,
      height: 22,
    );

    game.camera.moveTo(
      startingPosition - Vector2.array([200, 200]),
      speed: 500,
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Bullet time: slow down if near a Bat (using hitboxes)
    final bats = parent?.children.whereType<Bat>() ?? [];
    bool nearBat = false;
    // Get player's hitbox rect in world coordinates (handles flipping)
    final playerHitbox = (children.whereType<ShapeHitbox>().isNotEmpty)
        ? children.whereType<ShapeHitbox>().first.toAbsoluteRect()
        : Rect.fromLTWH(
            position.x + hitbox.offsetX,
            position.y + hitbox.offsetY,
            hitbox.width,
            hitbox.height,
          );
    for (final bat in bats) {
      // Try to get bat's hitbox (if it has one)
      final batHitbox = bat.children.whereType<ShapeHitbox>().isNotEmpty
          ? bat.children.whereType<ShapeHitbox>().first
          : null;
      if (batHitbox != null) {
        final batRect = batHitbox.toAbsoluteRect();
        // Compute min distance between rectangles
        final dx = max(
            0,
            max(batRect.left - playerHitbox.right,
                playerHitbox.left - batRect.right));
        final dy = max(
            0,
            max(batRect.top - playerHitbox.bottom,
                playerHitbox.top - batRect.bottom));
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 50) {
          nearBat = true;
          break;
        }
      }
    }

    if (nearBat && !game.isSlowTime()) {
      game.setSlowTime();
      print('slow time');
    } else if (!nearBat && game.isSlowTime()) {
      game.setNormalTime();
      print('normal time');
    }

    // Use scaled dt for gameplay logic, but unscaled dt for smooth visual updates
    final scaledDt = dt * game.timeScale;
    accumulatedTime += scaledDt;
    _updateCameraPosition();

    while (accumulatedTime >= kFixedDeltaTime) {
      if (!isGotHit && !isReachedCheckpoint) {
        _checkAttackCollisions();
        _updatePlayerState();
        _updatePlayerMovement(kFixedDeltaTime);
        checkHorizontalCollisions(this);
        applyGravity(kFixedDeltaTime);
        checkVerticalCollisions(this, kFixedDeltaTime);
      }
      accumulatedTime -= kFixedDeltaTime;
    }

    // Always update animation and position with real dt for smoothness
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!game.isGameStarted) {
      return false;
    }

    // Pause the game
    if (keysPressed.contains(LogicalKeyboardKey.escape)) {
      game.pause();
    }

    // Track movement input state
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    _isMovementInputActive = isLeftKeyPressed || isRightKeyPressed;

    // Determine input direction
    if (isLeftKeyPressed) {
      _inputDirection = ActorDirection.left;
    } else if (isRightKeyPressed) {
      _inputDirection = ActorDirection.right;
    } else {
      _inputDirection = ActorDirection.none;
    }

    // Handle movement only if not attacking
    if (!isAttacking) {
      horizontalMovement = 0;
      horizontalMovement += isLeftKeyPressed ? -1 : 0;
      horizontalMovement += isRightKeyPressed ? 1 : 0;
    }

    isJumping = keysPressed.contains(LogicalKeyboardKey.keyJ) && !isAttacking;

    if (keysPressed.contains(LogicalKeyboardKey.keyK)) {
      if (!isAttacking && isOnGround && !isJumping && !isClambering) {
        _performAttack();
      }
    }

    // If Player press L, check intersection with a "trigger", that interacts
    // with linked "actionable" object (Trigger.Name > Actionable.Name),
    // action will do something (torch changes intensity, door open/closes, etc).
    if (keysPressed.contains(LogicalKeyboardKey.keyL)) {
      print('Player pressed L key: $collideWithTriggerId');
      // if Player collide with trigger?
      if (collideWithTriggerId.isNotEmpty) {
        print('Activating Trigger with id: $collideWithTriggerId');
        print('Found ${triggers.length} triggers in the level');
        for (final trigger in triggers) {
          if (trigger.targetId == collideWithTriggerId) {
            print('Activating trigger: ${trigger.targetId}');
            trigger.activate();
          }
        }
      }
    }

    return false;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isReachedCheckpoint) {
      if (other is Collectable) other.collideWithPlayer();
      if (other is Bat && !isAttacking) _respawn();
      if (other is YellowMob && !isAttacking) other.collidedWithPlayer();
      if (other is Checkpoint) _reachedCheckpoint();
      if (other is Bomb) {
        other.collideWithPlayer();
        _respawn();
      }
      if (other is Trigger) {
        collideWithTriggerId = other.targetId;
        print('Player collided with Trigger: $collideWithTriggerId');
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Trigger) {
      collideWithTriggerId = '';
    }
    super.onCollisionEnd(other);
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
    attackingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 7, position: Vector2(0, 48 * 1))
      ..loop = false;
    appearingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 3))
      ..loop = false;
    disappearingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 4, position: Vector2(0, 48 * 6));
    climbingAnimation = _spriteAnimation(
        image: 'hero/Player.png', amount: 1, position: Vector2(0, 48 * 3));

    // List of all animations
    animations = {
      ActorState.idle: idleAnimation,
      ActorState.running: runningAnimation,
      ActorState.jumping: jumpingAnimation,
      ActorState.falling: fallingAnimation,
      ActorState.hit: hitAnimation,
      ActorState.attacking: attackingAnimation,
      ActorState.appearing: appearingAnimation,
      ActorState.disappearing: disappearingAnimation,
      ActorState.climbing: climbingAnimation,
    };
    current = ActorState.idle;
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
        amountPerRow: amount > 4 ? 4 : amount,
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
    ActorState playerState = ActorState.idle;

    // Only flip based on player input, not escalator movement
    if (horizontalMovement < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
      isPlayerFacingRight = false;
    } else if (horizontalMovement > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
      isPlayerFacingRight = true;
    }

    // Check if moving based on player input, not velocity (to handle escalators)
    if (horizontalMovement > 0 || horizontalMovement < 0) {
      playerState = ActorState.running;
    }

    // check if Falling set to falling
    if (velocity.y > 0) playerState = ActorState.falling;

    // Checks if jumping, set to jumping
    if (velocity.y < 0) playerState = ActorState.jumping;

    if (isClambering) playerState = ActorState.climbing;

    if (isAttacking) playerState = ActorState.attacking;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (isJumping && (isOnGround || isClambering)) _playerJump(dt);

    if (velocity.y > kGravity * 15) isOnGround = false; // Coyote Time

    if (!isWallJumping) {
      velocity.x = horizontalMovement * moveSpeed;
      if (isInQuickSand) {
        velocity.x *= 0.1; // Strong slow down movement in quicksand
      }
      // Add escalator velocity if player is on an escalator
      if (currentEscalator != null) {
        final escalatorVelocity = currentEscalator!.currentMoveDirection *
            currentEscalator!.moveSpeed;
        velocity.x += escalatorVelocity.x;
      }
    }
    position.x += velocity.x * dt;

    if (isClambering) {
      velocity.y *= 0.1; // Slow down movement while climbing
    }
    // Die if player's position is outside the screen
    if (position.y > 380) {
      _respawn();
    }
  }

  void _playerJump(double dt) async {
    if (game.playSounds) {
      game.jumpPool.start(volume: game.soundVolume);
    }
    if (isClambering) {
      velocity.y = -kJumpForce * 0.7;
      if (horizontalMovement < 0) {
        velocity.x = kJumpForce * 0.5;
      } else if (horizontalMovement > 0) {
        velocity.x = -kJumpForce * 0.5;
      } else {
        velocity.x = isPlayerFacingRight ? -kJumpForce * 0.5 : kJumpForce * 0.5;
      }
      isClambering = false;
      isWallJumping = true;
      Future.delayed(
          const Duration(milliseconds: 100), () => isWallJumping = false);
    } else {
      velocity.y = -kJumpForce;
      if (isInQuickSand) {
        velocity.y *= 0.1; // Slow down jump in quicksand
      }
    }
    position.y += velocity.y * dt;
    isOnGround = false;
    isJumping = false;
  }

  // void _checkHorizontalCollisions() {
  //   for (final block in collisionBlocks) {
  //     if (!block.isActive) continue;
  //     if (block.isQuickSand) {
  //       if (checkCollision(this, block)) {
  //         isInQuickSand = true;
  //       } else {
  //         isInQuickSand = false;
  //       }
  //     } else if (block.isWall) {
  //       if (checkCollision(this, block)) {
  //         if (velocity.x > 0) {
  //           velocity.x = 0;
  //           position.x = block.x - hitbox.offsetX - hitbox.width;
  //           if (!isOnGround) {
  //             isClambering = true;
  //           }
  //           break;
  //         }
  //         if (velocity.x < 0) {
  //           velocity.x = 0;
  //           position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
  //           if (!isOnGround) {
  //             isClambering = true;
  //           }
  //           break;
  //         }
  //       } else {
  //         isClambering = false;
  //       }
  //     } else {
  //       if (checkCollision(this, block)) {
  //         if (velocity.x > 0) {
  //           velocity.x = 0;
  //           position.x = block.x - hitbox.offsetX - hitbox.width;
  //           break;
  //         }
  //         if (velocity.x < 0) {
  //           velocity.x = 0;
  //           position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
  //           break;
  //         }
  //       }
  //     }
  //   }
  // }

  // void _applyGravity(double dt) {
  //   velocity.y += kGravity;
  //   velocity.y = velocity.y.clamp(-kJumpForce, kTerminalVelocity);
  //   position.y += velocity.y * dt;
  // }

  // void _checkVerticalCollisions(double dt) {
  //   // Reset escalator tracking at the start of collision check
  //   currentEscalator = null;

  //   for (final block in collisionBlocks) {
  //     if (!block.isActive) continue;
  //     if (block.isPlatform) {
  //       if (checkCollision(this, block)) {
  //         if (velocity.y > 0) {
  //           velocity.y = 0;
  //           position.y = block.y - hitbox.height - hitbox.offsetY;
  //           isOnGround = true;
  //           break;
  //         }
  //       }
  //     } else if (block.isQuickSand) {
  //       if (checkCollision(this, block)) {
  //         if (velocity.y > 0) {
  //           velocity.y = 0;
  //           isOnGround = true;
  //           break;
  //         }
  //         // Removed velocity.x *= 0.1; from here for consistency
  //       }
  //     } else {
  //       if (checkCollision(this, block)) {
  //         if (velocity.y > 0) {
  //           velocity.y = 0;
  //           position.y = block.y - hitbox.height - hitbox.offsetY;
  //           isOnGround = true;
  //           break;
  //         }
  //         if (velocity.y < 0) {
  //           velocity.y = 0;
  //           position.y = block.y + block.height - hitbox.offsetY;
  //         }
  //       }
  //     }
  //   }

  //   // Check for escalator collisions
  //   for (final escalator in escalators) {
  //     if (!escalator.isActive) continue;
  //     if (checkCollision(this, escalator)) {
  //       if (velocity.y > 0) {
  //         velocity.y = 0;
  //         position.y = escalator.y - hitbox.height - hitbox.offsetY;
  //         isOnGround = true;
  //         // Track that player is on this escalator
  //         currentEscalator = escalator;
  //         break;
  //       }
  //     }
  //   }
  // }

  void _respawn() async {
    if (isGotHit) return;
    if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);

    isGotHit = true;
    current = ActorState.hit;
    await animationTicker?.completed;
    animationTicker?.reset();

    scale.x = 1;
    velocity = Vector2.zero();
    position = startingPosition;

    current = ActorState.appearing;
    await animationTicker?.completed;
    animationTicker?.reset();
    isGotHit = false;
    current = ActorState.idle;

    // Reset camera position after respawn
    game.camera.moveTo(
      startingPosition - Vector2.array([200, 200]),
      speed: 500,
    );

    if (numberOfLives > 0) {
      numberOfLives -= 1;
    } else {
      // Trigger game over
      numberOfLives = kNumberOfTries;
      game.isGameStarted = false;
      game.overlays.add('GameOver');
      // remove player from the game world
      removeFromParent();
    }
  }

  void _reachedCheckpoint() async {
    isReachedCheckpoint = true;
    if (game.playSounds) {
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }
    // if (scale.x > 0) {
    //   position = position - Vector2.all(32);
    // } else if (scale.x < 0) {
    //   position = position + Vector2(32, -32);
    // }

    current = ActorState.disappearing;

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () {
      isReachedCheckpoint = false;
      game.loadNextLevel();
    });
  }

  void _performAttack() {
    isAttacking = true;
    // Store current movement to restore later
    // Movement will be handled by _checkAttackCollisions
  }

  void _resumeMovementAfterAttack() {
    // Resume movement based on stored input direction if still active
    if (_isMovementInputActive && _inputDirection != ActorDirection.none) {
      switch (_inputDirection) {
        case ActorDirection.left:
          horizontalMovement = -1;
          break;
        case ActorDirection.right:
          horizontalMovement = 1;
          break;
        case ActorDirection.none:
        case ActorDirection.up:
        case ActorDirection.down:
          horizontalMovement = 0;
          break;
      }
    } else {
      horizontalMovement = 0;
    }
  }

  void _checkAttackCollisions() async {
    if (!isAttacking) return;
    current = ActorState.attacking;

    horizontalMovement = 0;
    velocity.x = 0;
    isAttacking = true;

    // Define the attack hitbox dimensions and position
    if (!isAttackHitboxAdded) {
      attackHitbox = RectangleHitbox(
        position: Vector2(
          isPlayerFacingRight
              ? 16 - hitbox.offsetX + hitbox.width
              : hitbox.offsetX - 20 + hitbox.width,
          hitbox.offsetY - 14,
        ),
        size: Vector2(37, hitbox.height + 14),
      );
      attackHitbox.collisionType = CollisionType.active;
      attackHitbox.debugMode = true;
      add(attackHitbox);

      isAttackHitboxAdded = true;

      // Wait for attack animation to complete
      await animationTicker?.completed;
      animationTicker?.reset();

      // Clear attack state
      isAttacking = false;
      isAttackHitboxAdded = false;
      attackHitbox.removeFromParent();

      // Resume movement if input is still active
      _resumeMovementAfterAttack();
    }

    // Check for collisions with enemies
    for (final enemy in parent!.children.whereType<Enemy>()) {
      //.followedBy(parent!.children.whereType<Bat>().cast<YellowMob>())) {
      if (attackHitbox.toAbsoluteRect().overlaps(
          enemy.children.whereType<ShapeHitbox>().first.toAbsoluteRect())) {
        // enemy.collidedWithPlayer();
        enemy.collidedWithPlayer(gotHit: true);
        print('Enemy hit!');
        // isAttacking = false;
        // isAttackHitboxAdded = false;
        // attackHitbox.removeFromParent();
        break;
      }
    }
  }

  void collidedWithEnemy() {
    _respawn();
  }
}

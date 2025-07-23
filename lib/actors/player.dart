import 'dart:async';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

enum PlayerState {
  idle,
  walk,
  run,
  jump,
  attack,
  hurt,
  die,
  climb,
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
  Player({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(48),
          anchor: Anchor.topLeft,
        );

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation walkAnimation;
  final kStepTime = 0.1;
  var playerDirection = PlayerDirection.none;
  final moveSpeed = 50.0;
  var velocity = Vector2.zero();
  bool isPlayerFacingRight = true;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    if (isRightKeyPressed) {
      playerDirection = PlayerDirection.right;
    } else if (isLeftKeyPressed) {
      playerDirection = PlayerDirection.left;
    } else {
      playerDirection = PlayerDirection.none;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = true;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerMovement(dt);
    super.update(dt);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation(
      image: 'hero/Player.png',
      amount: 4,
      position: Vector2(0, 48 * 9),
    );

    walkAnimation = _spriteAnimation(
      image: 'hero/Player.png',
      amount: 4,
      position: Vector2(0, 48 * 0),
    );

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.walk: walkAnimation,
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

  void _updatePlayerMovement(double dt) {
    switch (playerDirection) {
      case PlayerDirection.left:
        position.x -= moveSpeed * dt;
        current = PlayerState.walk;
        if (isPlayerFacingRight) {
          flipHorizontallyAroundCenter();
          isPlayerFacingRight = false;
        }
        break;
      case PlayerDirection.right:
        position.x += moveSpeed * dt;
        current = PlayerState.walk;
        if (!isPlayerFacingRight) {
          flipHorizontallyAroundCenter();
          isPlayerFacingRight = true;
        }
        break;
      case PlayerDirection.up:
        position.y -= moveSpeed * dt;
        current = PlayerState.walk;
        break;
      case PlayerDirection.down:
        position.y += moveSpeed * dt;
        current = PlayerState.walk;
        break;
      case PlayerDirection.none:
        current = PlayerState.idle;
        break;
    }
  }
}

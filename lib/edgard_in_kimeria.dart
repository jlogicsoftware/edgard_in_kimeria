import 'dart:async';
import 'package:edgard_in_kimeria/components/overlay/hud.dart';
import 'package:flutter/material.dart';

import 'package:edgard_in_kimeria/components/player.dart';
import 'package:edgard_in_kimeria/components/overlay/jump_button.dart';
import 'package:edgard_in_kimeria/levels/level.dart';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';

class EdgardInKimeria extends FlameGame<World>
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  double timeScale = 1.0;
  final player = Player();
  late AudioPool jumpPool;
  late AudioPool bouncePool;
  late AudioPool collectPool;
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = false;
  double soundVolume = 1.0;
  List<String> levelNames = ['forest-1', 'forest'];
  int currentLevelIndex = 0;

  int coinsCollected = 0;
  bool isGameStarted = false;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();
    await FlameAudio.audioCache.loadAll([
      'jump.wav',
      'hit.wav',
      'collect.wav',
      // ...other sounds
    ]);
    // Warm up the audio engine by playing a silent sound
    await FlameAudio.play('jump.wav', volume: 0);
    // Create AudioPool for jump sound
    jumpPool = await FlameAudio.createPool('jump.wav', maxPlayers: 3);
    bouncePool = await FlameAudio.createPool('bounce.wav', maxPlayers: 3);
    collectPool = await FlameAudio.createPool('collect.wav', maxPlayers: 3);

    _loadLevel();

    if (showControls) {
      addJoystick();
      add(JumpButton());
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    // Update the camera with unscaled dt for smooth movement
    camera.update(dt);
    // Update the rest of the game with scaled dt (for bullet time, etc)
    super.update(dt * timeScale);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );

    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);

    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      // no more levels
      currentLevelIndex = 0;
      _loadLevel();
    }
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      Level world = Level(
        player: player,
        levelName: levelNames[currentLevelIndex],
      );

      camera = CameraComponent.withFixedResolution(
        world: world,
        width: 640,
        height: 360,
      );
      camera.viewfinder.anchor = Anchor.topLeft;

      camera.viewport.add(Hud());

      addAll([world]);
    });
  }

  void reset() {
    coinsCollected = 0;
    currentLevelIndex = 0;
    removeWhere((component) => component is Level);
    _loadLevel();
  }
}

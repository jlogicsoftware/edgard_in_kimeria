import 'dart:async';

import 'package:edgard_in_kimeria/components/player.dart';
import 'package:edgard_in_kimeria/components/HUD/jump_button.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'package:edgard_in_kimeria/levels/level.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/painting.dart';

class EdgardInKimeria extends FlameGame<World>
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  final player = Player();
  late AudioPool jumpPool;
  late AudioPool bouncePool;
  late AudioPool collectPool;
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = true;
  double soundVolume = 1.0;
  List<String> levelNames = ['forest', 'forest-1'];
  int currentLevelIndex = 0;

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
    super.update(dt);
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

      addAll([world]);
    });
  }
}

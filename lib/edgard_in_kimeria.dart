import 'dart:async';

import 'package:edgard_in_kimeria/components/player.dart';
import 'package:edgard_in_kimeria/components/jump_button.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'package:edgard_in_kimeria/components/level.dart';
import 'package:flutter/painting.dart';

class EdgardInKimeria extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color.fromARGB(255, 2, 9, 52);
  final player = Player();
  late CameraComponent cam;

  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = true;
  double soundVolume = 1.0;
  List<String> levelNames = ['forest', 'forest-1'];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {
    // final world = Forest(levelName: 'forest', player: player);

    await images.loadAllImages();

    // // Set the initial camera position if needed
    // _camera = CameraComponent.withFixedResolution(
    //     width: 640, height: 360, world: world);
    // _camera.viewfinder.anchor = Anchor.topLeft;
    // addAll([
    //   _camera,
    //   world,
    // ]);

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

      cam = CameraComponent.withFixedResolution(
        world: world,
        width: 640,
        height: 360,
      );
      cam.viewfinder.anchor = Anchor.topLeft;

      addAll([cam, world]);
    });
  }
}

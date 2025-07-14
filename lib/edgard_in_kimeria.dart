import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'package:edgard_in_kimeria/levels/forest.dart';

class EdgardInKimeria extends FlameGame {
  late final CameraComponent _camera;
  final _world = Forest(levelName: 'forest');

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    // Set the initial camera position if needed
    _camera = CameraComponent.withFixedResolution(
        width: 640, height: 360, world: _world);
    _camera.viewfinder.anchor = Anchor.topLeft;
    addAll([
      _camera,
      _world,
    ]);

    return super.onLoad();
  }
}

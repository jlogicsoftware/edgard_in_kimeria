import 'dart:async';

import 'package:edgard_in_kimeria/levels/forest.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class EdgardInKimeria extends FlameGame {
  late final CameraComponent _camera;
  final _world = Forest();

  @override
  FutureOr<void> onLoad() {
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

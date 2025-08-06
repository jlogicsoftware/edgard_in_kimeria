import 'dart:async';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class SkyTile extends ParallaxComponent<EdgardInKimeria> {
  SkyTile();

  final double scrollSpeed = 5;

  @override
  FutureOr<void> onLoad() async {
    priority = -10;
    size = Vector2.all(64);
    parallax = await game.loadParallax(
      [ParallaxImageData('background/sky.png')],
      baseVelocity: Vector2(scrollSpeed, 0),
    );
    return super.onLoad();
  }
}

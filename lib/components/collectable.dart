import 'dart:async';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Collectable extends SpriteAnimationComponent
    with HasGameReference<EdgardInKimeria>, CollisionCallbacks {
  final String collectableName;

  Collectable({this.collectableName = 'Coin', position, size})
      : super(
          position: position ?? Vector2.zero(),
          size: size ?? Vector2.all(16.0),
          anchor: Anchor.topLeft,
        );

  static const kStepTime = 0.3;
  bool isCollected = false;

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    priority = 1;

    add(CircleHitbox(
      radius: 8,
      position: Vector2.zero(),
      collisionType: CollisionType.passive,
    ));
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items.png'),
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: kStepTime,
        textureSize: Vector2.all(16),
        texturePosition: switch (collectableName) {
          'Coin' => Vector2(0, 0),
          'Heart' => Vector2(0, 16),
          _ => Vector2(0, 0),
        },
      ),
    );

    return super.onLoad();
  }

  void collideWithPlayer() async {
    if (!isCollected) {
      isCollected = true;
      if (game.playSounds) {
        game.collectPool.start(volume: game.soundVolume);
      }
      removeFromParent();
    }
  }
}

import 'dart:async' as async;

import 'package:edgard_in_kimeria/components/effects/bomb_explosion_effect.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Bomb extends SpriteAnimationComponent
    with HasGameReference<EdgardInKimeria>, CollisionCallbacks {
  Bomb({position, size})
      : super(
          position: position ?? Vector2.zero(),
          size: size ?? Vector2.all(16.0),
          anchor: Anchor.topLeft,
        );

  static const kStepTime = 0.1;
  bool isExploded = false;

  @override
  async.FutureOr<void> onLoad() {
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
        texturePosition: Vector2(32, 0),
      ),
    );

    return super.onLoad();
  }

  @override
  void onRemove() {
    super.onRemove();
  }

  void collideWithPlayer() async {
    if (!isExploded) {
      isExploded = true;
      if (game.playSounds) {
        game.bouncePool.start(volume: game.soundVolume);
      }
      // Add the explosion effect to the bomb's parent BEFORE removing the bomb
      parent?.add(
        BombExplosionEffect(
          position: absoluteCenter,
          size: 64,
        ),
      );
      removeFromParent();
    }
  }
}

import 'dart:async';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:edgard_in_kimeria/components/effects/shockwave_effect.dart';
import 'package:edgard_in_kimeria/components/effects/ripple_effect.dart';
import 'package:flame_tiled/flame_tiled.dart';

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
      // Show a quick shockwave when collecting coins
      if (collectableName == 'Coin') {
        game.coinsCollected += 1;

        parent?.add(RippleEffect(
          tiled: (parent as World).children.whereType<TiledComponent>().first,
          centerWorld: absoluteCenter,
          duration: 0.75,
          maxRadius: 300,
          strength: 12.0,
          frequency: 60.0,
          decay: 20.0,
        ));
      }

      if (collectableName == 'Heart') {
        parent?.add(ShockwaveEffect(
          position: absoluteCenter,
          // duration: 0.5,
          // maxRadius: 64,
          // ringWidth: 8,
          // shaderAsset: 'shaders/shockwave.frag',
        ));
      }

      removeFromParent();
    }
  }
}

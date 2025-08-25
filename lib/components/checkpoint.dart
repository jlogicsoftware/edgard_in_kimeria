import 'dart:async';

import 'package:edgard_in_kimeria/components/player.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Checkpoint extends SpriteAnimationComponent
    with HasGameReference<EdgardInKimeria>, CollisionCallbacks {
  Checkpoint({
    super.position,
    super.size,
  });

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    add(RectangleHitbox(
      position: Vector2(0, 0),
      size: Vector2(16, 32),
      collisionType: CollisionType.passive,
    ));

    return super.onLoad();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) _reachedCheckpoint();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _reachedCheckpoint() async {
    //   animation = SpriteAnimation.fromFrameData(
    //     game.images.fromCache(
    //         'Items/Checkpoints/Checkpoint/Checkpoint (Flag Out) (64x64).png'),
    //     SpriteAnimationData.sequenced(
    //       amount: 26,
    //       stepTime: 0.05,
    //       textureSize: Vector2.all(64),
    //       loop: false,
    //     ),
    //   );

    //   await animationTicker?.completed;

    //   animation = SpriteAnimation.fromFrameData(
    //     game.images.fromCache(
    //         'Items/Checkpoints/Checkpoint/Checkpoint (Flag Idle)(64x64).png'),
    //     SpriteAnimationData.sequenced(
    //       amount: 10,
    //       stepTime: 0.05,
    //       textureSize: Vector2.all(64),
    //     ),
    //   );
  }
}

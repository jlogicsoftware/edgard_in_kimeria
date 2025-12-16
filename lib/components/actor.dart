import 'dart:async';

import 'package:edgard_in_kimeria/components/custom_hitbox.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum ActorState {
  idle,
  running,
  jumping,
  falling,
  hit,
  attacking,
  appearing,
  disappearing,
  climbing
}

enum ActorDirection {
  left,
  right,
  up,
  down,
  none,
}

/// Actor class that instantiates a collision component based on the hitbox type.
/// The hitbox must be set in the onLoad method to make it work.
class Actor extends SpriteAnimationGroupComponent {
  /// Hitbox of the actor, used for collision detection
  /// This is not the same as the hitbox of the sprite
  /// The hitbox must be set in the onLoad method to make it work
  late CustomHitbox hitbox;

  Actor({Vector2? position, required Vector2 size, required Anchor anchor})
      : super(position: position ?? Vector2.zero(), size: size, anchor: anchor);

  @override
  FutureOr<void> onLoad() {
    if (hitbox.radius > 0) {
      add(CircleHitbox(
        radius: hitbox.radius,
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
      ));
    } else {
      add(RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
      ));
    }
    return super.onLoad();
  }

  void collidedWithActor({bool gotHit = false}) {}
}

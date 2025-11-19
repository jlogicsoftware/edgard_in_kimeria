import 'package:edgard_in_kimeria/components/environment/collision_block.dart';
import 'package:edgard_in_kimeria/components/items/actionable.dart';
import 'package:flame/components.dart';

class Wall extends CollisionBlock with Actionable {
  Wall({
    Vector2? position,
    Vector2? size,
    String targetId = '',
  }) : super(
          position: position,
          size: size,
          isWall: true,
        ) {
    this.targetId = targetId;
  }

  @override
  void performAction() {
    if (!isActive) return;
    print('Wall action performed: $targetId');
    isActive = false;
    removeFromParent();
  }
}

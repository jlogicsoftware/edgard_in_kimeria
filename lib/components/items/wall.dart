import 'package:edgard_in_kimeria/components/environment/collision_block.dart';
import 'package:edgard_in_kimeria/components/items/actionable.dart';

class Wall extends CollisionBlock with Actionable {
  Wall({
    super.position,
    super.size,
    String targetId = '',
  }) : super(
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

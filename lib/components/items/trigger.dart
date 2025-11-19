import 'package:edgard_in_kimeria/components/items/actionable.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Trigger extends SpriteAnimationComponent
    with HasGameReference<EdgardInKimeria>, CollisionCallbacks {
  Trigger({
    required Vector2 position,
    required Vector2 size,
    required this.targetId,
  }) : super(position: position, size: size);
  final String targetId;

  @override
  Future<void> onLoad() async {
    debugMode = true;
    priority = 1;
    add(RectangleHitbox(
      size: size,
      position: Vector2.zero(),
      collisionType: CollisionType.passive,
    ));
    return super.onLoad();
  }

  void activate() {
    print('Trigger activated with targetId: $targetId');
    // Find all Actionable components with matching targetId and perform action
    final actionableComponents = parent!.children
        .whereType<Actionable>()
        .where((actionable) => actionable.targetId == targetId);
    
    print(
        'Found ${actionableComponents.length} actionable components for targetId: $targetId');
    for (final actionable in actionableComponents) {
      print('Trigger activated for Actionable with targetId: $targetId');
      actionable.performAction();
    }
  }
}

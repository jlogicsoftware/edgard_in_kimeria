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
    final allActionables = parent!.children.whereType<Actionable>();
    print('Total Actionable components in game: ${allActionables.length}');
    for (final actionable in allActionables) {
      print('Existing Actionable targetId: ${actionable.targetId}');
    }
    final actionableComponents = parent!.children
        .whereType<Actionable>()
        .where((actionable) => actionable.targetId == targetId);
    print(
        'Found ${actionableComponents.length} actionable components for targetId: $targetId');
    for (final actionable in actionableComponents) {
      // Perform the desired action on the actionable component
      // For example, you might want to change its state, trigger an animation, etc.
      // Here, we'll just print a message for demonstration purposes
      print('Trigger activated for Actionable with targetId: $targetId');
      actionable.performAction();
    }
  }
}

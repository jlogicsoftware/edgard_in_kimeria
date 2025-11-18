import 'package:edgard_in_kimeria/components/effects/torch.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/components.dart';

class Actionable extends SpriteAnimationComponent
    with HasGameReference<EdgardInKimeria> {
  Actionable({
    required Vector2 position,
    required Vector2 size,
    required this.targetId,
    required this.type,
  }) : super(position: position, size: size);

  final String targetId;
  final String type;

  void performAction() {
    print('Action performed on Actionable with targetId: $targetId');
    print('Action type: $type');
    if (type == 'Torch') {
      final torch = parent?.children.whereType<Torch>().firstWhere(
        (t) => t.targetId == targetId,
        orElse: () {
          throw Exception(
              'No Torch found with targetId: $targetId. Available Torch IDs: ${parent?.children.whereType<Torch>().map((t) => t.targetId).toList()}');
        },
      );
      print('torch found: $targetId with intensity ${torch!.intensity}');
      torch.toggleFire(torch.intensity == 0);
      print('Torch fire toggled: $targetId, new intensity: ${torch.intensity}');
    }
  }
}

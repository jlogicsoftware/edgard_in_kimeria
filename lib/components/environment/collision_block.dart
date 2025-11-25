import 'package:edgard_in_kimeria/components/environment/collidable.dart';
import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent implements Collidable {
  @override
  bool isPlatform;
  @override
  bool isQuickSand;
  @override
  bool isWall;
  @override
  bool isActive;
  @override
  bool isEscalator;
  CollisionBlock({
    super.position,
    super.size,
    this.isPlatform = false,
    this.isQuickSand = false,
    this.isWall = false,
    this.isActive = true,
    this.isEscalator = false,
  }) {
    debugMode = true;
  }
}

import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isQuickSand;
  bool isWall = false;
  bool isActive = true;
  CollisionBlock({
    super.position,
    super.size,
    this.isPlatform = false,
    this.isQuickSand = false,
    this.isWall = false,
    this.isActive = true,
  }) {
    debugMode = true;
  }
}

import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isQuickSand;
  bool isWall = false;
  CollisionBlock({
    super.position,
    super.size,
    this.isPlatform = false,
    this.isQuickSand = false,
    this.isWall = false,
  }) {
    debugMode = true;
  }
}

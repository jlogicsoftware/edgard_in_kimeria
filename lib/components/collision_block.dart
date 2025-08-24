import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isQuickSand;
  bool isWall = false;
  CollisionBlock({
    position,
    size,
    this.isPlatform = false,
    this.isQuickSand = false,
    this.isWall = false,
  }) : super(
          position: position,
          size: size,
        ) {
    debugMode = true;
  }
}

import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isQuickSand;
  CollisionBlock({
    position,
    size,
    this.isPlatform = false,
    this.isQuickSand = false,
  }) : super(
          position: position,
          size: size,
        ) {
    debugMode = true;
  }
}

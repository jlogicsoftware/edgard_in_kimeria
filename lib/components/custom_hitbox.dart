import 'package:flame/components.dart';

/// Custom hitbox for actors with radius or width and height
/// It instantiates a circle or rectangle hitbox based on the radius
class CustomHitbox extends Component {
  final double offsetX;
  final double offsetY;
  final double width;
  final double height;
  final double radius;

  CustomHitbox({
    this.offsetX = 0,
    this.offsetY = 0,
    this.width = 0,
    this.height = 0,
    this.radius = 0,
  });
}

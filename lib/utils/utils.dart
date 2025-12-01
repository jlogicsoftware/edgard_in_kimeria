import 'package:edgard_in_kimeria/components/actor.dart';
import 'package:edgard_in_kimeria/components/environment/collidable.dart';

bool checkCollision(Actor actor, Collidable block) {
  final hitbox = actor.hitbox;
  final playerX = actor.position.x + hitbox.offsetX;
  final playerY = actor.position.y + hitbox.offsetY;
  final playerWidth = hitbox.width;
  final playerHeight = hitbox.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  var fixedX = actor.scale.x < 0
      ? playerX - (hitbox.offsetX * 2) - playerWidth
      : playerX;
  fixedX = block.isQuickSand ? playerX + (hitbox.offsetX) : fixedX;

  final fixedY = block.isPlatform ? playerY + playerHeight : playerY;

  return (fixedY < blockY + blockHeight &&
      playerY + playerHeight > blockY &&
      fixedX < blockX + blockWidth &&
      fixedX + playerWidth > blockX);
}

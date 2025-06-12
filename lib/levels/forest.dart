import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Forest extends World {
  late final TiledComponent level;

  @override
  Future<void> onLoad() async {
    level = await TiledComponent.load('forest.tmx', Vector2.all(16));
    add(level);
    level.position = Vector2.zero();
    level.size =
        Vector2.all(16 * 20); // Assuming the level is 20 tiles wide and tall
    level.anchor = Anchor.topLeft;

    return super.onLoad();
  }
}

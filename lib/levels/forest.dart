import 'package:edgard_in_kimeria/actors/player.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Forest extends World {
  final String levelName;
  Forest({required this.levelName});
  late final TiledComponent level;

  @override
  Future<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(level);
    level.position = Vector2.zero();
    level.size =
        Vector2.all(16 * 20); // Assuming the level is 20 tiles wide and tall
    level.anchor = Anchor.topLeft;

    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    for (final spawnPoint in spawnPointsLayer!.objects) {
      switch (spawnPoint.class_) {
        case 'Player':
          final playerPosition = Vector2(
            spawnPoint.x,
            spawnPoint.y,
          );
          final player = Player(position: playerPosition);
          add(player);
          break;
        default:
      }
    }

    return super.onLoad();
  }
}

import 'package:edgard_in_kimeria/components/background_tile.dart';
import 'package:edgard_in_kimeria/components/collision_block.dart';
import 'package:edgard_in_kimeria/components/player.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Level extends World {
  Level({required this.levelName, required this.player});

  final String levelName;
  late final TiledComponent level;
  final Player player;
  List<CollisionBlock> collisionBlocks = [];

  @override
  Future<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));

    add(level);

    _loadBackground();
    _spawningObjects();
    _addCollisions();

    // level.position = Vector2.zero();
    // level.size = Vector2.all(16 * 20);
    // level.anchor = Anchor.topLeft;

    // final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    // for (final spawnPoint in spawnPointsLayer!.objects) {
    //   switch (spawnPoint.class_) {
    //     case 'Player':
    //       final playerPosition = Vector2(
    //         spawnPoint.x,
    //         spawnPoint.y,
    //       );
    //       player.position = playerPosition;
    //       add(player);
    //       break;
    //     default:
    //   }
    // }

    return super.onLoad();
  }

  void _loadBackground() {
    final skyTile = SkyTile();
    add(skyTile);
  }

  void _spawningObjects() {
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('SpawnPoints');
    if (spawnPointsLayer != null) {
      for (final spawnPoint in spawnPointsLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            player.scale.x = 1;
            add(player);
            break;
          // case 'Fruit':
          //   final fruit = Fruit(
          //     fruit: spawnPoint.name,
          //     position: Vector2(spawnPoint.x, spawnPoint.y),
          //     size: Vector2(spawnPoint.width, spawnPoint.height),
          //   );
          //   add(fruit);
          //   break;
          // case 'Saw':
          //   final isVertical = spawnPoint.properties.getValue('isVertical');
          //   final offNeg = spawnPoint.properties.getValue('offNeg');
          //   final offPos = spawnPoint.properties.getValue('offPos');
          //   final saw = Saw(
          //     isVertical: isVertical,
          //     offNeg: offNeg,
          //     offPos: offPos,
          //     position: Vector2(spawnPoint.x, spawnPoint.y),
          //     size: Vector2(spawnPoint.width, spawnPoint.height),
          //   );
          //   add(saw);
          //   break;
          // case 'Checkpoint':
          //   final checkpoint = Checkpoint(
          //     position: Vector2(spawnPoint.x, spawnPoint.y),
          //     size: Vector2(spawnPoint.width, spawnPoint.height),
          //   );
          //   add(checkpoint);
          //   break;
          // case 'YellowMob':
          //   print(spawnPoint.properties);
          //   final offNeg = spawnPoint.properties.getValue('offNeg');
          //   final offPos = spawnPoint.properties.getValue('offPos');
          //   final yellowMob = YellowMob(
          //     position: Vector2(spawnPoint.x, spawnPoint.y),
          //     size: Vector2(spawnPoint.width, spawnPoint.height),
          //     offNeg: offNeg,
          //     offPos: offPos,
          //   );
          //   add(yellowMob);
          //   break;
          default:
        }
      }
    }
  }

  void _addCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');

    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Platform':
            final platform = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isPlatform: true,
            );
            collisionBlocks.add(platform);
            add(platform);
            break;
          case 'QuickSand':
            final quickSand = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isQuickSand: true,
            );
            collisionBlocks.add(quickSand);
            add(quickSand);
          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            collisionBlocks.add(block);
            add(block);
        }
      }
    }
    player.collisionBlocks = collisionBlocks;
  }
}

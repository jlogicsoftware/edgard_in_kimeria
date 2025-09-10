import 'package:edgard_in_kimeria/components/enemy/yellow_mob.dart';
import 'package:edgard_in_kimeria/components/environment/background_tile.dart';
import 'package:edgard_in_kimeria/components/enemy/bat.dart';
import 'package:edgard_in_kimeria/components/environment/checkpoint.dart';
import 'package:edgard_in_kimeria/components/items/bomb.dart';
import 'package:edgard_in_kimeria/components/items/collectable.dart';
import 'package:edgard_in_kimeria/components/environment/collision_block.dart';
import 'package:edgard_in_kimeria/components/player.dart';
import 'package:edgard_in_kimeria/components/effects/firefly.dart';
import 'package:edgard_in_kimeria/components/effects/rain.dart';
import 'package:edgard_in_kimeria/components/effects/fog_effect.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Level extends World with HasGameReference<EdgardInKimeria> {
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

    // Add fireflies for level 1 (forest)
    if (levelName == 'forest') {
      for (int i = 0; i < 24; i++) {
        add(Firefly(area: Vector2(level.size.x, level.size.y)));
      }
    }

    // Add rain for level 2 (forest-1)
    if (levelName == 'forest-1') {
      for (int i = 0; i < 48; i++) {
        add(RainDrop(area: Vector2(level.size.x, level.size.y)));
      }
    }

    add(FogEffect());
    return super.onLoad();
  }

  void _loadBackground() {
    final skyTile = SkyTile();
    game.camera.backdrop = skyTile;
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
          case 'Collectable':
            final collectable = Collectable(
              collectableName: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(collectable);
            break;
          case 'Bat':
            final isVertical = spawnPoint.properties.getValue('isVertical');
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final bat = Bat(
              isVertical: isVertical,
              offNeg: offNeg,
              offPos: offPos,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(bat);
            break;
          case 'Checkpoint':
            final checkpoint = Checkpoint(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(checkpoint);
            break;
          case 'YellowMob':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final yellowMob = YellowMob(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg,
              offPos: offPos,
            );
            add(yellowMob);
            break;
          case 'Bomb':
            final bomb = Bomb(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(bomb);
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
          case 'Wall':
            final wall = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isWall: true,
            );
            collisionBlocks.add(wall);
            add(wall);
            break;
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

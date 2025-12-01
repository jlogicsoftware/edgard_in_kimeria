import 'package:edgard_in_kimeria/components/actor.dart';
import 'package:edgard_in_kimeria/components/mixins/gravity_mixin.dart';
import 'package:edgard_in_kimeria/components/player.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum State { idle, run, hit }

class Enemy extends Actor
    with HasGameReference<EdgardInKimeria>, CollisionCallbacks, GravityMixin {
  Enemy({
    required this.spriteName,
    required Vector2 position,
    Vector2? size,
    this.offNeg = 0,
    this.offPos = 0,
    this.stepTime = 0.05,
  }) : super(
          position: position,
          size: size ?? Vector2.all(16),
          anchor: Anchor.topLeft,
        );

  final String spriteName;
  final double offNeg;
  final double offPos;
  double stepTime;

  static const kStepTime = 0.05;
  static const tileSize = 16;

  @override
  Vector2 velocity = Vector2.zero();
  @override
  bool isOnGround = false;
  double rangeNeg = 0;
  double rangePos = 0;
  double moveDirection = 0;

  late final Player player;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation hitAnimation;

  @override
  void update(double dt) {
    if (!game.isGameStarted) return;

    updateEnemy(dt);
    super.update(dt);
  }

  void updateEnemy(double dt) {}

  SpriteAnimation spriteAnimation(String state, int amount, stepTime,
      Vector2 textureSize, Vector2 texturePosition) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('enemy/$spriteName.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
        texturePosition: texturePosition,
      ),
    );
  }

  void collidedWithPlayer({bool gotHit = false}) async {
    if (gotHit ||
        (player.velocity.y > 0 && player.y + player.height > position.y)) {
      if (game.playSounds) {
        game.bouncePool.start(volume: game.soundVolume);
      }
      current = State.hit;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }
}

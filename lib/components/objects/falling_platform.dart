import 'package:edgard_in_kimeria/components/effects/torch.dart';
import 'package:edgard_in_kimeria/components/environment/collidable.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

enum FallingPlatformState { idle, falling }

class FallingPlatform extends SpriteAnimationGroupComponent
    with HasGameReference<EdgardInKimeria>, CollisionCallbacks
    implements Collidable {
  FallingPlatform({
    Vector2? position,
    Vector2? size,
  }) : super(
          position: position ?? Vector2.zero(),
          size: size ?? Vector2(32, 16),
          anchor: Anchor.topLeft,
        );

  @override
  bool isActive = true;
  @override
  bool isPlatform = true;
  @override
  bool isQuickSand = false;
  @override
  bool isWall = false;
  @override
  bool isEscalator = false;

  // static double stepTime = 0.1;
  bool isFalling = false;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _fallingAnimation;
  late final Torch _torchEffect;

  @override
  Future<void> onLoad() async {
    debugMode = true;
    priority = 1;

    _idleAnimation = _loadSprite(stepTime: 0.1);
    _fallingAnimation = _loadSprite(stepTime: 0.3);
    animations = {
      FallingPlatformState.idle: _idleAnimation,
      FallingPlatformState.falling: _fallingAnimation,
    };
    current = FallingPlatformState.idle;

    return super.onLoad();
  }

  SpriteAnimation _loadSprite({required double stepTime}) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('objects/FallingOn.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: stepTime,
        textureSize: Vector2(32, 16),
        texturePosition: Vector2(0, 0),
      ),
    );
  }

  void collideWithActor() {
    if (!isFalling) {
      triggerFall();
    }
  }

  /// Initiates the falling sequence of the platform
  void triggerFall() {
    if (!isFalling) {
      isFalling = true;
      current = FallingPlatformState.falling;

      // Apply torch effect to the game scene
      _torchEffect = Torch(
        position: position + size,
        size: size,
        intensity: 5,
      );
      parent?.add(_torchEffect); // Add to the game scene

      // After 1 second, trigger fall and turn off the torch effect
      Future.delayed(const Duration(seconds: 1), () {
        _torchEffect.toggleFire(false);
        _startFalling();
      });
    }
  }

  void _startFalling() {
    print('FallingPlatform is now falling.');
    final fallEffect = MoveByEffect(
      Vector2(0, 200),
      EffectController(duration: 1.5),
      onComplete: () {
        removeFromParent();
        _torchEffect.removeFromParent();
      },
    );
    add(fallEffect);
  }
}

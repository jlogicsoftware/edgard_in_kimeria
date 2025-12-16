import 'package:edgard_in_kimeria/components/actor.dart';
import 'package:edgard_in_kimeria/components/environment/collision_block.dart';
import 'package:edgard_in_kimeria/components/items/trigger.dart';
import 'package:edgard_in_kimeria/components/mixins/gravity_mixin.dart';
import 'package:edgard_in_kimeria/components/objects/escalator.dart';
import 'package:edgard_in_kimeria/components/objects/falling_platform.dart';
import 'package:edgard_in_kimeria/levels/level.dart';
import 'package:edgard_in_kimeria/utils/utils.dart';

/// Mixin for collision detection with collision blocks and escalators.
/// It is used by actors to detect collisions with collision blocks and escalators.
/// Applies to actors gravity, clambers, wall jumps, and quicksand.
mixin CollideMixin on GravityMixin, Actor {
  List<Escalator> get escalators => (parent as Level).escalators;
  List<CollisionBlock> get collisionBlocks => (parent as Level).collisionBlocks;
  List<Trigger> get triggers => (parent as Level).triggers;
  List<FallingPlatform> get fallingPlatforms =>
      (parent as Level).fallingPlatforms;

  Escalator? currentEscalator;

  bool isInQuickSand = false;
  bool isClambering = false;
  bool isWallJumping = false;

  /// Checking vertical collisions with collision blocks
  void checkHorizontalCollisions(Actor actor) {
    for (final block in collisionBlocks) {
      if (!block.isActive) continue;
      if (block.isQuickSand) {
        if (checkCollision(actor, block)) {
          isInQuickSand = true;
        } else {
          isInQuickSand = false;
        }
      } else if (block.isWall) {
        if (checkCollision(actor, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            if (!isOnGround) {
              isClambering = true;
            }
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            if (!isOnGround) {
              isClambering = true;
            }
            break;
          }
        } else {
          isClambering = false;
        }
      } else {
        if (checkCollision(actor, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  /// Checking vertical collisions
  void checkVerticalCollisions(Actor actor, double dt) {
    // Reset escalator tracking at the start of collision check
    currentEscalator = null;

    for (final block in collisionBlocks) {
      if (!block.isActive) continue;
      if (block.isPlatform) {
        if (checkCollision(actor, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else if (block.isQuickSand) {
        if (checkCollision(actor, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            isOnGround = true;
            break;
          }
          // Removed velocity.x *= 0.1; from here for consistency
        }
      } else {
        if (checkCollision(actor, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }

    // Check for escalator collisions
    for (final escalator in escalators) {
      if (!escalator.isActive) continue;
      if (checkCollision(this, escalator)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = escalator.y - hitbox.height - hitbox.offsetY;
          isOnGround = true;
          // Track that player is on this escalator
          currentEscalator = escalator;
          break;
        }
      }
    }

    // Check for falling platform collisions
    for (final platform in fallingPlatforms) {
      if (checkCollision(this, platform)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = platform.y - hitbox.height - hitbox.offsetY;
          isOnGround = true;
          if (!platform.isFalling) {
            platform.collideWithActor();
          }
          break;
        } else {
          collidedWithActor();
        }
      }
    }
  }
}

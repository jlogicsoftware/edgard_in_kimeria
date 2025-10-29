import 'dart:async';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class JumpButton extends SpriteComponent
    with HasGameReference<EdgardInKimeria>, TapCallbacks {
  JumpButton();

  final margin = 32;
  final buttonSize = 64;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/JumpButton.png'));
    position = Vector2(
      game.size.x - margin - buttonSize,
      game.size.y - margin - buttonSize,
    );
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.isJumping = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.isJumping = false;
    super.onTapUp(event);
  }
}

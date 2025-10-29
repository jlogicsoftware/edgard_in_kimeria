import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Hud extends PositionComponent with HasGameReference<EdgardInKimeria> {
  Hud() : super(priority: 10);

  late TextComponent _coinText;

  @override
  Future<void> onLoad() async {
    _coinText = TextComponent(
      text: '${game.coinsCollected}',
      position: Vector2(50, 12),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
        ),
      ),
    );
    add(_coinText);

    final imageFromCache = game.images.fromCache('Items.png');
    final coinSprite = Sprite(
      imageFromCache,
      srcPosition: Vector2(0, 0),
      srcSize: Vector2(16, 16),
    );
    final coinIcon = SpriteComponent(
      sprite: coinSprite,
      position: Vector2(10, 10),
      size: Vector2(32, 32),
      anchor: Anchor.topLeft,
    );
    add(coinIcon);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _coinText.text = '${game.coinsCollected}';
  }
}

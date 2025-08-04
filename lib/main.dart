import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  final game = EdgardInKimeria();
  game.onLoad();

  runApp(GameWidget(game: kDebugMode ? EdgardInKimeria() : game));
}

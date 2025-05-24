import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setLandscape();
  Flame.device.setOrientation(DeviceOrientation.landscapeRight);

  EdgardInKimeria game = EdgardInKimeria();
  game.onLoad();

  runApp(GameWidget(game: kDebugMode ? EdgardInKimeria() : game));
}

import 'package:flame/components.dart';

mixin Actionable on PositionComponent {
  String targetId = '';
  void performAction();
}

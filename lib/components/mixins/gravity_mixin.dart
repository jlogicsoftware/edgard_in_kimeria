import 'package:flame/components.dart';

/// A mixin that provides gravity functionality for walking actors.
///
/// This mixin can be applied to any PositionComponent that needs to be
/// affected by gravity. Classes using this mixin must have a `velocity`
/// Vector2 property and should call `applyGravity(dt)` in their update loop.
///
/// Example usage:
/// ```dart
/// class MyActor extends SpriteAnimationComponent with GravityMixin {
///   @override
///   double get gravityAcceleration => 12.0; // Custom gravity
///
///   @override
///   void update(double dt) {
///     applyGravity(dt);
///     position.y += velocity.y * dt;
///     super.update(dt);
///   }
/// }
/// ```
mixin GravityMixin on PositionComponent {
  /// The velocity vector for this component.
  /// Must be implemented by the class using this mixin.
  Vector2 get velocity;

  /// Whether the component is currently on the ground.
  /// This should be set by collision detection logic.
  bool get isOnGround;
  set isOnGround(bool value);

  /// The gravity acceleration value (pixels per frame squared).
  /// Override this getter to customize gravity for specific actors.
  /// Default value: 9.8
  double get gravityAcceleration => 9.8;

  /// The maximum falling velocity (terminal velocity).
  /// Override this getter to customize terminal velocity for specific actors.
  /// Default value: 300.0
  double get terminalVelocity => 300.0;

  /// The jump force applied when jumping.
  /// Override this getter to customize jump force for specific actors.
  /// Default value: 260.0
  double get jumpForce => 260.0;

  /// Applies gravity to the vertical velocity and updates position.
  ///
  /// This method should be called in the update loop of the component.
  /// It will:
  /// 1. Add gravity acceleration to vertical velocity
  /// 2. Clamp velocity to terminal velocity
  ///
  /// Note: This only updates velocity. Position should be updated separately
  /// and collision checks should happen after position update.
  ///
  /// [dt] - Delta time for the current frame
  void applyGravity(double dt) {
    velocity.y += gravityAcceleration;
    velocity.y = velocity.y.clamp(-jumpForce, terminalVelocity);
    position.y += velocity.y * dt;
  }

  /// Resets the vertical velocity to zero.
  /// Useful when landing on ground or hitting ceiling.
  void resetVerticalVelocity() {
    velocity.y = 0;
  }
}

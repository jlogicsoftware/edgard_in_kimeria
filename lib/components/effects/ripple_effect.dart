import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:edgard_in_kimeria/edgard_in_kimeria.dart';
import 'package:edgard_in_kimeria/components/effects/ripple_decorator.dart';

/// RippleEffect
/// Controls a ripple effect via the global RippleDecorator.
class RippleEffect extends Component with HasGameReference<EdgardInKimeria> {
  final Vector2 centerWorld;
  final double duration;
  final double maxRadius; // pixels
  final double strength; // pixels
  final double frequency;
  final double decay;

  late RippleData _data;
  double _elapsed = 0.0;

  RippleEffect({
    required this.centerWorld,
    this.duration = 1.0,
    this.maxRadius = 120.0,
    this.strength = 12.0,
    this.frequency = 60.0,
    this.decay = 30.0,
  });

  @override
  void onLoad() {
    // Convert world center to screen center?
    // Actually, the shader expects UV or screen coords.
    // The decorator applies to the viewport, so we need screen coordinates.
    // We can calculate screen coordinates in update() as the camera moves.

    // Initial data
    _data = RippleData(
      center: Vector2.zero(), // Updated in update
      screenSize: game.camera.viewport.size,
      maxRadius: maxRadius,
      strength: strength,
      frequency: frequency,
      decay: decay,
    );

    game.rippleDecorator?.addRipple(_data);
  }

  @override
  void onRemove() {
    game.rippleDecorator?.removeRipple(_data);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    final progress = (_elapsed / duration).clamp(0.0, 1.0);

    if (progress >= 1.0) {
      removeFromParent();
      return;
    }

    // Update data
    _data.progress = progress;

    // Calculate screen position of the ripple center
    // Manual conversion from World to Screen
    final camera = game.camera;
    final viewfinder = camera.viewfinder;

    // 1. World to Viewfinder (relative to camera position)
    final delta = centerWorld - viewfinder.position;

    // 2. Rotate (if camera rotates)
    // delta.rotate(-viewfinder.angle); // Optional if we have rotation

    // 3. Scale (Zoom)
    final scaled = delta * viewfinder.zoom;

    // 4. Viewfinder to Screen (Viewport)
    // Assuming viewport anchor is TopLeft (0,0) and position is (0,0)
    // If anchor is Center, we add half viewport size.
    // Viewfinder anchor determines where the camera position is on the screen.

    // Use logical resolution for viewport size in calculation
    final viewportSize = game.logicalResolution;

    final anchorOffset = Vector2(
      viewportSize.x * viewfinder.anchor.x,
      viewportSize.y * viewfinder.anchor.y,
    );

    final screenPosition = scaled + anchorOffset;

    // 5. Viewport to Canvas (Window)
    // FixedResolutionViewport scales and centers the content.
    final canvasSize = game.canvasSize;

    final scale = math.min(
      canvasSize.x / viewportSize.x,
      canvasSize.y / viewportSize.y,
    );

    final scaledViewportSize = viewportSize * scale;
    final offset = (canvasSize - scaledViewportSize) / 2;
    
    final canvasPosition = (screenPosition * scale) + offset;
    
    _data.center.setFrom(canvasPosition);
    
    // Fade out the ripple strength as it progresses
    _data.strength = strength * (1.0 - progress);
    
    // Update screen size in case of resize
    _data.screenSize.setFrom(canvasSize);
  }
}

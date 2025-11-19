import 'dart:math';
import 'package:edgard_in_kimeria/components/items/actionable.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Torch particle effect placed at a position. Creates a small continuous
/// flame flicker and occasional embers/smoke using short-lived particles
/// that are respawned to simulate a continuous effect.
class Torch extends PositionComponent with Actionable {
  final Random _rand = Random();
  late final CircleComponent _light;
  // Intensity controls glow size/alpha and, by default, the mid-sparkle burst.
  int intensity;
  // Number of mid-life sparkles emitted per burst. Default is `intensity`.
  final int midSparkleBurst;
  // Weighted live sparkle/ember sum (weights depend on particle distance).
  // Used to modulate glow smoothly.
  double _weightedSparkles = 0.0;
  // Stored base light parameters computed from intensity
  late double _baseRadius;
  late int _baseAlpha;
  // Current and target radius/alpha used for smoothing (lerp in update)
  double _currentRadius = 0.0;
  double _currentAlpha = 0.0;
  double _targetRadius = 0.0;
  double _targetAlpha = 0.0;

  // Flag to control whether new particles are scheduled
  bool _schedulersActive = true;

  Torch({
    Vector2? position,
    Vector2? size,
    this.intensity = 80,
    int? midSparkleBurst,
    String targetId = '',
  }) : midSparkleBurst = midSparkleBurst ?? intensity {
    if (position != null) this.position = position;
    if (size != null) this.size = size;
    this.targetId = targetId;
    anchor = Anchor.center;
  }

  @override
  void performAction() {
    toggleFire(intensity == 0);
  }

  @override
  Future<void> onLoad() async {
    // Ensure this torch renders above shader-based ripple effects (which
    // use priority = 0). Actors typically use priority = 1; use 2 to be
    // safely above ripple and other effects so the torch is not occluded.
    priority = 2;

    // Initialize _light immediately to avoid LateInitializationError
    _baseRadius = (4.0 + intensity * 0.06).clamp(3.0, 40.0).toDouble();
    _baseAlpha = ((18 + (intensity * 0.22)).round().clamp(8, 220)).toInt();

    _light = CircleComponent(
      radius: _baseRadius,
      paint: Paint()..color = Colors.yellow.withAlpha(_baseAlpha),
      anchor: Anchor.center,
    );
    add(_light);

    if (intensity > 0) {
      // Start a few continuous spawners for core flame, embers and smoke.
      _setupLight();
      _scheduleCore();
      _scheduleEmber();
      _scheduleMidSparkle();
      _scheduleSmoke();
    }

    return super.onLoad();
  }

  void toggleFire(bool isOn) {
    if (isOn) {
      intensity = 200;
      _light.paint = Paint()
        ..color = Colors.yellow.withAlpha(_baseAlpha)
        ..blendMode = BlendMode.plus;

      // Restart schedulers
      _schedulersActive = true;
      _setupLight();
      _scheduleCore();
      _scheduleEmber();
      _scheduleMidSparkle();
      _scheduleSmoke();
    } else {
      intensity = 0;
      _light.paint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.plus;

      // Stop all schedulers
      _schedulersActive = false;

      // Allow existing particles to burn down naturally
      Future.delayed(Duration(seconds: 2), () {
        removeWhere(
            (child) => child != _light); // Remove all remaining particles
      });
    }
  }

  // Mid-life sparkle: emit a configurable burst of many small green sparks.
  void _spawnMidSparkle() {
    // Burst count scales from the configured midSparkleBurst, with slight
    // random variance (+/-20%). Keep a sensible lower bound.
    final burstCount = (midSparkleBurst * (0.8 + _rand.nextDouble() * 0.4))
        .round()
        .clamp(10, 300);

    for (int i = 0; i < burstCount; i++) {
      final lifespan = 400 + _rand.nextInt(800); // 0.4 - 1.2s
      final life = lifespan / 1000.0;

      final start = Vector2(
        (_rand.nextDouble() - 0.5) * 10.0,
        (_rand.nextDouble() - 0.5) * 8.0,
      );
      final end = start +
          Vector2((_rand.nextDouble() - 0.5) * 18.0,
              -30.0 - _rand.nextDouble() * 60.0);

      final sparkle = ParticleSystemComponent(
        particle: MovingParticle(
          from: start,
          to: end,
          child: ComputedParticle(
            lifespan: life,
            renderer: (canvas, particle) {
              final t = particle.progress;
              final pos = Offset.zero;
              // smaller size for dense bursts
              final size =
                  0.6 + 1.2 * (1 - t) * (0.6 + _rand.nextDouble() * 1.0);
              final color = Color.lerp(
                  Colors.lime, Colors.greenAccent, _rand.nextDouble())!;
              final paint = Paint()
                ..color = color.withAlpha((180 * (1 - t)).toInt())
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0)
                ..blendMode = BlendMode.plus;
              canvas.drawCircle(pos, size, paint);
            },
          ),
        ),
        position: Vector2.zero(),
        anchor: Anchor.center,
      );

      add(sparkle);
      // weight contribution based on distance from center (closer sparks matter more)
      final distance = start.length; // start is already a small offset vector
      const maxRange = 30.0;
      final normalizedDist = (1.0 - (distance / maxRange)).clamp(0.0, 1.0);
      final weight = normalizedDist * normalizedDist; // quadratic falloff
      _incrementLiveSparkles(weight);
      Future.delayed(Duration(milliseconds: lifespan), () {
        _decrementLiveSparkles(weight);
        sparkle.removeFromParent();
      });
    }

    // schedule next mid-sparkle burst (more frequent now)
    if (isMounted) _scheduleMidSparkle();
  }

  void _scheduleMidSparkle() {
    if (!_schedulersActive) return; // Prevent scheduling if stopped
    final delay = 80 + _rand.nextInt(180); // ~0.08-0.26s between bursts
    Future.delayed(Duration(milliseconds: delay), () {
      if (isMounted && _schedulersActive) _spawnMidSparkle();
    });
  }

  void _setupLight() {
    // Flicker loop
    void flicker() {
      if (!isMounted) return;
      // Slightly vary the radius and alpha around the base values to flicker.
      final normalized =
          (_weightedSparkles / (_baseIntensityForNormalization()))
              .clamp(0.0, 2.0);
      final intensityScale = 1.0 + (normalized * 0.5);
      final targetRadius =
          _baseRadius * (0.75 + _rand.nextDouble() * 0.6) * intensityScale;
      final targetAlpha =
          (_baseAlpha * (0.55 + _rand.nextDouble() * 0.6) * intensityScale)
              .round();
      // animate over a short random duration by scheduling small steps
      final steps = 3 + _rand.nextInt(4);
      for (int i = 0; i < steps; i++) {
        Future.delayed(Duration(milliseconds: 40 * i), () {
          if (!isMounted) return;
          final stepRadius = targetRadius * (0.88 + _rand.nextDouble() * 0.28);
          final stepAlpha =
              (targetAlpha * (1 - i / steps)).toInt().clamp(0, 255);
          _updateLightPaint(stepRadius, stepAlpha);
        });
      }
      // schedule next flicker
      Future.delayed(Duration(milliseconds: 120 + _rand.nextInt(220)), () {
        flicker();
      });
    }

    flicker();
  }

  // Core flickering flame: short-lived bright particles drawn as soft,
  // layered circles (yellow -> orange -> red) with a blur.
  void _spawnCore() {
    // Slightly longer core life for smoother glow, and larger base size
    final lifespan = 140 + _rand.nextInt(180); // ms
    final life = lifespan / 1000.0;

    // Render vertical ovals to create a narrow plume. Shift upward as it
    // progresses to emulate rising flame.
    final particle = ParticleSystemComponent(
      particle: ComputedParticle(
        lifespan: life,
        renderer: (canvas, particle) {
          final t = particle.progress; // 0..1
          final flick = 0.9 + _rand.nextDouble() * 0.4;
          // upward drift for the core shape
          final yOffset = -12.0 * t;
          // base size controls width; height will be larger for vertical plume
          final base = 6.0 * (1.0 - t) * flick;

          // outer soft green glow
          final outer = Paint()
            ..color = Color.lerp(Colors.green[900], Colors.greenAccent, 0.35)!
                .withAlpha((50 * (1 - t)).toInt())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0)
            ..blendMode = BlendMode.plus;
          final outerRect = Rect.fromCenter(
              center: Offset(0, yOffset),
              width: base * 1.6,
              height: base * 3.0);
          canvas.drawOval(outerRect, outer);

          // mid layer (brighter green)
          final mid = Paint()
            ..color = Color.lerp(Colors.green[500], Colors.lime, 0.4)!
                .withAlpha((200 * (1 - t)).toInt())
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0);
          final midRect = Rect.fromCenter(
              center: Offset(0, yOffset + 2),
              width: base * 1.0,
              height: base * 2.2);
          canvas.drawOval(midRect, mid);

          // bright tip/core (small)
          final core = Paint()
            ..color = Color.lerp(Colors.yellow, Colors.greenAccent, 0.6)!
                .withAlpha((255 * (1 - t)).toInt());
          final coreRect = Rect.fromCenter(
              center: Offset(0, yOffset + 4),
              width: base * 0.5,
              height: base * 1.0);
          canvas.drawOval(coreRect, core);
        },
      ),
      position: Vector2.zero(),
      anchor: Anchor.center,
    );

    add(particle);

    // Remove after life and schedule next spawn
    Future.delayed(Duration(milliseconds: lifespan), () {
      particle.removeFromParent();
      if (isMounted) _scheduleCore();
    });
  }

  void _scheduleCore() {
    if (!_schedulersActive) return; // Prevent scheduling if stopped
    final delay = 40 + _rand.nextInt(120); // ms
    Future.delayed(Duration(milliseconds: delay), () {
      if (isMounted && _schedulersActive) _spawnCore();
    });
  }

  // Ember particles: small sparks that rise upward and fade.
  void _spawnEmber() {
    // more frequent embers, smaller, with gentle upward motion
    final lifespan = 350 + _rand.nextInt(450); // ms
    final life = lifespan / 1000.0;

    // start slightly above the base of the torch
    final start = Vector2(
      0 + (_rand.nextDouble() - 0.5) * 6.0,
      0 + (_rand.nextDouble() - 0.2) * 4.0,
    );

    // spawn a moderate burst of embers for sparkle
    final burst = 3 + _rand.nextInt(5); // 3-7
    for (int i = 0; i < burst; i++) {
      final sStart = start +
          Vector2(
            (_rand.nextDouble() - 0.5) * 8.0,
            (_rand.nextDouble() - 0.5) * 6.0,
          );
      final sEnd = sStart +
          Vector2(
            (_rand.nextDouble() - 0.5) * 28.0,
            -40.0 - _rand.nextDouble() * 30.0,
          );
      final isPop = _rand.nextDouble() < 0.14; // occasional bright pop

      final ember = ParticleSystemComponent(
        particle: MovingParticle(
          from: sStart,
          to: sEnd,
          child: ComputedParticle(
            lifespan: life,
            renderer: (canvas, particle) {
              final t = particle.progress; // 0..1
              final size = (isPop ? 1.2 : 0.6) + 1.0 * (1.0 - t);
              final pos = Offset.zero;
              // ember color: lime/green sparks
              final base = Color.lerp(
                  Colors.limeAccent, Colors.greenAccent, _rand.nextDouble())!;
              final color = isPop ? Color.lerp(base, Colors.white, 0.7)! : base;
              final paint = Paint()
                ..color = color.withAlpha((240 * (1 - t)).toInt())
                ..blendMode = BlendMode.plus;
              canvas.drawCircle(pos, size, paint);
            },
          ),
        ),
        position: Vector2.zero(),
        anchor: Anchor.center,
      );
      add(ember);
      // small weight contribution for embers (they're less impactful)
      final emberDistance = sStart.length;
      const emberMax = 28.0;
      final emberNorm = (1.0 - (emberDistance / emberMax)).clamp(0.0, 1.0);
      final emberWeight = 0.25 * emberNorm * emberNorm; // smaller influence
      _incrementLiveSparkles(emberWeight);
      Future.delayed(Duration(milliseconds: lifespan), () {
        _decrementLiveSparkles(emberWeight);
        ember.removeFromParent();
      });
    }

    // schedule next spawn
    Future.delayed(Duration(milliseconds: lifespan), () {
      if (isMounted) _scheduleEmber();
    });
  }

  void _scheduleEmber() {
    if (!_schedulersActive) return; // Prevent scheduling if stopped
    // spawn occasional embers - random interval
    final delay = 20 + _rand.nextInt(120); // ms - much more frequent
    Future.delayed(Duration(milliseconds: delay), () {
      if (isMounted && _schedulersActive) _spawnEmber();
    });
  }

  // Smoke: soft gray particles that slowly rise and fade
  void _spawnSmoke() {
    // Replace with long-lived grey smoke for visible column
    final lifespan = 2000 + _rand.nextInt(2000); // 2-4s
    final life = lifespan / 1000.0;

    final start = Vector2(
        0 + (_rand.nextDouble() - 0.5) * 6.0, -2.0 + _rand.nextDouble() * 3.0);
    final end = start +
        Vector2((_rand.nextDouble() - 0.5) * 8.0,
            -50.0 - _rand.nextDouble() * 40.0);

    final smoke = ParticleSystemComponent(
      particle: MovingParticle(
        from: start,
        to: end,
        child: ComputedParticle(
          lifespan: life,
          renderer: (canvas, particle) {
            final t = particle.progress;
            // visibly grey smoke: larger, long-lived, rising slowly
            final size = 10.0 * t + 10.0; // larger expansion
            final alpha = (200 * (1 - t)).toInt();
            final baseColor = Color.lerp(Colors.grey[600], Colors.black, 0.1)!;
            final paint = Paint()
              ..color = baseColor.withAlpha(alpha)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0)
              ..blendMode = BlendMode.srcOver;
            final rect = Rect.fromCenter(
                center: Offset(0, -6.0 * t),
                width: size * 1.2,
                height: size * 3.6);
            canvas.drawOval(rect, paint);
          },
        ),
      ),
      position: Vector2.zero(),
      anchor: Anchor.center,
    );

    add(smoke);
    Future.delayed(Duration(milliseconds: lifespan), () {
      smoke.removeFromParent();
      if (isMounted) _scheduleSmoke();
    });
  }

  void _scheduleSmoke() {
    if (!_schedulersActive) return; // Prevent scheduling if stopped
    // make smoke more frequent to be visible
    final delay = 220 + _rand.nextInt(500);
    Future.delayed(Duration(milliseconds: delay), () {
      if (isMounted && _schedulersActive) _spawnSmoke();
    });
  }

  // Helper to compute normalization denominator for live sparkles.
  double _baseIntensityForNormalization() {
    // Use the configured midSparkleBurst as a baseline; ensure non-zero.
    return (midSparkleBurst.clamp(10, 300)).toDouble();
  }

  // Weighted increment/decrement for live sparkles
  void _incrementLiveSparkles(double weight) {
    _weightedSparkles += weight;
    _updateTargetsFromWeighted();
  }

  void _decrementLiveSparkles(double weight) {
    _weightedSparkles =
        (_weightedSparkles - weight).clamp(0.0, double.infinity);
    _updateTargetsFromWeighted();
  }

  void _updateTargetsFromWeighted() {
    if (!isMounted) return;
    final baseline = _baseIntensityForNormalization();
    final normalized = (_weightedSparkles / baseline).clamp(0.0, 2.0);
    final intensityScale = 1.0 + (normalized * 0.5);
    _targetRadius = _baseRadius * intensityScale;
    _targetAlpha =
        (_baseAlpha * intensityScale).round().toDouble().clamp(0.0, 255.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // If intensity is less than or equal to 0, skip sparkling updates
    if (intensity <= 0) {
      _light.paint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.plus;
      return;
    }

    // Smooth current values toward targets (lerp). Smoothing factor tuned for gentle pulses.
    const smoothing = 8.0; // higher = faster
    final t = (1.0 - pow(0.5, dt * smoothing)).toDouble();
    _currentRadius = _lerp(
        _currentRadius == 0.0 ? _baseRadius : _currentRadius, _targetRadius, t);
    _currentAlpha = _lerp(
        _currentAlpha == 0.0 ? _baseAlpha.toDouble() : _currentAlpha,
        _targetAlpha,
        t);
    _updateLightPaint(_currentRadius, _currentAlpha.round());
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _updateLightPaint(double radius, int alpha) {
    // Simpler approach: colored circle with a blurred mask filter.
    // This avoids shader centering issues and looks consistent when
    // composited with BlendMode.plus.
    _light.radius = radius.clamp(2.0, 80.0);
    final blur = (radius * 0.6).clamp(2.0, 48.0);
    _light.paint = Paint()
      ..color = Colors.greenAccent.withAlpha(alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
      ..blendMode = BlendMode.plus;
  }
}

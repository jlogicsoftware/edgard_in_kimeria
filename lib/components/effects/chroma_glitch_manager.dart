import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:edgard_in_kimeria/components/effects/chroma_glitch_post_process.dart';

class ChromaGlitchManager extends Component {
  ChromaGlitchManager({
    required this.camera,
    this.shaderPath = 'shaders/chroma_glitch.frag',
    this.minInterval = 1.0,
    this.maxInterval = 3.0,
    this.minDuration = 0.2,
    this.maxDuration = 0.5,
    this.initialShiftIntensity = 0.002,
    this.maxShiftIntensity = 0.010,
    this.poisonProgressionRate =
        0.0005, // How fast the poison progresses per second
    this.maxPoisonDuration = 2.0, // Maximum duration when fully poisoned
  });

  final CameraComponent camera;
  final String shaderPath;

  // Timing configuration
  final double minInterval;
  final double maxInterval;
  final double minDuration;
  final double maxDuration;

  // Poison progression configuration
  final double initialShiftIntensity;
  final double maxShiftIntensity;
  final double poisonProgressionRate;
  final double maxPoisonDuration; // Maximum duration when fully poisoned

  // State variables
  double _time = 0.0;
  double _nextTriggerTime = 0.0;
  double _effectEndTime = 0.0;
  bool _isEffectActive = false;
  final Random _random = Random();

  // Current poison level (intensity increases over time)
  double _currentShiftIntensity = 0.0;

  // Fragment program loaded asynchronously
  FragmentProgram? _fragmentProgram;
  bool _isShaderLoaded = false;

  ChromaGlitchPostProcess? _postProcess;

  @override
  void onMount() {
    super.onMount();
    // Initialize current shift intensity
    _currentShiftIntensity = initialShiftIntensity;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Load the fragment shader
    try {
      _fragmentProgram = await FragmentProgram.fromAsset(shaderPath);
      _isShaderLoaded = true;
    } catch (e) {
      print(
          'Warning: Could not load chroma glitch shader from $shaderPath: $e');
      _isShaderLoaded = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Progressively increase the poison effect over time
    _currentShiftIntensity =
        (_currentShiftIntensity + poisonProgressionRate * dt)
            .clamp(initialShiftIntensity, maxShiftIntensity);

    // Update current post-process intensity if active
    if (_postProcess != null) {
      _postProcess!.shiftIntensity = _currentShiftIntensity;
    }

    // Check if we should start a new effect (only if shader is loaded)
    if (!_isEffectActive && _time >= _nextTriggerTime && _isShaderLoaded) {
      _startEffect();
    }

    // Check if current effect should end
    if (_isEffectActive && _time >= _effectEndTime) {
      _endEffect();
    }
  }

  void _startEffect() {
    // Don't start effect if shader isn't loaded
    if (!_isShaderLoaded || _fragmentProgram == null) {
      return;
    }

    _isEffectActive = true;

    // Calculate progressive duration based on poison level
    final currentPoisonLevel = poisonLevel;

    // Interpolate between initial duration range and max poison duration
    final baseDuration =
        minDuration + _random.nextDouble() * (maxDuration - minDuration);
    final poisonDurationBonus =
        (maxPoisonDuration - maxDuration) * currentPoisonLevel;
    final duration = baseDuration + poisonDurationBonus;

    _effectEndTime = _time + duration;

    // Add post-processing to camera with current poison intensity
    _postProcess = ChromaGlitchPostProcess(
      fragmentProgram: _fragmentProgram!,
      shiftIntensity: _currentShiftIntensity,
    );
    camera.postProcess = _postProcess;
  }

  void _endEffect() {
    _isEffectActive = false;

    // Remove post-processing from camera
    camera.postProcess = null;
    _postProcess = null;

    // Schedule next effect
    final interval =
        minInterval + _random.nextDouble() * (maxInterval - minInterval);
    _nextTriggerTime = _time + interval;
  }

  /// Get the current poison level as a percentage (0.0 to 1.0)
  double get poisonLevel {
    return (_currentShiftIntensity - initialShiftIntensity) /
        (maxShiftIntensity - initialShiftIntensity);
  }

  /// Get the current shift intensity value
  double get currentShiftIntensity => _currentShiftIntensity;

  /// Get the current maximum possible duration for glitch effects
  double get currentMaxDuration {
    final currentPoisonLevel = poisonLevel;
    return maxDuration + (maxPoisonDuration - maxDuration) * currentPoisonLevel;
  }

  @override
  void onRemove() {
    // Clean up when component is removed
    if (_postProcess != null) {
      camera.postProcess = null;
      _postProcess = null;
    }
    super.onRemove();
  }
}

// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Animated Lamp',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0C0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD08A),
          surface: Color(0xFF0F1116),
        ),
        useMaterial3: true,
      ),
      home: const LampScreen(),
    );
  }
}

/// A minimal, premium-looking lamp scene.
///
/// Interaction:
/// - Tap the pull handle to toggle.
/// - Drag down on the pull handle; releasing past a threshold toggles.
///
/// Animation:
/// - The lamp glow ramps smoothly with a curved controller.
/// - The pull string has a short, physical-ish pull + return.
class LampScreen extends StatefulWidget {
  const LampScreen({super.key});

  @override
  State<LampScreen> createState() => _LampScreenState();
}

class _LampScreenState extends State<LampScreen> with TickerProviderStateMixin {
  static const _toggleThreshold = 0.55;
  static const _maxPullPx = 180.0;

  bool _isOn = false;
  double _pullPx = 0;

  late final AnimationController _glowController;
  late final Animation<double> _glow;

  // A very subtle brightness modulation that runs only while the lamp is ON.
  // This is intentionally minimal so it feels premium, not “glitchy”.
  late final AnimationController _flickerController;

  // A short-lived “string wave” animation that decays after pulls/releases.
  late final AnimationController _waveController;
  double _waveStrength = 0;

  late final AnimationController _pullController;
  late final Animation<double> _pullReturn;

  // Micro vibration when toggling (adds physicality).
  late final AnimationController _kickController;

  // Slow ambient motion for premium feel (background drift + dust particles).
  late final AnimationController _ambientController;
  late final List<_DustParticle> _dust;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _glow = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _pullReturn = CurvedAnimation(
      parent: _pullController,
      curve: Curves.easeOutBack,
    );

    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _kickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    final rng = math.Random(7);
    _dust = List.generate(
      26,
      (i) => _DustParticle(
        seed: rng.nextDouble(),
        x: rng.nextDouble() * 2 - 1, // -1..1
        y: rng.nextDouble(), // 0..1
        size: lerpDouble(0.6, 2.0, rng.nextDouble()) ?? 1.2,
        speed: lerpDouble(0.10, 0.32, rng.nextDouble()) ?? 0.2,
        twinkle: lerpDouble(0.6, 1.0, rng.nextDouble()) ?? 0.8,
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pullController.dispose();
    _flickerController.dispose();
    _waveController.dispose();
    _ambientController.dispose();
    _kickController.dispose();
    super.dispose();
  }

  double get _flickerFactor {
    // Only apply while ON and while glow is non-zero.
    if (!_isOn) return 1.0;
    final t = _flickerController.value;

    // Two sine layers to avoid a perfectly periodic “metronome” feel.
    final a = math.sin((t * math.pi * 2) * 1.0 + 0.3);
    final b = math.sin((t * math.pi * 2) * 2.7 + 1.2);
    final mix = (a * 0.65 + b * 0.35);

    // Keep amplitude tiny.
    return 1.0 + (mix * 0.018);
  }

  double get _pullT => (_pullPx / _maxPullPx).clamp(0.0, 1.0);

  // Gentle sway reads nicely on camera (very low amplitude).
  double _swayAngle(double ambientT) {
    final base = math.sin(ambientT * math.pi * 2) * 0.012;
    final pull = _pullT * 0.030;
    final wave =
        math.sin(_waveController.value * math.pi * 2 * 2.2) *
        (0.010 * _waveStrength);
    return base + pull + wave;
  }

  double _swayOffsetX(double ambientT) {
    final base = math.sin((ambientT * math.pi * 2) + 1.6) * 6.0;
    final pull = _pullT * 7.5;
    return base + pull;
  }

  void _kickWave({required double strength}) {
    _waveStrength = strength.clamp(0.0, 1.0);
    if (_waveStrength <= 0.001) return;

    // Restart a decaying wave so quick pulls look “alive”.
    _waveController.forward(from: 0.0);
  }

  Future<void> _setLampOn(bool on) async {
    if (_isOn == on) return;
    setState(() => _isOn = on);

    // Tiny vibration cue (reads well in screen recordings).
    _kickController.forward(from: 0.0);

    if (on) {
      if (!_flickerController.isAnimating) {
        _flickerController.repeat();
      }
      await _glowController.forward();
    } else {
      await _glowController.reverse();
      _flickerController.stop();
      _flickerController.value = 0.0;
    }
  }

  Future<void> _toggleLamp() => _setLampOn(!_isOn);

  Future<void> _tapPull() async {
    // A tiny staged pull so it reads on camera.
    _kickWave(strength: 0.85);
    await _animatePullTo(_maxPullPx * 0.62);
    await _toggleLamp();
    _kickWave(strength: 0.95);
    await _animatePullTo(0);
  }

  Future<void> _animatePullTo(double targetPx) async {
    // Drive a short return animation from the current _pullPx to targetPx.
    final startPx = _pullPx;
    _pullController.stop();
    _pullController.reset();

    void listener() {
      final t = _pullReturn.value;
      setState(() {
        _pullPx = lerpDouble(startPx, targetPx, t) ?? targetPx;
      });
    }

    _pullController.addListener(listener);
    await _pullController.forward();
    _pullController.removeListener(listener);
  }

  void _onPullDragUpdate(DragUpdateDetails details) {
    setState(() {
      _pullPx = (_pullPx + details.delta.dy).clamp(0, _maxPullPx);
    });

    final normalized = (_pullPx / _maxPullPx).clamp(0.0, 1.0);
    // Only kick if there's meaningful motion.
    if (details.delta.dy.abs() > 0.6) {
      _kickWave(strength: normalized);
    }
  }

  Future<void> _onPullDragEnd(DragEndDetails details) async {
    final normalized = (_pullPx / _maxPullPx).clamp(0.0, 1.0);
    final shouldToggle = normalized >= _toggleThreshold;
    if (shouldToggle) {
      await _toggleLamp();
    }
    _kickWave(strength: math.max(0.35, normalized));
    await _animatePullTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final lampWidth = (w * 0.72).clamp(300.0, 460.0);
            final lampHeight = lampWidth / 1.1;
            final lampTop = 56.0;
            final lampCenter = Offset(
              w / 2,
              lampTop + (lampHeight * 0.60) + 18,
            );
            final stringTop = lampTop + (lampHeight * 0.60) - 6;

            final ambientT = _ambientController.value;

            return Stack(
              children: [
                AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return _BackgroundVignette(drift: ambientT);
                  },
                ),

                // Glow lives behind the lamp and ramps with [_glow].
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _glowController,
                        _flickerController,
                      ]),
                      builder: (context, _) {
                        final intensity = (_glow.value * _flickerFactor).clamp(
                          0.0,
                          1.0,
                        );
                        return GlowEffect(
                          intensity: intensity,
                          anchor: lampCenter,
                        );
                      },
                    ),
                  ),
                ),

                // Cinematic dust particles drifting through the beam.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _ambientController,
                        _glowController,
                        _flickerController,
                      ]),
                      builder: (context, _) {
                        final intensity = (_glow.value * _flickerFactor).clamp(
                          0.0,
                          1.0,
                        );
                        if (intensity <= 0.10) return const SizedBox.expand();
                        return ClipPath(
                          clipper: _BeamClipper(
                            anchor: lampCenter,
                            intensity: intensity,
                          ),
                          child: CustomPaint(
                            painter: _DustPainter(
                              anchor: lampCenter,
                              intensity: intensity,
                              t: ambientT,
                              particles: _dust,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Floor caustics (subtle shimmering patch under the beam).
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _ambientController,
                        _glowController,
                        _flickerController,
                      ]),
                      builder: (context, _) {
                        final intensity = (_glow.value * _flickerFactor).clamp(
                          0.0,
                          1.0,
                        );
                        if (intensity <= 0.18) return const SizedBox.expand();

                        return CustomPaint(
                          painter: _CausticsPainter(
                            anchor: lampCenter,
                            intensity: intensity,
                            t: _ambientController.value,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                ),

                // A subtle watermark projected in the light beam.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _glowController,
                        _flickerController,
                      ]),
                      builder: (context, _) {
                        final intensity = (_glow.value * _flickerFactor).clamp(
                          0.0,
                          1.0,
                        );
                        if (intensity <= 0.2) return const SizedBox.expand();

                        final coneTop = lampCenter + const Offset(0, 36);
                        final coneHeight =
                            lerpDouble(220, 420, intensity) ?? 320;
                        final watermarkY =
                            coneTop.dy + (coneHeight * 0.42); // mid-beam

                        final opacity =
                            ((intensity - 0.2) / 0.8).clamp(0.0, 1.0) * 0.32;

                        return Opacity(
                          opacity: opacity,
                          child: ClipPath(
                            clipper: _BeamClipper(
                              anchor: lampCenter,
                              intensity: intensity,
                            ),
                            child: SizedBox.expand(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Transform.translate(
                                      offset: Offset(0, watermarkY),
                                      child: Transform.rotate(
                                        angle: -0.10,
                                        child: Text(
                                          'rayonix solution',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFFFFF2DB,
                                            ).withOpacity(0.70),
                                            fontSize: 20,
                                            letterSpacing: 1.4,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.45,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Lamp + string group.
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: w,
                    height: constraints.maxHeight,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _ambientController,
                        _waveController,
                        _kickController,
                      ]),
                      builder: (context, _) {
                        final angle = _swayAngle(ambientT);
                        final dx = _swayOffsetX(ambientT);

                        // 0..1 kick. Use a half-sine for a quick impulse.
                        final k = math.sin(_kickController.value * math.pi);
                        final kickX = k * 2.8;
                        final kickY = k * 1.2;
                        final kickRot = k * 0.010;

                        return Transform.translate(
                          offset: Offset(dx + kickX, kickY),
                          child: Transform.rotate(
                            angle: angle + kickRot,
                            origin: Offset(w / 2, lampTop + 20),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: lampTop,
                                  left: (w - lampWidth) / 2,
                                  width: lampWidth,
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _glowController,
                                      _flickerController,
                                    ]),
                                    builder: (context, _) {
                                      final g = (_glow.value * _flickerFactor)
                                          .clamp(0.0, 1.0);
                                      return LampWidget(glow: g);
                                    },
                                  ),
                                ),

                                // Pull string starts from inside the shade opening.
                                Positioned(
                                  top: stringTop,
                                  left: w / 2 + lampWidth * 0.12,
                                  child: AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, _) {
                                      return PullStringWidget(
                                        pullPx: _pullPx,
                                        maxPullPx: _maxPullPx,
                                        wavePhase: _waveController.value,
                                        waveStrength: _waveStrength,
                                        onTap: _tapPull,
                                        onDragUpdate: _onPullDragUpdate,
                                        onDragEnd: _onPullDragEnd,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Expose state via Semantics for tests/accessibility.
                // (Keeps UI minimal while still being verifiable.)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Semantics(
                      key: const Key('lamp_state'),
                      label: 'lamp',
                      value: _isOn ? 'on' : 'off',
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dark background with a subtle vignette to make the glow feel premium.
class _BackgroundVignette extends StatelessWidget {
  const _BackgroundVignette({required this.drift});

  /// 0..1 repeating, used to drift the vignette slightly.
  final double drift;

  @override
  Widget build(BuildContext context) {
    final dx = math.sin(drift * math.pi * 2) * 0.06;
    final dy = math.cos(drift * math.pi * 2) * 0.05;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.25,
          colors: [Color(0xFF10131A), Color(0xFF08090C), Color(0xFF06070A)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(dx, -0.20 + dy),
            radius: 1.22,
            colors: [
              const Color(0xFF151A23).withOpacity(0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Glow / light spill effect.
///
/// Built with gradients + soft blur (no images) so it stays asset-free.
class GlowEffect extends StatelessWidget {
  const GlowEffect({super.key, required this.intensity, required this.anchor});

  /// 0..1, driven by the lamp on/off animation.
  final double intensity;

  /// Where the lamp bulb lives (in global stack coordinates).
  final Offset anchor;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0.001) return const SizedBox.expand();

    return CustomPaint(
      painter: _GlowPainter(intensity: intensity, anchor: anchor),
      child: const SizedBox.expand(),
    );
  }
}

class _BeamClipper extends CustomClipper<Path> {
  _BeamClipper({required this.anchor, required this.intensity});

  final Offset anchor;
  final double intensity;

  @override
  Path getClip(Size size) {
    final coneTop = anchor + const Offset(0, 36);
    final coneHeight = lerpDouble(220, 420, intensity) ?? 320;
    final coneHalfWidth = lerpDouble(90, 170, intensity) ?? 130;

    return Path()
      ..moveTo(coneTop.dx - 18, coneTop.dy)
      ..lineTo(coneTop.dx + 18, coneTop.dy)
      ..lineTo(coneTop.dx + coneHalfWidth, coneTop.dy + coneHeight)
      ..lineTo(coneTop.dx - coneHalfWidth, coneTop.dy + coneHeight)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BeamClipper oldClipper) {
    return oldClipper.anchor != anchor || oldClipper.intensity != intensity;
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.intensity, required this.anchor});

  final double intensity;
  final Offset anchor;

  @override
  void paint(Canvas canvas, Size size) {
    final warm = const Color(0xFFFFD08A);
    final hot = const Color(0xFFFFF2DB);

    // Ambient glow behind the shade.
    final r = lerpDouble(140, 300, intensity) ?? 240;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          hot.withOpacity(0.40 * intensity),
          warm.withOpacity(0.22 * intensity),
          warm.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: anchor, radius: r))
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        lerpDouble(6, 18, intensity) ?? 12,
      );
    canvas.drawCircle(anchor, r, glowPaint);

    // Light cone: a minimal beam for a cinematic feel.
    final coneTop = anchor + const Offset(0, 36);
    final coneHeight = lerpDouble(220, 420, intensity) ?? 320;
    final coneHalfWidth = lerpDouble(90, 170, intensity) ?? 130;

    final conePath = Path()
      ..moveTo(coneTop.dx - 18, coneTop.dy)
      ..lineTo(coneTop.dx + 18, coneTop.dy)
      ..lineTo(coneTop.dx + coneHalfWidth, coneTop.dy + coneHeight)
      ..lineTo(coneTop.dx - coneHalfWidth, coneTop.dy + coneHeight)
      ..close();

    final conePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              warm.withOpacity(0.18 * intensity),
              warm.withOpacity(0.06 * intensity),
              warm.withOpacity(0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromLTWH(
              coneTop.dx - coneHalfWidth,
              coneTop.dy,
              coneHalfWidth * 2,
              coneHeight,
            ),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(conePath, conePaint);

    // Volumetric upgrade: a hotter inner core that makes the beam feel 3D.
    final innerHalfWidth = coneHalfWidth * 0.58;
    final innerHeight = coneHeight * 0.92;
    final innerTop = coneTop + const Offset(0, 6);
    final innerPath = Path()
      ..moveTo(innerTop.dx - 12, innerTop.dy)
      ..lineTo(innerTop.dx + 12, innerTop.dy)
      ..lineTo(innerTop.dx + innerHalfWidth, innerTop.dy + innerHeight)
      ..lineTo(innerTop.dx - innerHalfWidth, innerTop.dy + innerHeight)
      ..close();

    final corePaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              hot.withOpacity(0.14 * intensity),
              warm.withOpacity(0.08 * intensity),
              warm.withOpacity(0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromLTWH(
              innerTop.dx - innerHalfWidth,
              innerTop.dy,
              innerHalfWidth * 2,
              innerHeight,
            ),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(innerPath, corePaint);

    // Soft edge rolloff: slightly brighter near the edges, very subtle.
    final edgePaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader =
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              warm.withOpacity(0.020 * intensity),
              Colors.transparent,
              warm.withOpacity(0.020 * intensity),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
            Rect.fromLTWH(
              coneTop.dx - coneHalfWidth,
              coneTop.dy,
              coneHalfWidth * 2,
              coneHeight,
            ),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawPath(conePath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.anchor != anchor;
  }
}

/// Lamp body (shade + bulb) drawn with simple shapes/gradients.
///
/// - [glow] controls bulb brightness and shade reflections.
class LampWidget extends StatelessWidget {
  const LampWidget({super.key, required this.glow});

  final double glow;

  @override
  Widget build(BuildContext context) {
    // Fixed aspect keeps it stable for reels and previews.
    return AspectRatio(
      aspectRatio: 1.1,
      child: CustomPaint(painter: _LampPainter(glow: glow)),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({required this.glow});

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final warm = const Color(0xFFFFD08A);
    final hot = const Color(0xFFFFF2DB);

    final centerX = size.width / 2;

    // Shade: rounded trapezoid.
    // Keep this value early so the mount/cable can attach with no gaps.
    final topY = 54.0;

    // Suspension cord (top to mount) for a proper hanging feel.
    final cordPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2A2E38).withOpacity(0.75),
          const Color(0xFF0B0C0F).withOpacity(0.35),
        ],
      ).createShader(Rect.fromLTWH(centerX - 2, 0, 4, topY))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, topY - 20), cordPaint);

    // Mount / cap.
    final capRect = Rect.fromCenter(
      center: Offset(centerX, topY - 18),
      width: size.width * 0.20,
      height: 14,
    );
    final capPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2A2E38), Color(0xFF151821)],
      ).createShader(capRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(8)),
      capPaint,
    );

    // Thin rod: connect mount to shade with NO visible gap.
    final rodPaint = Paint()
      ..color = const Color(0xFF1A1E28)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, capRect.bottom),
      Offset(centerX, topY + 1),
      rodPaint,
    );

    final bottomY = size.height * 0.60;
    final topW = size.width * 0.56;
    final bottomW = size.width * 0.82;
    final shadePath = Path()
      ..moveTo(centerX - topW / 2, topY)
      ..lineTo(centerX + topW / 2, topY)
      ..lineTo(centerX + bottomW / 2, bottomY)
      ..lineTo(centerX - bottomW / 2, bottomY)
      ..close();

    // Base shade gradient.
    final shadeRect = Rect.fromLTWH(
      centerX - bottomW / 2,
      topY,
      bottomW,
      bottomY - topY,
    );

    final shadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF2B2F3A), const Color(0xFF151821)],
      ).createShader(shadeRect);
    canvas.drawPath(shadePath, shadePaint);

    // Reflection highlight that appears when the lamp is on.
    if (glow > 0.001) {
      canvas.save();
      canvas.clipPath(shadePath);
      final highlightPaint = Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(0.35, 0.8),
          colors: [
            hot.withOpacity(0.14 * glow),
            warm.withOpacity(0.06 * glow),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(shadeRect);

      canvas.drawRect(shadeRect, highlightPaint);
      canvas.restore();
    }

    // Rim at the bottom (makes it feel less flat).
    final rimRect = Rect.fromLTWH(
      centerX - bottomW / 2,
      bottomY - 10,
      bottomW,
      14,
    );
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF0F1116),
          const Color(0xFF2B2F3A),
          const Color(0xFF0F1116),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rimRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(10)),
      rimPaint,
    );

    // Bulb.
    final bulbCenter = Offset(centerX, bottomY + 18);
    final bulbRadius = size.width * 0.10;
    final bulbRect = Rect.fromCircle(center: bulbCenter, radius: bulbRadius);

    final bulbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.95,
        colors: [
          hot.withOpacity(lerpDouble(0.35, 1.0, glow) ?? 1.0),
          warm.withOpacity(lerpDouble(0.18, 0.90, glow) ?? 0.9),
          const Color(0xFF2A2E38),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bulbRect);
    canvas.drawCircle(bulbCenter, bulbRadius, bulbPaint);

    // Subtle bulb bloom.
    if (glow > 0.001) {
      final bloomPaint = Paint()
        ..color = warm.withOpacity(0.22 * glow)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          lerpDouble(8, 18, glow) ?? 14,
        );
      canvas.drawCircle(bulbCenter, bulbRadius * 1.35, bloomPaint);
    }

    // Ground shadow (very subtle, helps realism in previews).
    final shadowY = bottomY + 210;
    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, shadowY),
      width: size.width * 0.95,
      height: 26,
    );
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.black.withOpacity(0.36), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(shadowRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _LampPainter oldDelegate) {
    return oldDelegate.glow != glow;
  }
}

/// Pull string + handle.
///
/// This widget intentionally exposes a small touch target (handle) with
/// drag/tap gestures. Pull distance is passed in via [pullPx].
class PullStringWidget extends StatelessWidget {
  const PullStringWidget({
    super.key,
    required this.pullPx,
    required this.maxPullPx,
    required this.wavePhase,
    required this.waveStrength,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double pullPx;
  final double maxPullPx;
  final double wavePhase;
  final double waveStrength;
  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    const baseStringLength = 250.0;

    // Rope extends when pulled; top stays anchored (no whole-widget translate).
    final ropeHeight = baseStringLength + pullPx;

    final pullT = (pullPx / maxPullPx).clamp(0.0, 1.0);
    final decay = (1.0 - wavePhase).clamp(0.0, 1.0);
    final wobble = math.sin(wavePhase * math.pi * 2 * 3.0);
    final wobbleX = wobble * (10.0 * waveStrength * decay) + (pullT * 1.0);
    final wobbleRot = wobble * (0.06 * waveStrength * decay);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rope.
        Transform.translate(
          offset: Offset(wobbleX, 0),
          child: CustomPaint(
            size: Size(44, ropeHeight),
            painter: _StringWavePainter(
              phase: wavePhase,
              strength: waveStrength,
              pullT: pullT,
            ),
          ),
        ),

        // Handle: the main touch target.
        GestureDetector(
          key: const Key('pull_handle'),
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          onVerticalDragUpdate: onDragUpdate,
          onVerticalDragEnd: onDragEnd,
          child: Transform.translate(
            offset: Offset(wobbleX * 0.55, 0),
            child: Transform.rotate(
              angle: wobbleRot,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.25, -0.25),
                    colors: [Color(0xFF3A3F4B), Color(0xFF171A22)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.60),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0B0C0F).withOpacity(0.85),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StringWavePainter extends CustomPainter {
  _StringWavePainter({
    required this.phase,
    required this.strength,
    required this.pullT,
  });

  final double phase;
  final double strength;
  final double pullT;

  @override
  void paint(Canvas canvas, Size size) {
    final decay = (1.0 - phase).clamp(0.0, 1.0);
    final amp = (1.2 + 8.0 * strength) * decay + (pullT * 1.1);
    final centerX = size.width / 2;

    final top = Offset(centerX, 0);
    final bottom = Offset(centerX, size.height);

    // Build a gently wavy curve by sampling points.
    final path = Path()..moveTo(top.dx, top.dy);
    const points = 18;
    for (var i = 1; i <= points; i++) {
      final t = i / points;
      final y = size.height * t;

      // Stronger wave near the handle.
      final handleBias = lerpDouble(0.25, 1.0, t) ?? 1.0;
      final wave = math.sin(
        (t * math.pi * 2 * 1.65) + (phase * math.pi * 2 * 3.2),
      );
      final x = centerX + (wave * amp * handleBias);
      path.lineTo(x, y);
    }

    final stringRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3B3F49).withOpacity(0.85),
          const Color(0xFF0E1015).withOpacity(0.80),
        ],
      ).createShader(stringRect);

    // Slight blur for a softer, cinematic look.
    final softPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, softPaint);
    canvas.drawPath(path, paint);

    // Small knot near the bottom (subtle).
    final knotY = size.height - 10;
    canvas.drawCircle(
      Offset(centerX, knotY),
      1.6,
      Paint()..color = const Color(0xFF3B3F49).withOpacity(0.65),
    );

    // Ensure the bottom is visually anchored.
    canvas.drawCircle(bottom, 0.01, Paint()..color = Colors.transparent);
  }

  @override
  bool shouldRepaint(covariant _StringWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.strength != strength ||
        oldDelegate.pullT != pullT;
  }
}

class _DustParticle {
  const _DustParticle({
    required this.seed,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.twinkle,
  });

  final double seed;
  final double x; // -1..1
  final double y; // 0..1
  final double size;
  final double speed;
  final double twinkle;
}

class _DustPainter extends CustomPainter {
  _DustPainter({
    required this.anchor,
    required this.intensity,
    required this.t,
    required this.particles,
  });

  final Offset anchor;
  final double intensity;
  final double t;
  final List<_DustParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    // Beam geometry (matches _BeamClipper / _GlowPainter).
    final coneTop = anchor + const Offset(0, 36);
    final coneHeight = lerpDouble(220, 420, intensity) ?? 320;
    final coneHalfWidth = lerpDouble(90, 170, intensity) ?? 130;

    final warm = const Color(0xFFFFD08A);
    final hot = const Color(0xFFFFF2DB);

    for (final p in particles) {
      // Downward drift with wrap.
      final y = (p.y + (t * p.speed) + (p.seed * 0.7)) % 1.0;
      final yPx = coneTop.dy + (y * coneHeight);

      // Beam narrows near top, widens near bottom.
      final widthAtY = lerpDouble(18, coneHalfWidth, y) ?? coneHalfWidth;
      final xPx = coneTop.dx + (p.x * widthAtY * 0.88);

      // Twinkle adds life but stays subtle.
      final tw = (math.sin((t + p.seed) * math.pi * 2 * 1.6) * 0.5 + 0.5);
      final alpha =
          (0.05 + (0.10 * tw * p.twinkle)) * (intensity.clamp(0.0, 1.0));

      final r = p.size;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            hot.withOpacity(alpha * 0.95),
            warm.withOpacity(alpha * 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(xPx, yPx), radius: r * 4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(xPx, yPx), r * 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.intensity != intensity ||
        oldDelegate.anchor != anchor ||
        oldDelegate.particles != particles;
  }
}

class _CausticsPainter extends CustomPainter {
  _CausticsPainter({
    required this.anchor,
    required this.intensity,
    required this.t,
  });

  final Offset anchor;
  final double intensity;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final warm = const Color(0xFFFFD08A);
    final hot = const Color(0xFFFFF2DB);

    // Place caustics towards the bottom, aligned with the beam.
    final y = (anchor.dy + 520).clamp(0.0, size.height);
    final center = Offset(anchor.dx, y);

    final driftX = math.sin(t * math.pi * 2 * 0.7) * 16;
    final driftY = math.cos(t * math.pi * 2 * 0.6) * 10;

    final baseW = lerpDouble(170, 260, intensity) ?? 220;
    final baseH = lerpDouble(36, 56, intensity) ?? 46;

    final shimmer = (math.sin(t * math.pi * 2 * 1.35) * 0.5 + 0.5).clamp(
      0.0,
      1.0,
    );
    final alpha =
        ((intensity - 0.18) / 0.82).clamp(0.0, 1.0) * (0.16 + shimmer * 0.10);

    final rect = Rect.fromCenter(
      center: center + Offset(driftX, driftY),
      width: baseW,
      height: baseH,
    );

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          hot.withOpacity(alpha * 0.85),
          warm.withOpacity(alpha * 0.55),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawOval(rect, paint);

    // Secondary streaks (very subtle) to mimic caustic breakup.
    final streakPaint = Paint()
      ..blendMode = BlendMode.screen
      ..color = warm.withOpacity(alpha * 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    for (var i = 0; i < 3; i++) {
      final p = (i / 3.0);
      final sx = math.sin((t + p) * math.pi * 2 * 1.2) * 22;
      final sy = math.cos((t + p) * math.pi * 2 * 1.1) * 7;
      final r = Rect.fromCenter(
        center: center + Offset(driftX + sx, driftY + sy),
        width: baseW * (0.22 + p * 0.08),
        height: baseH * 0.55,
      );
      canvas.drawOval(r, streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CausticsPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.intensity != intensity ||
        oldDelegate.anchor != anchor;
  }
}

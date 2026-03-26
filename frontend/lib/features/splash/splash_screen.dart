import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/logo_widget.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _progressCtrl;

  // ── Animations ──────────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _shimmer;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo pop-in
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoSlide = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.3), end: Offset.zero));

    // Pulse rings
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulseScale = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 1.0, end: 2.4));
    _pulseOpacity =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut)
            .drive(Tween(begin: 0.4, end: 0.0));

    // Shimmer sweep
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _shimmer = _shimmerCtrl.drive(Tween(begin: -1.5, end: 2.5));

    // Floating particles
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();

    // Text fade-slide in
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.4), end: Offset.zero));

    // Progress bar
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _progressValue = CurvedAnimation(
            parent: _progressCtrl, curve: Curves.easeInOutCubic)
        .drive(Tween(begin: 0.0, end: 1.0));
  }

  Future<void> _startSequence() async {
    // 1. Logo pop-in at 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();

    // 2. Text + progress appear at 700ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();
    _progressCtrl.forward();

    // 3. Navigate at 2800ms
    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // ── Floating particles ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Radial gradient overlay ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppTheme.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Pulse rings + logo ───────────────────────────────────────
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseScale.value,
                          child: Opacity(
                            opacity: _pulseOpacity.value,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Inner pulse ring (offset phase)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final phase =
                              (_pulseCtrl.value + 0.4).clamp(0.0, 1.0);
                          final scale = 1.0 + phase * 1.4;
                          final opacity = (0.4 - phase * 0.4).clamp(0.0, 0.4);
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Logo with shimmer
                      FadeTransition(
                        opacity: _logoFade,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: _ShimmerLogo(shimmerAnim: _shimmer),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── App name + tagline ───────────────────────────────────────
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(children: [
                      const Text(
                        'PG Hostel',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hostel Management System',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 48),

                // ── Animated progress bar ────────────────────────────────────
                FadeTransition(
                  opacity: _textFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(children: [
                      AnimatedBuilder(
                        animation: _progressValue,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progressValue.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom version badge ───────────────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.25),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Logo ──────────────────────────────────────────────────────────────
class _ShimmerLogo extends StatelessWidget {
  final Animation<double> shimmerAnim;
  const _ShimmerLogo({required this.shimmerAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            (shimmerAnim.value - 0.4).clamp(0.0, 1.0),
            shimmerAnim.value.clamp(0.0, 1.0),
            (shimmerAnim.value + 0.4).clamp(0.0, 1.0),
          ],
          colors: [
            Colors.white.withOpacity(0.85),
            Colors.white,
            Colors.white.withOpacity(0.85),
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const AppLogo(size: 90),
      ),
    );
  }
}

// ── Floating Particles Painter ────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);

  static final _particles = List.generate(18, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      radius: 1.5 + _rng.nextDouble() * 3,
      speed: 0.15 + _rng.nextDouble() * 0.3,
      phase: _rng.nextDouble(),
      drift: (_rng.nextDouble() - 0.5) * 0.04,
    );
  });

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final x = (p.x + p.drift * t) * size.width;
      final y = (p.y - t * 0.6) * size.height;
      final opacity = (t < 0.15
              ? t / 0.15
              : t > 0.75
                  ? (1 - t) / 0.25
                  : 1.0) *
          0.35;

      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, radius, speed, phase, drift;
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.drift,
  });
}
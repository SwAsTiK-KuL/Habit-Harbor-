import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_event.dart';
import '../../application/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ───────────────────────────────────────────────────

  late final AnimationController _rippleController;
  late final AnimationController _contentController;
  late final AnimationController _exitController;

  // Ripple rings
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _ring3Scale;
  late final Animation<double> _ring3Opacity;

  // Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Bottom content
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _taglineOpacity;

  // Exit
  late final Animation<double> _exitOpacity;

  bool _authCheckDone = false;
  String? _navigationTarget;

  // ── Palette — matched to logo blues ─────────────────────────────────────────

  static const _bg = Color(0xFFF0F6FF);
  static const _blue = Color(0xFF1565C0);
  static const _blueLight = Color(0xFF42A5F5);
  static const _ink = Color(0xFF0D1B2A);
  static const _inkMid = Color(0xFF5A6A7A);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
    _triggerAuthCheck();
  }

  void _setupAnimations() {
    // ── Ripple (loops) ──────────────────────────────
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _ring1Scale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _ring1Opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring2Scale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.18, 0.9, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.38, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.38, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring3Scale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.32, 1.0, curve: Curves.easeOut),
      ),
    );
    _ring3Opacity = Tween<double>(begin: 0.25, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.52, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Content reveal ───────────────────────────────
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.72, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );

    // ── Exit fade ────────────────────────────────────
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _contentController.forward();
  }

  void _triggerAuthCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(CheckAuthStatus());
    });
  }

  Future<void> _navigateWhenReady() async {
    if (!_authCheckDone || _navigationTarget == null) return;

    if (_contentController.value < 0.9) {
      await _contentController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _rippleController.stop();
    await _exitController.forward();
    if (!mounted) return;

    if (_navigationTarget == 'home') {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _contentController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
      ),
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _authCheckDone = true;
          _navigationTarget = 'home';
          _navigateWhenReady();
        } else if (state is AuthUnauthenticated) {
          _authCheckDone = true;
          _navigationTarget = 'login';
          _navigateWhenReady();
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _rippleController,
            _contentController,
            _exitController,
          ]),
          builder: (context, _) {
            return FadeTransition(
              opacity: _exitOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Radial gradient background ──────────────
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Colors.white,
                            _bg,
                            _blueLight.withOpacity(0.12),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ── Grain texture ───────────────────────────
                  Positioned.fill(child: CustomPaint(painter: _GrainPainter())),

                  // ── Decorative corner arcs ──────────────────
                  Positioned(
                    top: -70,
                    right: -70,
                    child: _buildCornerArc(220, _blue.withOpacity(0.05)),
                  ),
                  Positioned(
                    bottom: -90,
                    left: -90,
                    child: _buildCornerArc(280, _blueLight.withOpacity(0.06)),
                  ),

                  // ── Logo centered vertically (slightly above center) ──
                  Align(
                    alignment: const Alignment(0, -0.18),
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ring 3 — outermost
                          _buildRippleRing(
                            scale: _ring3Scale.value,
                            opacity: _ring3Opacity.value,
                            size: 268,
                            strokeWidth: 1.0,
                          ),
                          // Ring 2
                          _buildRippleRing(
                            scale: _ring2Scale.value,
                            opacity: _ring2Opacity.value,
                            size: 222,
                            strokeWidth: 1.3,
                          ),
                          // Ring 1 — innermost
                          _buildRippleRing(
                            scale: _ring1Scale.value,
                            opacity: _ring1Opacity.value,
                            size: 176,
                            strokeWidth: 1.7,
                          ),

                          // ── Logo image ──────────────────────
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: SizedBox(
                                width: 210,
                                height: 210,
                                child: Image.asset(
                                  'assets/images/splash_image.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom panel — name + tagline + version ──
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 52),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _bg.withOpacity(0.0),
                            _bg.withOpacity(0.9),
                            _bg,
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App name
                          FadeTransition(
                            opacity: _nameOpacity,
                            child: SlideTransition(
                              position: _nameSlide,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Habit',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w300,
                                        color: _ink,
                                        letterSpacing: 1.5,
                                        height: 1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' Harbor',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: _blue,
                                        letterSpacing: 0.5,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: Text(
                              'Build habits. Find your rhythm.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _inkMid,
                                letterSpacing: 0.4,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Version
                          FadeTransition(
                            opacity: _nameOpacity,
                            child: Text(
                              'v1.0.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: _inkMid.withOpacity(0.5),
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildRippleRing({
    required double scale,
    required double opacity,
    required double size,
    required double strokeWidth,
  }) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _blue, width: strokeWidth),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerArc(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}

// ── Grain texture painter ─────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  final _rng = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.014)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 500; i++) {
      final dx = _rng.nextDouble() * size.width;
      final dy = _rng.nextDouble() * size.height;
      final r = _rng.nextDouble() * 0.8 + 0.3;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

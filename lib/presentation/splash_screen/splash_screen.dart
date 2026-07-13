import 'dart:async';
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

  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;
  late final Animation<double> _ring3Scale;
  late final Animation<double> _ring3Opacity;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _taglineOpacity;

  late final Animation<double> _exitOpacity;

  // ── Navigation state ────────────────────────────────────────────────────────

  // Both conditions must be true before navigating:
  // [1] _minDelayDone  — 2 seconds have passed
  // [2] _authCheckDone — BLoC emitted a terminal state
  bool _minDelayDone = false;
  bool _authCheckDone = false;
  bool _isNavigating = false;
  String? _navigationTarget;

  Timer? _minDelayTimer;
  Timer? _safetyTimer;

  // ── Palette ─────────────────────────────────────────────────────────────────

  static const _bg = Color(0xFFF0F6FF);
  static const _blue = Color(0xFF1565C0);
  static const _blueLight = Color(0xFF42A5F5);
  static const _ink = Color(0xFF0D1B2A);
  static const _inkMid = Color(0xFF5A6A7A);

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _contentController.forward();
    _triggerAuthCheck();
    _startMinDelayTimer();
    _startSafetyTimer();
  }

  @override
  void dispose() {
    _minDelayTimer?.cancel();
    _safetyTimer?.cancel();
    _rippleController.dispose();
    _contentController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ── Timers ───────────────────────────────────────────────────────────────────

  /// Minimum 2-second display time. After this fires we check if auth
  /// is already done — if yes navigate immediately, otherwise wait for
  /// the BLoC to emit its terminal state.
  void _startMinDelayTimer() {
    _minDelayTimer = Timer(const Duration(seconds: 2), () {
      _minDelayDone = true;
      debugPrint('⏱ SplashScreen: 2s minimum delay done');
      _tryNavigate();
    });
  }

  /// Hard fallback — if auth never resolves after 7s, force login.
  void _startSafetyTimer() {
    _safetyTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _isNavigating) return;
      if (!_authCheckDone) {
        debugPrint('⚠️ SplashScreen: Safety timer — forcing login');
        _authCheckDone = true;
        _navigationTarget = 'login';
        _tryNavigate();
      }
    });
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  void _triggerAuthCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('🔵 SplashScreen: Firing CheckAuthStatus');
        context.read<AuthBloc>().add(CheckAuthStatus());
      }
    });
  }

  void _onAuthResolved(String target) {
    if (_authCheckDone) return;
    _authCheckDone = true;
    _navigationTarget = target;
    debugPrint('✅ SplashScreen: Auth resolved → $target');
    _safetyTimer?.cancel();
    _tryNavigate();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  /// Only navigates when BOTH the 2s delay is done AND auth has resolved.
  void _tryNavigate() {
    if (!_minDelayDone || !_authCheckDone) return;
    if (_isNavigating) return;
    if (!mounted) return;
    _isNavigating = true;

    debugPrint('🚀 SplashScreen: Navigating to /${_navigationTarget}');
    _rippleController.stop();

    // Play exit fade, then push the next route
    _exitController.forward().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        _navigationTarget == 'home' ? '/home' : '/login',
      );
    });
  }

  // ── Animations ───────────────────────────────────────────────────────────────

  void _setupAnimations() {
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

    // ✅ 600ms fade-out exit animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
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
        debugPrint('🔵 SplashScreen: state = ${state.runtimeType}');
        if (state is AuthAuthenticated) {
          _onAuthResolved('home');
        } else if (state is AuthUnauthenticated) {
          _onAuthResolved('login');
        } else if (state is AuthError) {
          debugPrint('⚠️ SplashScreen: AuthError → ${state.message}');
          _onAuthResolved('login');
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
                  // ── Background gradient ─────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.3),
                        radius: 1.1,
                        colors: [_blueLight.withOpacity(0.12), _bg],
                      ),
                    ),
                  ),

                  // ── Grain texture ───────────────────────────
                  Positioned.fill(
                    child: CustomPaint(painter: _GrainPainter()),
                  ),

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

                  // ── Logo ────────────────────────────────────
                  Align(
                    alignment: const Alignment(0, -0.18),
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRippleRing(
                            scale: _ring3Scale.value,
                            opacity: _ring3Opacity.value,
                            size: 268,
                            strokeWidth: 1.0,
                          ),
                          _buildRippleRing(
                            scale: _ring2Scale.value,
                            opacity: _ring2Opacity.value,
                            size: 222,
                            strokeWidth: 1.3,
                          ),
                          _buildRippleRing(
                            scale: _ring1Scale.value,
                            opacity: _ring1Opacity.value,
                            size: 176,
                            strokeWidth: 1.7,
                          ),
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

                  // ── Bottom panel ────────────────────────────
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
    final paint = Paint()
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
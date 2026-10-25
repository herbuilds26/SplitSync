import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../main.dart';
import '../../widgets/botanical_illustrations.dart';

/// 🌿 A playful, fun, beautifully animated Splash Screen for SplitSync.
/// Features:
/// - Elastic bouncing entrance with playful wobble/wiggle
/// - Pulsing shockwave rings & orbiting sync particles
/// - Gentle floating & breathing idle motion
/// - Interactive tap-to-bounce squish response
/// - Staggered typography reveal & hopping mint/berry dots
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final bool autoNavigate;
  final Widget? destination;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
    this.autoNavigate = true,
    this.destination,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Main entrance & sequence controller
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _wobbleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _rippleAnimation;
  late final Animation<double> _textSlideAnimation;
  late final Animation<double> _textOpacityAnimation;

  // Continuous looping idle animation (float & orbit)
  late final AnimationController _idleController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _orbitAnimation;
  late final Animation<double> _pulseGlowAnimation;

  // Interactive tap squish controller
  late final AnimationController _tapSquishController;
  late final Animation<double> _tapSquishAnimation;

  Timer? _navTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance choreography controller (1200ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Elastic bounce entrance: starts small, springs out playfully
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.18).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 0.94).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75),
    ));

    // Playful wobble (tilts left, rights itself, wiggles to center)
    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.22, end: 0.18).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.18, end: -0.09).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.09, end: 0.04).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.04, end: 0.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 15,
      ),
    ]).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.1, 0.8),
    ));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // Staggered text reveal
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.85, curve: Curves.easeIn),
      ),
    );

    // 2. Looping idle motion (floating and orbiting particles)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOutSine,
      ),
    );

    _orbitAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.linear,
      ),
    );

    _pulseGlowAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _idleController,
        curve: Curves.easeInOut,
      ),
    );

    // 3. Tap squish reaction (quick spring compression)
    _tapSquishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _tapSquishAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.86), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.86, end: 1.10), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.10, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _tapSquishController,
      curve: Curves.easeOutBack,
    ));

    // Kick off animations
    _entranceController.forward().then((_) {
      if (mounted) {
        _idleController.repeat(reverse: true);
      }
    });

    if (widget.autoNavigate) {
      _scheduleNavigation();
    }
  }

  void _scheduleNavigation() {
    _navTimer?.cancel();
    _navTimer = Timer(widget.duration, () {
      if (mounted && !_hasNavigated) {
        _navigateToDestination();
      }
    });
  }

  void _navigateToDestination() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _navTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.destination ?? const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          final scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  void _onLogoTapped() {
    if (!_tapSquishController.isAnimating) {
      _tapSquishController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entranceController.dispose();
    _idleController.dispose();
    _tapSquishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBerry,
      body: GestureDetector(
        onTap: () {
          // Tap to skip after 1.2s or trigger fun squish
          if (_entranceController.isCompleted) {
            _navigateToDestination();
          } else {
            _onLogoTapped();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ================= 1. BACKGROUND GRADIENT & VIGNETTE =================
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.25,
                  colors: [
                    Color(0xFF6B223D), // Warm glowing center
                    Color(0xFF4A152B), // Signature Deep Berry
                    Color(0xFF260A16), // Deep rich edge vignette
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),

            // ================= 2. BOTANICAL CORNER ACCENTS =================
            const Positioned(
              top: -15,
              right: -10,
              child: Opacity(
                opacity: 0.35,
                child: HangingVinesIllustration(width: 170, height: 180),
              ),
            ),

            const Positioned(
              bottom: -20,
              left: -15,
              child: Opacity(
                opacity: 0.28,
                child: DelicateBouquetIllustration(width: 160, height: 170),
              ),
            ),

            // ================= 3. FLOATING BOKEH SPARKLE CIRCLES =================
            ..._buildBackgroundSparkles(),

            // ================= 4. MAIN CENTER CONTENT =================
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // ================= ANIMATED LOGO =================
                    _buildAnimatedLogo(),

                    const SizedBox(height: 32),

                    // ================= TYPOGRAPHY & BRANDING =================
                    _buildAnimatedBranding(),

                    const Spacer(flex: 4),

                    // ================= BOTTOM INDICATOR =================
                    _buildBottomHoppingIndicator(),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds fun background sparkles floating subtly around
  List<Widget> _buildBackgroundSparkles() {
    return [
      _buildSparkleDot(top: 140, left: 60, size: 8, color: AppColors.mintGreen, opacity: 0.45),
      _buildSparkleDot(top: 220, right: 70, size: 10, color: AppColors.berryRose, opacity: 0.5),
      _buildSparkleDot(bottom: 260, left: 80, size: 7, color: AppColors.mintGreen, opacity: 0.4),
      _buildSparkleDot(bottom: 180, right: 85, size: 9, color: AppColors.softBerryPink, opacity: 0.45),
    ];
  }

  Widget _buildSparkleDot({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          final pulse = (_idleController.value * 2 - 1).abs();
          return Opacity(
            opacity: (opacity * (0.6 + 0.4 * pulse)).clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(140),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the animated logo with shockwave ripples, orbiting particles,
  /// elastic scale, playful wobble, and tap squish.
  Widget _buildAnimatedLogo() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding Shockwave Ripple 1 (Mint Green)
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              if (_rippleAnimation.value == 0.0) return const SizedBox.shrink();
              final rippleScale = 0.8 + 0.8 * _rippleAnimation.value;
              final rippleOpacity = (1.0 - _rippleAnimation.value) * 0.45;
              return Transform.scale(
                scale: rippleScale,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.mintGreen.withAlpha(((rippleOpacity.clamp(0.0, 1.0)) * 255).toInt()),
                      width: 3.5,
                    ),
                  ),
                ),
              );
            },
          ),

          // Expanding Shockwave Ripple 2 (Berry Rose)
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              if (_rippleAnimation.value < 0.2) return const SizedBox.shrink();
              final norm = ((_rippleAnimation.value - 0.2) / 0.8).clamp(0.0, 1.0);
              final rippleScale = 0.85 + 0.75 * norm;
              final rippleOpacity = (1.0 - norm) * 0.35;
              return Transform.scale(
                scale: rippleScale,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.berryRose.withAlpha(((rippleOpacity.clamp(0.0, 1.0)) * 255).toInt()),
                      width: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),

          // Glowing Aura behind logo
          AnimatedBuilder(
            animation: _pulseGlowAnimation,
            builder: (context, child) {
              return Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.berryRose.withAlpha(
                        (85 * _pulseGlowAnimation.value).toInt(),
                      ),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.mintGreen.withAlpha(
                        (45 * _pulseGlowAnimation.value).toInt(),
                      ),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),

          // Orbiting Sync Particles (represents splitting & syncing)
          AnimatedBuilder(
            animation: _orbitAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildOrbitingDot(radius: 88, angle: _orbitAnimation.value, color: AppColors.mintGreen, size: 10),
                  _buildOrbitingDot(radius: 88, angle: _orbitAnimation.value + math.pi, color: AppColors.berryRose, size: 9),
                  _buildOrbitingDot(radius: 88, angle: _orbitAnimation.value + math.pi / 2, color: AppColors.softBerryPink, size: 7),
                  _buildOrbitingDot(radius: 88, angle: _orbitAnimation.value + 3 * math.pi / 2, color: AppColors.sageGreen, size: 8),
                ],
              );
            },
          ),

          // The Core Interactive Logo
          GestureDetector(
            onTap: _onLogoTapped,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _entranceController,
                _idleController,
                _tapSquishController,
              ]),
              builder: (context, child) {
                final scale = _scaleAnimation.value * _tapSquishAnimation.value;
                final wobble = _wobbleAnimation.value;
                final floatY = _entranceController.isCompleted ? _floatAnimation.value : 0.0;
                final opacity = _opacityAnimation.value.clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, floatY),
                    child: Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: wobble,
                        child: _buildLogoBadge(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the circular card framing the logo with rich depth
  Widget _buildLogoBadge() {
    return Container(
      width: 145,
      height: 145,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.3),
          radius: 0.95,
          colors: [
            Color(0xFFFFEDF1), // Soft highlight
            Color(0xFFFFE3EA), // Soft berry pink
            Color(0xFFF9D2DC), // Edge tone
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.berryRose.withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withAlpha(200),
          width: 3.5,
        ),
      ),
      child: Center(
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // High-quality fallback graphic if asset is missing
                return Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 68,
                  color: AppColors.deepBerry,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an orbiting dot along the perimeter of the logo
  Widget _buildOrbitingDot({
    required double radius,
    required double angle,
    required Color color,
    required double size,
  }) {
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(160),
              blurRadius: 6,
              spreadRadius: 1.5,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the animated SplitSync title & tagline with smooth staggered entrance
  Widget _buildAnimatedBranding() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: Opacity(
            opacity: _textOpacityAnimation.value.clamp(0.0, 1.0),
            child: Column(
              children: [
                // App Title
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFFFEDF1),
                        Color(0xFFFFE3EA),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'SplitSync',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Fun Tagline Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(45),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        size: 15,
                        color: AppColors.mintGreen,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Your expenses, beautifully in sync',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFEDF1),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Playful hopping berry & mint dots at the bottom
  Widget _buildBottomHoppingIndicator() {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        final progress = _idleController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHoppingDot(0, progress, AppColors.mintGreen),
            const SizedBox(width: 8),
            _buildHoppingDot(1, progress, AppColors.berryRose),
            const SizedBox(width: 8),
            _buildHoppingDot(2, progress, AppColors.softBerryPink),
          ],
        );
      },
    );
  }

  Widget _buildHoppingDot(int index, double progress, Color color) {
    // Phase offset per dot
    final phase = (progress + (index * 0.25)) % 1.0;
    final hopY = -math.sin(phase * math.pi) * 8.0;

    return Transform.translate(
      offset: Offset(0, hopY < 0 ? hopY : 0.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(120),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

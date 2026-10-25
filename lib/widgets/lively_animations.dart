import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';

/// 🎯 Tactile Bouncing Tap Micro-Interaction
/// Gives buttons, cards, and chips a lively physical spring on tap with subtle haptics.
class BouncingTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleLower;
  final Duration duration;
  final bool enableHaptics;

  const BouncingTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleLower = 0.94,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptics = true,
  });

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleLower,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 🌬️ Gentle Sinusoidal Floating & Swaying Motion
/// Perfect for hero icons, decorative botanicals, or badges.
class FloatingItem extends StatefulWidget {
  final Widget child;
  final double distance;
  final double tiltAngle;
  final Duration duration;

  const FloatingItem({
    super.key,
    required this.child,
    this.distance = 5.0,
    this.tiltAngle = 0.03,
    this.duration = const Duration(milliseconds: 2400),
  });

  @override
  State<FloatingItem> createState() => _FloatingItemState();
}

class _FloatingItemState extends State<FloatingItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final dy = math.sin(progress * math.pi) * widget.distance;
        final angle = math.sin(progress * math.pi) * widget.tiltAngle;

        return Transform.translate(
          offset: Offset(0, -dy),
          child: Transform.rotate(
            angle: angle,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 🌟 Pulsing Breathing Glow Aura
/// Gives cards and hero elements an ambient, alive presence.
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;
  final double minBlur;
  final Duration duration;

  const PulsingGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.berryRose,
    this.minBlur = 10.0,
    this.maxBlur = 22.0,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final blur = widget.minBlur + (widget.maxBlur - widget.minBlur) * t;
        final alpha = (35 + 35 * t).round();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withAlpha(alpha),
                blurRadius: blur,
                spreadRadius: 2.0 * t,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 📈 Smooth Animated Number & Currency Counter
/// Animates between numeric changes smoothly rather than jumping abruptly.
class AnimatedNumberCounter extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  const AnimatedNumberCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '₹',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        // Format with thousands commas and 2 decimals
        final formatted = _formatAmount(val);
        return Text(
          '$prefix$formatted',
          style: style,
        );
      },
    );
  }

  static String _formatAmount(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    if (integerPart.length <= 3) {
      return '$integerPart.$decimalPart';
    }

    final lastThree = integerPart.substring(integerPart.length - 3);
    final remaining = integerPart.substring(0, integerPart.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);

    return '${buffer.toString()}.$decimalPart';
  }
}

/// 🌊 Staggered Smooth Fade & Slide Entrance
/// Brings list items and sections in with progressive, pleasing motion.
class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final Offset offset;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0.0, 0.12),
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    final delay = Duration(milliseconds: widget.baseDelay.inMilliseconds * widget.index.clamp(0, 10));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

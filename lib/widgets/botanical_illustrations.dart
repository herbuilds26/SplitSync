import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// 🎨 Botanical Illustration Styles matching SplitSync Reference Designs
enum BotanicalStyle {
  delicateBouquet, // Option 1: Slender bouquet with 5-petal blush blossoms & bow ribbon
  minimalBloom,    // Option 2: Contour layered tulip/magnolia bloom with aura
  hangingVines,    // Option 3: Cascading vines & drifting leaves from top-right
  moonlitFlorals,  // Option 5: Crescent moon with sparkling stars & twin tulip buds
  heartLeaves,     // Option 6: Potted plant with heart-shaped veined foliage
}

/// 🌿 Main Botanical Illustration Widget
/// Fully responsive vector art rendered via CustomPaint
class BotanicalIllustration extends StatelessWidget {
  final BotanicalStyle style;
  final double width;
  final double height;
  final bool isDark;

  const BotanicalIllustration({
    super.key,
    this.style = BotanicalStyle.delicateBouquet,
    this.width = 130,
    this.height = 135,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = Theme.of(context).brightness == Brightness.dark || isDark;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BotanicalPainter(
          style: style,
          isDark: effectiveDark,
        ),
      ),
    );
  }
}

/// 🌸 Backwards-compatible alias for existing screens
class MintLeafIllustration extends StatelessWidget {
  final double width;
  final double height;
  final BotanicalStyle style;

  const MintLeafIllustration({
    super.key,
    this.width = 120,
    this.height = 125,
    this.style = BotanicalStyle.delicateBouquet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BotanicalIllustration(
      style: style,
      width: width,
      height: height,
      isDark: isDark,
    );
  }
}

/// 💐 Option 1: Delicate Bouquet Illustration
class DelicateBouquetIllustration extends StatelessWidget {
  final double width;
  final double height;

  const DelicateBouquetIllustration({super.key, this.width = 130, this.height = 135});

  @override
  Widget build(BuildContext context) {
    return BotanicalIllustration(
      style: BotanicalStyle.delicateBouquet,
      width: width,
      height: height,
    );
  }
}

/// 🌷 Option 2: Minimal Bloom Illustration
class MinimalBloomIllustration extends StatelessWidget {
  final double width;
  final double height;

  const MinimalBloomIllustration({super.key, this.width = 120, this.height = 130});

  @override
  Widget build(BuildContext context) {
    return BotanicalIllustration(
      style: BotanicalStyle.minimalBloom,
      width: width,
      height: height,
    );
  }
}

/// 🌿 Option 3: Hanging Vines Illustration
class HangingVinesIllustration extends StatelessWidget {
  final double width;
  final double height;

  const HangingVinesIllustration({super.key, this.width = 120, this.height = 130});

  @override
  Widget build(BuildContext context) {
    return BotanicalIllustration(
      style: BotanicalStyle.hangingVines,
      width: width,
      height: height,
    );
  }
}

/// 🌙 Option 5: Moonlit Florals Illustration
class MoonlitFloralsIllustration extends StatelessWidget {
  final double width;
  final double height;

  const MoonlitFloralsIllustration({super.key, this.width = 130, this.height = 135});

  @override
  Widget build(BuildContext context) {
    return BotanicalIllustration(
      style: BotanicalStyle.moonlitFlorals,
      width: width,
      height: height,
    );
  }
}

/// 🪴 Option 6: Potted Heart Leaves Illustration
class HeartLeavesIllustration extends StatelessWidget {
  final double width;
  final double height;

  const HeartLeavesIllustration({super.key, this.width = 130, this.height = 135});

  @override
  Widget build(BuildContext context) {
    return BotanicalIllustration(
      style: BotanicalStyle.heartLeaves,
      width: width,
      height: height,
    );
  }
}

/// 🌺 Aesthetic Group Silhouette for List & Empty states
class GroupIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const GroupIllustration({
    super.key,
    this.size = 48,
    this.color = AppColors.berryRose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BotanicalPainter(
          style: BotanicalStyle.delicateBouquet,
          isDark: true,
          compactMode: true,
          overrideColor: color,
        ),
      ),
    );
  }
}

/// 🌿 Animated Living Botanical Illustration with gentle breeze sway & breath
class AnimatedBotanicalIllustration extends StatefulWidget {
  final BotanicalStyle style;
  final double width;
  final double height;
  final bool isDark;
  final double maxSwayAngle;
  final Duration duration;

  const AnimatedBotanicalIllustration({
    super.key,
    this.style = BotanicalStyle.heartLeaves,
    this.width = 130,
    this.height = 135,
    this.isDark = true,
    this.maxSwayAngle = 0.04,
    this.duration = const Duration(milliseconds: 3200),
  });

  @override
  State<AnimatedBotanicalIllustration> createState() => _AnimatedBotanicalIllustrationState();
}

class _AnimatedBotanicalIllustrationState extends State<AnimatedBotanicalIllustration>
    with SingleTickerProviderStateMixin {
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
        final angle = math.sin(t * math.pi) * widget.maxSwayAngle;
        final scale = 1.0 + math.sin(t * math.pi) * 0.02;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: BotanicalIllustration(
        style: widget.style,
        width: widget.width,
        height: widget.height,
        isDark: widget.isDark,
      ),
    );
  }
}

/// 🌸 Lively, Friendly Empty State with animated vector illustration & action
class LivelyEmptyState extends StatelessWidget {
  final BotanicalStyle illustrationStyle;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final VoidCallback? onButtonPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryButtonPressed;
  final double illustrationSize;

  const LivelyEmptyState({
    super.key,
    this.illustrationStyle = BotanicalStyle.delicateBouquet,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.buttonIcon,
    this.onButtonPressed,
    this.secondaryButtonLabel,
    this.onSecondaryButtonPressed,
    this.illustrationSize = 120,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Living Botanical Vector
            AnimatedBotanicalIllustration(
              style: illustrationStyle,
              width: illustrationSize,
              height: illustrationSize * 1.05,
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.berryRose,
                  foregroundColor: Colors.white,
                  elevation: isDark ? 0 : 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: buttonIcon != null ? Icon(buttonIcon, size: 18) : const SizedBox.shrink(),
                label: Text(
                  buttonLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: onButtonPressed,
              ),
            ],
            if (secondaryButtonLabel != null && onSecondaryButtonPressed != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondaryButtonPressed,
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.berryRose : AppColors.deepBerry,
                ),
                child: Text(
                  secondaryButtonLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================= MASTER BOTANICAL PAINTER =================
class _BotanicalPainter extends CustomPainter {
  final BotanicalStyle style;
  final bool isDark;
  final bool compactMode;
  final Color? overrideColor;

  _BotanicalPainter({
    required this.style,
    required this.isDark,
    this.compactMode = false,
    this.overrideColor,
  });

  // Reference Palette Colors
  static const Color sageGreen = Color(0xFF789D88);
  static const Color darkSage = Color(0xFF5A826B);
  static const Color paleSage = Color(0xFFA5C4B2);
  static const Color blushWhite = Color(0xFFFDEEF1);
  static const Color blushPink = Color(0xFFF5D3D9);
  static const Color rosePetal = Color(0xFFE57E9B);
  static const Color deepRose = Color(0xFFD64971);
  static const Color goldPistil = Color(0xFFF6C96C);
  static const Color auraWine = Color(0xFF6B223D);

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case BotanicalStyle.delicateBouquet:
        _paintDelicateBouquet(canvas, size);
        break;
      case BotanicalStyle.minimalBloom:
        _paintMinimalBloom(canvas, size);
        break;
      case BotanicalStyle.hangingVines:
        _paintHangingVines(canvas, size);
        break;
      case BotanicalStyle.moonlitFlorals:
        _paintMoonlitFlorals(canvas, size);
        break;
      case BotanicalStyle.heartLeaves:
        _paintHeartLeaves(canvas, size);
        break;
    }
  }

  // ================= 1. DELICATE BOUQUET (Option 1) =================
  void _paintDelicateBouquet(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Backdrop Ambient Aura Smoke Wave
    if (!compactMode) {
      final auraPaint = Paint()
        ..color = (isDark ? auraWine.withAlpha(90) : AppColors.softBerryPink.withAlpha(120))
        ..style = PaintingStyle.fill;

      final auraPath = Path();
      auraPath.moveTo(w * 0.25, h * 0.7);
      auraPath.quadraticBezierTo(w * 0.1, h * 0.45, w * 0.4, h * 0.3);
      auraPath.quadraticBezierTo(w * 0.85, h * 0.15, w * 0.95, h * 0.55);
      auraPath.quadraticBezierTo(w * 0.95, h * 0.85, w * 0.55, h * 0.85);
      auraPath.close();
      canvas.drawPath(auraPath, auraPaint);
    }

    final stemPaint = Paint()
      ..color = (overrideColor ?? darkSage)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compactMode ? 1.5 : 2.2
      ..strokeCap = StrokeCap.round;

    // Multiple Slender Bouquet Stems converging at waist
    final waistX = w * 0.62;
    final waistY = h * 0.68;

    // Stem 1 (Center)
    final stem1 = Path();
    stem1.moveTo(w * 0.52, h * 0.18);
    stem1.quadraticBezierTo(w * 0.56, h * 0.42, waistX, waistY);
    stem1.quadraticBezierTo(w * 0.66, h * 0.85, w * 0.68, h * 0.96);
    canvas.drawPath(stem1, stemPaint);

    // Stem 2 (Left Branch)
    final stem2 = Path();
    stem2.moveTo(w * 0.38, h * 0.28);
    stem2.quadraticBezierTo(w * 0.44, h * 0.48, waistX, waistY);
    stem2.quadraticBezierTo(w * 0.72, h * 0.82, w * 0.78, h * 0.94);
    canvas.drawPath(stem2, stemPaint);

    // Stem 3 (Right Branch)
    final stem3 = Path();
    stem3.moveTo(w * 0.72, h * 0.24);
    stem3.quadraticBezierTo(w * 0.68, h * 0.45, waistX, waistY);
    stem3.quadraticBezierTo(w * 0.58, h * 0.82, w * 0.54, h * 0.93);
    canvas.drawPath(stem3, stemPaint);

    // Sage Leaves on Bouquet
    _drawCurvedLeaf(canvas, Offset(w * 0.42, h * 0.44), Offset(w * 0.26, h * 0.38), 10, sageGreen);
    _drawCurvedLeaf(canvas, Offset(w * 0.66, h * 0.40), Offset(w * 0.82, h * 0.34), 11, paleSage);
    _drawCurvedLeaf(canvas, Offset(w * 0.46, h * 0.54), Offset(w * 0.32, h * 0.50), 10, sageGreen);
    _drawCurvedLeaf(canvas, Offset(w * 0.68, h * 0.52), Offset(w * 0.84, h * 0.50), 12, darkSage);

    // Dainty 5-Petal Blossoms with Warm Centers
    _drawFivePetalFlower(canvas, Offset(w * 0.52, h * 0.18), 8.5);
    _drawFivePetalFlower(canvas, Offset(w * 0.38, h * 0.28), 7.5);
    _drawFivePetalFlower(canvas, Offset(w * 0.70, h * 0.25), 8.0);
    _drawFivePetalFlower(canvas, Offset(w * 0.44, h * 0.36), 6.5);
    _drawFivePetalFlower(canvas, Offset(w * 0.62, h * 0.34), 7.0);

    // Small budding flowers
    _drawFlowerBud(canvas, Offset(w * 0.32, h * 0.24), 4.5);
    _drawFlowerBud(canvas, Offset(w * 0.78, h * 0.20), 4.5);

    // Tied Ribbon Bow with tails
    _drawBowRibbon(canvas, Offset(waistX, waistY), w * 0.22);
  }

  // ================= 2. MINIMAL BLOOM (Option 2) =================
  void _paintMinimalBloom(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient soft wine glow wave
    final auraPaint = Paint()
      ..color = (isDark ? auraWine.withAlpha(100) : AppColors.softBerryPink.withAlpha(130))
      ..style = PaintingStyle.fill;

    final aura = Path();
    aura.moveTo(w * 0.5, h * 0.75);
    aura.quadraticBezierTo(w * 0.25, h * 0.5, w * 0.55, h * 0.35);
    aura.quadraticBezierTo(w * 0.9, h * 0.3, w * 0.85, h * 0.7);
    aura.close();
    canvas.drawPath(aura, auraPaint);

    // Graceful Long Stem
    final stemPaint = Paint()
      ..color = darkSage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final stem = Path();
    stem.moveTo(w * 0.65, h * 0.95);
    stem.quadraticBezierTo(w * 0.55, h * 0.65, w * 0.68, h * 0.38);
    canvas.drawPath(stem, stemPaint);

    // Curving Sage Leaves
    _drawCurvedLeaf(canvas, Offset(w * 0.60, h * 0.72), Offset(w * 0.38, h * 0.62), 14, darkSage);
    _drawCurvedLeaf(canvas, Offset(w * 0.64, h * 0.56), Offset(w * 0.84, h * 0.50), 12, paleSage);

    // Minimalist Contour Tulip / Magnolia Petals
    final petalOutline = Paint()
      ..color = rosePetal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final petalFill = Paint()
      ..color = blushPink.withAlpha(110)
      ..style = PaintingStyle.fill;

    // Center main petal
    final petalCenter = Path();
    petalCenter.moveTo(w * 0.68, h * 0.38);
    petalCenter.quadraticBezierTo(w * 0.58, h * 0.26, w * 0.66, h * 0.12);
    petalCenter.quadraticBezierTo(w * 0.76, h * 0.24, w * 0.68, h * 0.38);
    canvas.drawPath(petalCenter, petalFill);
    canvas.drawPath(petalCenter, petalOutline);

    // Left petal
    final petalLeft = Path();
    petalLeft.moveTo(w * 0.68, h * 0.38);
    petalLeft.quadraticBezierTo(w * 0.44, h * 0.32, w * 0.50, h * 0.16);
    petalLeft.quadraticBezierTo(w * 0.62, h * 0.22, w * 0.68, h * 0.38);
    canvas.drawPath(petalLeft, petalFill);
    canvas.drawPath(petalLeft, petalOutline);

    // Right petal
    final petalRight = Path();
    petalRight.moveTo(w * 0.68, h * 0.38);
    petalRight.quadraticBezierTo(w * 0.88, h * 0.30, w * 0.82, h * 0.16);
    petalRight.quadraticBezierTo(w * 0.72, h * 0.24, w * 0.68, h * 0.38);
    canvas.drawPath(petalRight, petalFill);
    canvas.drawPath(petalRight, petalOutline);
  }

  // ================= 3. HANGING VINES (Option 3) =================
  void _paintHangingVines(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final vinePaint = Paint()
      ..color = darkSage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Main vine drooping from top right
    final vine1 = Path();
    vine1.moveTo(w * 0.95, -5);
    vine1.quadraticBezierTo(w * 0.85, h * 0.35, w * 0.90, h * 0.65);
    vine1.quadraticBezierTo(w * 0.94, h * 0.85, w * 0.82, h * 0.98);
    canvas.drawPath(vine1, vinePaint);

    // Side vine
    final vine2 = Path();
    vine2.moveTo(w * 0.90, h * 0.2);
    vine2.quadraticBezierTo(w * 0.74, h * 0.35, w * 0.76, h * 0.55);
    canvas.drawPath(vine2, vinePaint);

    // Cascading Leaves along the vine (Sage and Tender Blush)
    _drawHeartLeaf(canvas, Offset(w * 0.88, h * 0.08), 9, paleSage, 0.4);
    _drawHeartLeaf(canvas, Offset(w * 0.82, h * 0.16), 11, blushPink, -0.3);
    _drawHeartLeaf(canvas, Offset(w * 0.86, h * 0.28), 12, sageGreen, 0.5);
    _drawHeartLeaf(canvas, Offset(w * 0.74, h * 0.32), 10, blushPink, -0.6);
    _drawHeartLeaf(canvas, Offset(w * 0.88, h * 0.45), 13, darkSage, 0.3);
    _drawHeartLeaf(canvas, Offset(w * 0.76, h * 0.54), 11, paleSage, -0.4);
    _drawHeartLeaf(canvas, Offset(w * 0.90, h * 0.64), 12, blushPink, 0.6);
    _drawHeartLeaf(canvas, Offset(w * 0.85, h * 0.78), 10, sageGreen, -0.2);
    _drawHeartLeaf(canvas, Offset(w * 0.82, h * 0.96), 8, paleSage, 0.2);

    // Drifting fallen petals
    _drawFallenPetal(canvas, Offset(w * 0.65, h * 0.65), 5.5, blushPink, 0.8);
    _drawFallenPetal(canvas, Offset(w * 0.55, h * 0.80), 4.5, rosePetal, -0.5);
  }

  // ================= 5. MOONLIT FLORALS (Option 5) =================
  void _paintMoonlitFlorals(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing Ambient Halo
    final moonHalo = Paint()
      ..color = (isDark ? auraWine.withAlpha(120) : AppColors.softBerryPink.withAlpha(140))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.65, h * 0.42), w * 0.34, moonHalo);

    // Glowing Crescent Moon
    final moonPaint = Paint()
      ..color = blushPink.withAlpha(isDark ? 160 : 210)
      ..style = PaintingStyle.fill;

    final moonPath = Path();
    moonPath.addArc(Rect.fromCircle(center: Offset(w * 0.66, h * 0.40), radius: w * 0.26), -1.8, 3.4);
    moonPath.arcTo(Rect.fromCircle(center: Offset(w * 0.72, h * 0.39), radius: w * 0.23), 1.6, -3.4, false);
    moonPath.close();
    canvas.drawPath(moonPath, moonPaint);

    // Twinkling 4-Point Stars
    _drawStarSparkle(canvas, Offset(w * 0.46, h * 0.32), 6.5, blushWhite);
    _drawStarSparkle(canvas, Offset(w * 0.85, h * 0.28), 5.0, blushPink);
    _drawStarSparkle(canvas, Offset(w * 0.52, h * 0.68), 4.0, blushWhite);

    // Twin Tulip Stems
    final stemPaint = Paint()
      ..color = darkSage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final stem1 = Path();
    stem1.moveTo(w * 0.78, h * 0.95);
    stem1.quadraticBezierTo(w * 0.72, h * 0.68, w * 0.75, h * 0.48);
    canvas.drawPath(stem1, stemPaint);

    final stem2 = Path();
    stem2.moveTo(w * 0.74, h * 0.90);
    stem2.quadraticBezierTo(w * 0.62, h * 0.72, w * 0.64, h * 0.56);
    canvas.drawPath(stem2, stemPaint);

    // Sage Leaves
    _drawCurvedLeaf(canvas, Offset(w * 0.74, h * 0.76), Offset(w * 0.88, h * 0.64), 14, sageGreen);
    _drawCurvedLeaf(canvas, Offset(w * 0.70, h * 0.68), Offset(w * 0.54, h * 0.62), 12, darkSage);

    // Tulip Blooms in Soft Blush
    _drawTulipBud(canvas, Offset(w * 0.75, h * 0.44), 13.0, blushPink, rosePetal);
    _drawTulipBud(canvas, Offset(w * 0.64, h * 0.52), 10.5, blushWhite, rosePetal);
  }

  // ================= 6. HEART LEAVES (Option 6) =================
  void _paintHeartLeaves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient back aura
    final auraPaint = Paint()
      ..color = (isDark ? auraWine.withAlpha(90) : AppColors.softBerryPink.withAlpha(120))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.68, h * 0.46), w * 0.32, auraPaint);

    // Stand / Plinth Base
    final plinthPaint = Paint()
      ..color = (isDark ? const Color(0xFF260D18) : const Color(0xFFE2B7C1))
      ..style = PaintingStyle.fill;
    final plinth = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.44, h * 0.88, w * 0.95, h * 0.98),
      const Radius.circular(6),
    );
    canvas.drawRRect(plinth, plinthPaint);

    // Cute Planter Pot in Blush Pink
    final potPaint = Paint()
      ..color = blushPink
      ..style = PaintingStyle.fill;

    final potPath = Path();
    potPath.moveTo(w * 0.58, h * 0.68);
    potPath.lineTo(w * 0.84, h * 0.68);
    potPath.lineTo(w * 0.79, h * 0.88);
    potPath.lineTo(w * 0.63, h * 0.88);
    potPath.close();
    canvas.drawPath(potPath, potPaint);

    // Little Berry Heart on Pot
    _drawTinyHeart(canvas, Offset(w * 0.71, h * 0.77), 4.5, deepBerryColor);

    // Plant Stems
    final stemPaint = Paint()
      ..color = darkSage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(w * 0.71, h * 0.68), Offset(w * 0.71, h * 0.32), stemPaint);
    canvas.drawLine(Offset(w * 0.71, h * 0.68), Offset(w * 0.54, h * 0.40), stemPaint);
    canvas.drawLine(Offset(w * 0.71, h * 0.68), Offset(w * 0.88, h * 0.42), stemPaint);
    canvas.drawLine(Offset(w * 0.71, h * 0.68), Offset(w * 0.50, h * 0.56), stemPaint);
    canvas.drawLine(Offset(w * 0.71, h * 0.68), Offset(w * 0.90, h * 0.62), stemPaint);

    // Lush Heart-Shaped Veined Leaves
    _drawVeinedHeartLeaf(canvas, Offset(w * 0.71, h * 0.30), 18, darkSage, paleSage, 0);
    _drawVeinedHeartLeaf(canvas, Offset(w * 0.52, h * 0.38), 16, sageGreen, paleSage, -0.4);
    _drawVeinedHeartLeaf(canvas, Offset(w * 0.88, h * 0.40), 16, sageGreen, paleSage, 0.4);
    _drawVeinedHeartLeaf(canvas, Offset(w * 0.48, h * 0.54), 14, darkSage, paleSage, -0.6);
    _drawVeinedHeartLeaf(canvas, Offset(w * 0.90, h * 0.60), 13, paleSage, darkSage, 0.5);
  }

  static const Color deepBerryColor = Color(0xFF4A152B);

  // ================= HELPER VECTOR DRAWING METHODS =================

  /// Draws a classic 5-petal flower with blushing petals and warm golden pistil center
  void _drawFivePetalFlower(Canvas canvas, Offset center, double radius) {
    final petalPaint = Paint()
      ..color = blushWhite
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = rosePetal.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72.0) * math.pi / 180.0;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * (radius * 0.65),
        center.dy + math.sin(angle) * (radius * 0.65),
      );
      canvas.drawCircle(petalCenter, radius * 0.48, petalPaint);
      canvas.drawCircle(petalCenter, radius * 0.48, shadowPaint);
    }

    // Warm golden center core
    final corePaint = Paint()
      ..color = goldPistil
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.28, corePaint);
  }

  /// Small rounded flower bud
  void _drawFlowerBud(Canvas canvas, Offset center, double radius) {
    final budPaint = Paint()
      ..color = blushPink
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, budPaint);
    final centerPaint = Paint()..color = rosePetal..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  /// Smooth curving lanceolate leaf with tapered tip
  void _drawCurvedLeaf(Canvas canvas, Offset base, Offset tip, double width, Color color) {
    final leafPaint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final midX = (base.dx + tip.dx) / 2;
    final midY = (base.dy + tip.dy) / 2;
    final dx = tip.dx - base.dx;
    final dy = tip.dy - base.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final normalX = -dy / len;
    final normalY = dx / len;

    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(
      midX + normalX * width,
      midY + normalY * width,
      tip.dx,
      tip.dy,
    );
    path.quadraticBezierTo(
      midX - normalX * (width * 0.4),
      midY - normalY * (width * 0.4),
      base.dx,
      base.dy,
    );
    path.close();
    canvas.drawPath(path, leafPaint);
  }

  /// Delicate tied bow ribbon with two loops and dangling tails
  void _drawBowRibbon(Canvas canvas, Offset center, double size) {
    final ribbonPaint = Paint()
      ..color = rosePetal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final leftLoop = Path();
    leftLoop.moveTo(center.dx, center.dy);
    leftLoop.cubicTo(
      center.dx - size * 0.6,
      center.dy - size * 0.4,
      center.dx - size * 0.7,
      center.dy + size * 0.2,
      center.dx,
      center.dy,
    );
    canvas.drawPath(leftLoop, ribbonPaint);

    final rightLoop = Path();
    rightLoop.moveTo(center.dx, center.dy);
    rightLoop.cubicTo(
      center.dx + size * 0.6,
      center.dy - size * 0.4,
      center.dx + size * 0.7,
      center.dy + size * 0.2,
      center.dx,
      center.dy,
    );
    canvas.drawPath(rightLoop, ribbonPaint);

    // Ribbon Knot center
    final knotPaint = Paint()..color = deepRose..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.2, knotPaint);

    // Ribbon Tails dangling downwards
    final tail1 = Path();
    tail1.moveTo(center.dx - 1, center.dy + 2);
    tail1.quadraticBezierTo(center.dx - size * 0.4, center.dy + size * 0.6, center.dx - size * 0.6, center.dy + size * 0.9);
    canvas.drawPath(tail1, ribbonPaint);

    final tail2 = Path();
    tail2.moveTo(center.dx + 1, center.dy + 2);
    tail2.quadraticBezierTo(center.dx + size * 0.3, center.dy + size * 0.6, center.dx + size * 0.5, center.dy + size * 0.85);
    canvas.drawPath(tail2, ribbonPaint);
  }

  /// Heart-shaped leaf with rotation
  void _drawHeartLeaf(Canvas canvas, Offset center, double radius, Color color, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, radius);
    path.cubicTo(-radius, radius * 0.3, -radius, -radius * 0.6, 0, -radius * 0.3);
    path.cubicTo(radius, -radius * 0.6, radius, radius * 0.3, 0, radius);
    path.close();
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  /// Veined heart-shaped leaf
  void _drawVeinedHeartLeaf(Canvas canvas, Offset center, double radius, Color fillColor, Color veinColor, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final paint = Paint()..color = fillColor..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, radius * 1.1);
    path.cubicTo(-radius, radius * 0.3, -radius * 1.1, -radius * 0.7, 0, -radius * 0.4);
    path.cubicTo(radius * 1.1, -radius * 0.7, radius, radius * 0.3, 0, radius * 1.1);
    path.close();
    canvas.drawPath(path, paint);

    // Central vein
    final vPaint = Paint()..color = veinColor.withAlpha(180)..style = PaintingStyle.stroke..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, -radius * 0.3), Offset(0, radius * 0.9), vPaint);

    canvas.restore();
  }

  /// Tulip bud with overlapping petals
  void _drawTulipBud(Canvas canvas, Offset center, double radius, Color baseColor, Color edgeColor) {
    final fill = Paint()..color = baseColor..style = PaintingStyle.fill;
    final outline = Paint()..color = edgeColor..style = PaintingStyle.stroke..strokeWidth = 1.4;

    final path = Path();
    path.moveTo(center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx - radius * 0.9, center.dy + radius * 0.2, center.dx - radius * 0.6, center.dy - radius * 0.8);
    path.quadraticBezierTo(center.dx, center.dy - radius * 0.4, center.dx + radius * 0.6, center.dy - radius * 0.8);
    path.quadraticBezierTo(center.dx + radius * 0.9, center.dy + radius * 0.2, center.dx, center.dy + radius);
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  /// Sparkling 4-point star
  void _drawStarSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Small fallen leaf / petal drifting in air
  void _drawFallenPetal(Canvas canvas, Offset center, double radius, Color color, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, -radius);
    path.quadraticBezierTo(radius * 0.6, 0, 0, radius);
    path.quadraticBezierTo(-radius * 0.6, 0, 0, -radius);
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// Tiny decorative heart
  void _drawTinyHeart(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy + radius * 0.8);
    path.cubicTo(
      center.dx - radius,
      center.dy + radius * 0.2,
      center.dx - radius,
      center.dy - radius * 0.8,
      center.dx,
      center.dy - radius * 0.2,
    );
    path.cubicTo(
      center.dx + radius,
      center.dy - radius * 0.8,
      center.dx + radius,
      center.dy + radius * 0.2,
      center.dx,
      center.dy + radius * 0.8,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BotanicalPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.isDark != isDark ||
        oldDelegate.compactMode != compactMode ||
        oldDelegate.overrideColor != overrideColor;
  }
}

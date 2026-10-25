import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class AvatarOption {
  final String id;
  final String label;

  const AvatarOption({
    required this.id,
    required this.label,
  });
}

const profileAvatarOptions = [
  AvatarOption(id: 'initial', label: 'Name Initial'),
  AvatarOption(id: 'girl', label: 'Girl'),
  AvatarOption(id: 'boy', label: 'Boy'),
  AvatarOption(id: 'flower', label: 'Flower'),
  AvatarOption(id: 'dog', label: 'Dog'),
  AvatarOption(id: 'cat', label: 'Cat'),
  AvatarOption(id: 'bunny', label: 'Bunny'),
  AvatarOption(id: 'panda', label: 'Panda'),
  AvatarOption(id: 'fox', label: 'Fox'),
  AvatarOption(id: 'bear', label: 'Bear'),
  AvatarOption(id: 'koala', label: 'Koala'),
  AvatarOption(id: 'lion', label: 'Lion'),
  AvatarOption(id: 'penguin', label: 'Penguin'),
  AvatarOption(id: 'whale', label: 'Whale'),
  AvatarOption(id: 'frog', label: 'Frog'),
  AvatarOption(id: 'mushroom', label: 'Mushroom'),
];

String resolveAvatarId(String id) {
  final lower = id.toLowerCase().trim();
  if (lower == 'initial' || lower.isEmpty) return 'initial';
  if (lower == 'girl' || lower == 'berry_face') return 'girl';
  if (lower == 'boy' || lower == 'mint_smile' || lower == 'mint_sun') return 'boy';
  if (lower == 'leaves' || lower == 'mint_leaf') return 'leaves';
  if (lower == 'flower' || lower == 'rose_flower' || lower == 'berry_rose') return 'flower';
  if (lower == 'dog' || lower == 'berry_dog' || lower == 'sage_pet') return 'dog';
  if (lower == 'cat' || lower == 'kitty' || lower == 'berry_cat') return 'cat';
  if (lower == 'bunny' || lower == 'rabbit') return 'bunny';
  if (lower == 'panda') return 'panda';
  if (lower == 'fox') return 'fox';
  if (lower == 'bear') return 'bear';
  if (lower == 'koala') return 'koala';
  if (lower == 'lion') return 'lion';
  if (lower == 'penguin') return 'penguin';
  if (lower == 'whale' || lower == 'dolphin') return 'whale';
  if (lower == 'frog') return 'frog';
  if (lower == 'mushroom' || lower == 'plum_star' || lower == 'deep_crown') return 'mushroom';
  return lower;
}

Widget buildAvatarGraphic(String id, double size, {String fallbackName = ''}) {
  final canonicalId = resolveAvatarId(id);
  CustomPainter painter;

  switch (canonicalId) {
    case 'girl':
      painter = const GirlAvatarPainter();
      break;
    case 'boy':
      painter = const BoyAvatarPainter();
      break;
    case 'leaves':
      painter = const LeavesAvatarPainter();
      break;
    case 'flower':
      painter = const FlowerAvatarPainter();
      break;
    case 'dog':
      painter = const DogAvatarPainter();
      break;
    case 'cat':
      painter = const CatAvatarPainter();
      break;
    case 'bunny':
      painter = const BunnyAvatarPainter();
      break;
    case 'panda':
      painter = const PandaAvatarPainter();
      break;
    case 'fox':
      painter = const FoxAvatarPainter();
      break;
    case 'bear':
      painter = const BearAvatarPainter();
      break;
    case 'koala':
      painter = const KoalaAvatarPainter();
      break;
    case 'lion':
      painter = const LionAvatarPainter();
      break;
    case 'penguin':
      painter = const PenguinAvatarPainter();
      break;
    case 'whale':
      painter = const WhaleAvatarPainter();
      break;
    case 'frog':
      painter = const FrogAvatarPainter();
      break;
    case 'mushroom':
      painter = const MushroomAvatarPainter();
      break;
    default:
      return _buildFallbackAvatar(fallbackName, size);
  }

  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: painter),
  );
}

Widget _buildFallbackAvatar(String name, double size) {
  final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';
  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _FallbackAvatarPainter(initial: initial),
    ),
  );
}

class ProfileAvatar extends StatelessWidget {
  final String avatarId;
  final String name;
  final double radius;
  final bool showOuterRing;
  final Color? ringColor;

  const ProfileAvatar({
    super.key,
    required this.avatarId,
    required this.name,
    this.radius = 45,
    this.showOuterRing = false,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final graphic = buildAvatarGraphic(avatarId, size, fallbackName: name);

    if (!showOuterRing) {
      return graphic;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor ?? Colors.white.withAlpha(60),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBerry.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: graphic,
    );
  }
}

// ================= 1. GIRL AVATAR =================
class GirlAvatarPainter extends CustomPainter {
  const GirlAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.softBerryPink);

    // Hair Buns
    final bunPaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.18, h * 0.30), w * 0.16, bunPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.30), w * 0.16, bunPaint);

    // Hair base and bangs
    final hairPath = Path()
      ..moveTo(-w * 0.05, h * 0.40)
      ..quadraticBezierTo(w * 0.20, h * 0.05, w * 0.50, h * 0.05)
      ..quadraticBezierTo(w * 0.80, h * 0.05, w * 1.05, h * 0.40)
      ..quadraticBezierTo(w * 0.78, h * 0.26, w * 0.50, h * 0.38)
      ..quadraticBezierTo(w * 0.22, h * 0.26, -w * 0.05, h * 0.40)
      ..close();
    canvas.drawPath(hairPath, bunPaint);

    // Hair flower clip
    canvas.drawCircle(Offset(w * 0.28, h * 0.26), w * 0.065, Paint()..color = AppColors.berryRose);
    canvas.drawCircle(Offset(w * 0.28, h * 0.26), w * 0.025, Paint()..color = AppColors.mintLight);

    // Blushing cheeks
    final blushPaint = Paint()..color = AppColors.berryRose.withAlpha(120);
    canvas.drawCircle(Offset(w * 0.24, h * 0.65), w * 0.08, blushPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.65), w * 0.08, blushPaint);

    // Expressive eyes
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.36, h * 0.52), w * 0.075, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.52), w * 0.075, eyePaint);

    // White reflection dots
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.34, h * 0.495), w * 0.026, whitePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.495), w * 0.026, whitePaint);

    // Quirky eyelashes
    final lashPaint = Paint()
      ..color = AppColors.deepBerry
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.28, h * 0.44), Offset(w * 0.22, h * 0.38), lashPaint);
    canvas.drawLine(Offset(w * 0.36, h * 0.42), Offset(w * 0.36, h * 0.35), lashPaint);
    canvas.drawLine(Offset(w * 0.64, h * 0.42), Offset(w * 0.64, h * 0.35), lashPaint);
    canvas.drawLine(Offset(w * 0.72, h * 0.44), Offset(w * 0.78, h * 0.38), lashPaint);

    // Mouth with tongue and tooth
    final mouthRect = Rect.fromLTWH(w * 0.38, h * 0.66, w * 0.24, h * 0.19);
    final mouthPath = Path()
      ..moveTo(mouthRect.left, mouthRect.top)
      ..lineTo(mouthRect.right, mouthRect.top)
      ..arcTo(mouthRect, 0, 3.14159, false)
      ..close();
    canvas.drawPath(mouthPath, eyePaint);

    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(Offset(w * 0.50, h * 0.80), w * 0.10, Paint()..color = AppColors.berryRose);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.44, mouthRect.top, w * 0.12, h * 0.045), const Radius.circular(2)),
      whitePaint,
    );
    canvas.restore();

    // Outer border ring
    final ringPaint = Paint()
      ..color = AppColors.berryRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 2. BOY AVATAR =================
class BoyAvatarPainter extends CustomPainter {
  const BoyAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.mintLight);

    // Spiky cool hair tuft
    final hairPaint = Paint()..color = AppColors.deepBerry;
    final hair = Path()
      ..moveTo(w * 0.12, h * 0.40)
      ..lineTo(w * 0.20, h * 0.16)
      ..lineTo(w * 0.34, h * 0.26)
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.64, h * 0.24)
      ..lineTo(w * 0.78, h * 0.12)
      ..lineTo(w * 0.88, h * 0.40)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.12, h * 0.40)
      ..close();
    canvas.drawPath(hair, hairPaint);

    // Bold eyebrows
    final browPaint = Paint()
      ..color = AppColors.deepBerry
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.26, h * 0.44), Offset(w * 0.44, h * 0.47), browPaint);
    canvas.drawLine(Offset(w * 0.56, h * 0.47), Offset(w * 0.74, h * 0.44), browPaint);

    // Eyes
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.35, h * 0.56), w * 0.075, eyePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.56), w * 0.075, eyePaint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.33, h * 0.53), w * 0.026, whitePaint);
    canvas.drawCircle(Offset(w * 0.63, h * 0.53), w * 0.026, whitePaint);

    // Blush
    final blushPaint = Paint()..color = AppColors.berryRose.withAlpha(90);
    canvas.drawCircle(Offset(w * 0.24, h * 0.66), w * 0.07, blushPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.66), w * 0.07, blushPaint);

    // Smirking mouth with tongue
    final mouthRect = Rect.fromLTWH(w * 0.36, h * 0.68, w * 0.28, h * 0.17);
    final mouth = Path()
      ..moveTo(mouthRect.left, mouthRect.top)
      ..quadraticBezierTo(w * 0.50, h * 0.73, mouthRect.right, mouthRect.top)
      ..arcTo(mouthRect, 0, 3.14159, false)
      ..close();
    canvas.drawPath(mouth, eyePaint);

    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawCircle(Offset(w * 0.50, h * 0.80), w * 0.10, Paint()..color = AppColors.berryRose);
    canvas.restore();

    // Outer border ring
    final ringPaint = Paint()
      ..color = AppColors.deepBerry
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 3. LEAVES AVATAR =================
class LeavesAvatarPainter extends CustomPainter {
  const LeavesAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.mintLight);

    // Side companion leaf
    final leaf2 = Path()
      ..moveTo(w * 0.32, h * 0.78)
      ..quadraticBezierTo(w * 0.04, h * 0.60, w * 0.14, h * 0.34)
      ..quadraticBezierTo(w * 0.38, h * 0.36, w * 0.42, h * 0.65)
      ..close();
    canvas.drawPath(leaf2, Paint()..color = AppColors.sageGreen);

    // Main central mint leaf
    final leaf1 = Path()
      ..moveTo(w * 0.50, h * 0.90)
      ..quadraticBezierTo(w * 0.14, h * 0.68, w * 0.28, h * 0.24)
      ..quadraticBezierTo(w * 0.50, h * 0.10, w * 0.72, h * 0.24)
      ..quadraticBezierTo(w * 0.86, h * 0.68, w * 0.50, h * 0.90)
      ..close();
    canvas.drawPath(leaf1, Paint()..color = AppColors.mintGreen);

    // Stem Vein
    final stem = Path()
      ..moveTo(w * 0.50, h * 0.90)
      ..quadraticBezierTo(w * 0.49, h * 0.55, w * 0.50, h * 0.16);
    canvas.drawPath(
      stem,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round,
    );

    // Face
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.40, h * 0.46), w * 0.065, eyePaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.46), w * 0.065, eyePaint);

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.38, h * 0.44), w * 0.022, whitePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.44), w * 0.022, whitePaint);

    final blush = Paint()..color = AppColors.softBerryPink.withAlpha(180);
    canvas.drawCircle(Offset(w * 0.31, h * 0.56), w * 0.06, blush);
    canvas.drawCircle(Offset(w * 0.69, h * 0.56), w * 0.06, blush);

    final mouthRect = Rect.fromLTWH(w * 0.44, h * 0.55, w * 0.14, h * 0.12);
    final mouth = Path()
      ..moveTo(mouthRect.left, mouthRect.top)
      ..arcTo(mouthRect, 0, 3.14159, false)
      ..close();
    canvas.drawPath(mouth, eyePaint);

    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawCircle(Offset(w * 0.51, h * 0.63), w * 0.06, Paint()..color = AppColors.berryRose);
    canvas.restore();

    // Outer border ring
    final ringPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 4. FLOWER AVATAR =================
class FlowerAvatarPainter extends CustomPainter {
  const FlowerAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.softBerryPink);

    // 6 large round flower petals
    final petalPaint = Paint()..color = AppColors.berryRose;
    const count = 6;
    for (int i = 0; i < count; i++) {
      final angle = (i * (2 * 3.14159265 / count)) + 0.523;
      final petalCenter = Offset(center.dx + (r * 0.48) * cos(angle), center.dy + (r * 0.48) * sin(angle));
      canvas.drawCircle(petalCenter, r * 0.36, petalPaint);
    }

    // Flower Center Disk
    final diskPaint = Paint()..color = AppColors.mintLight;
    canvas.drawCircle(center, r * 0.46, diskPaint);
    canvas.drawCircle(
      center,
      r * 0.46,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028,
    );

    // Face in flower center
    final eyePaint = Paint()..color = AppColors.deepBerry;
    final winkPath = Path()
      ..moveTo(w * 0.34, h * 0.46)
      ..quadraticBezierTo(w * 0.40, h * 0.41, w * 0.46, h * 0.46);
    canvas.drawPath(
      winkPath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(w * 0.60, h * 0.45), w * 0.065, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.43), w * 0.022, Paint()..color = Colors.white);

    final blush = Paint()..color = AppColors.berryRose.withAlpha(120);
    canvas.drawCircle(Offset(w * 0.31, h * 0.54), w * 0.055, blush);
    canvas.drawCircle(Offset(w * 0.69, h * 0.54), w * 0.055, blush);

    final mouthRect = Rect.fromLTWH(w * 0.41, h * 0.53, w * 0.20, h * 0.16);
    final mouth = Path()
      ..moveTo(mouthRect.left, mouthRect.top)
      ..arcTo(mouthRect, 0, 3.14159, false)
      ..close();
    canvas.drawPath(mouth, eyePaint);

    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawCircle(Offset(w * 0.51, h * 0.64), w * 0.08, Paint()..color = AppColors.berryRose);
    canvas.restore();

    // Outer border ring
    final ringPaint = Paint()
      ..color = AppColors.berryBurgundy
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 5. DOG AVATAR =================
class DogAvatarPainter extends CustomPainter {
  const DogAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.berryBlush);

    // Dog Head base shape
    final headPath = Path()
      ..moveTo(w * 0.05, h * 0.85)
      ..quadraticBezierTo(w * 0.10, h * 0.25, w * 0.55, h * 0.20)
      ..quadraticBezierTo(w * 0.95, h * 0.30, w * 0.95, h * 0.65)
      ..quadraticBezierTo(w * 0.85, h * 0.95, w * 0.35, h * 0.95)
      ..close();
    canvas.drawPath(headPath, Paint()..color = AppColors.softBerryPink);

    // Floppy Ear on Left
    final earPath = Path()
      ..moveTo(w * 0.12, h * 0.32)
      ..lineTo(w * 0.04, h * 0.56)
      ..lineTo(w * 0.26, h * 0.48)
      ..close();
    canvas.drawPath(earPath, Paint()..color = AppColors.deepBerry);

    // Quirky Eye with eye ring patch
    canvas.drawCircle(Offset(w * 0.42, h * 0.40), w * 0.11, Paint()..color = AppColors.berryRose.withAlpha(80));
    canvas.drawCircle(Offset(w * 0.42, h * 0.40), w * 0.065, Paint()..color = AppColors.deepBerry);
    canvas.drawCircle(Offset(w * 0.40, h * 0.38), w * 0.022, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.42, h * 0.25), w * 0.035, Paint()..color = AppColors.deepBerry);

    // Nose
    final nosePath = Path()
      ..moveTo(w * 0.72, h * 0.38)
      ..lineTo(w * 0.82, h * 0.44)
      ..lineTo(w * 0.72, h * 0.48)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = AppColors.berryRose);

    // Open Barking Mouth
    final mouthPath = Path()
      ..moveTo(w * 0.54, h * 0.54)
      ..quadraticBezierTo(w * 0.88, h * 0.48, w * 0.94, h * 0.52)
      ..quadraticBezierTo(w * 0.90, h * 0.74, w * 0.58, h * 0.84)
      ..quadraticBezierTo(w * 0.44, h * 0.70, w * 0.54, h * 0.54)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = AppColors.deepBerry);

    // Teeth and Tongue
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(Offset(w * 0.76, h * 0.52), w * 0.03, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.84, h * 0.52), w * 0.03, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.66, h * 0.76), w * 0.11, Paint()..color = AppColors.berryRose);
    canvas.restore();

    // Outer border ring
    final ringPaint = Paint()
      ..color = AppColors.berryRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 6. MUSHROOM AVATAR =================
class MushroomAvatarPainter extends CustomPainter {
  const MushroomAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.softBerryPink);

    // Stem
    final stemPath = Path()
      ..moveTo(w * 0.36, h * 0.48)
      ..lineTo(w * 0.32, h * 0.88)
      ..quadraticBezierTo(w * 0.50, h * 0.94, w * 0.68, h * 0.88)
      ..lineTo(w * 0.64, h * 0.48)
      ..close();
    canvas.drawPath(stemPath, Paint()..color = AppColors.mintLight);
    canvas.drawPath(
      stemPath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025,
    );

    // Grass at base
    final grass = Path()
      ..moveTo(w * 0.22, h * 0.92)
      ..lineTo(w * 0.30, h * 0.78)
      ..lineTo(w * 0.36, h * 0.90)
      ..lineTo(w * 0.66, h * 0.90)
      ..lineTo(w * 0.74, h * 0.76)
      ..lineTo(w * 0.80, h * 0.92)
      ..close();
    canvas.drawPath(grass, Paint()..color = AppColors.sageGreen);

    // Mushroom Cap
    final capRect = Rect.fromLTWH(w * 0.12, h * 0.15, w * 0.76, h * 0.44);
    final capPath = Path()
      ..moveTo(capRect.left, capRect.bottom)
      ..arcTo(capRect, 3.14159, 3.14159, false)
      ..close();
    canvas.drawPath(capPath, Paint()..color = AppColors.berryRose);
    canvas.drawPath(
      capPath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028,
    );

    // Spots on Cap
    final spotPaint = Paint()..color = AppColors.mintLight;
    canvas.drawCircle(Offset(w * 0.32, h * 0.32), w * 0.07, spotPaint);
    canvas.drawCircle(Offset(w * 0.54, h * 0.24), w * 0.08, spotPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.34), w * 0.06, spotPaint);

    // Face on Stem
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.43, h * 0.62), w * 0.045, eyePaint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.62), w * 0.045, eyePaint);
    canvas.drawCircle(Offset(w * 0.42, h * 0.60), w * 0.016, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.56, h * 0.60), w * 0.016, Paint()..color = Colors.white);

    // Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(140);
    canvas.drawCircle(Offset(w * 0.36, h * 0.69), w * 0.04, blush);
    canvas.drawCircle(Offset(w * 0.64, h * 0.69), w * 0.04, blush);

    // Smile
    final smilePath = Path()
      ..moveTo(w * 0.46, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.54, h * 0.68);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );

    // Outer border ring
    final ringPaint = Paint()
      ..color = AppColors.deepBerry
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 7. CAT AVATAR =================
class CatAvatarPainter extends CustomPainter {
  const CatAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.softBerryPink.withAlpha(160));

    // Cat Ears (Triangles with inner pink)
    final earPaint = Paint()..color = const Color(0xFFFFF7ED);
    final innerEarPaint = Paint()..color = AppColors.berryRose;

    // Left Ear
    final leftEar = Path()
      ..moveTo(w * 0.20, h * 0.44)
      ..lineTo(w * 0.14, h * 0.16)
      ..lineTo(w * 0.42, h * 0.26)
      ..close();
    canvas.drawPath(leftEar, earPaint);

    final innerLeftEar = Path()
      ..moveTo(w * 0.22, h * 0.40)
      ..lineTo(w * 0.18, h * 0.21)
      ..lineTo(w * 0.38, h * 0.28)
      ..close();
    canvas.drawPath(innerLeftEar, innerEarPaint);

    // Right Ear
    final rightEar = Path()
      ..moveTo(w * 0.80, h * 0.44)
      ..lineTo(w * 0.86, h * 0.16)
      ..lineTo(w * 0.58, h * 0.26)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    final innerRightEar = Path()
      ..moveTo(w * 0.78, h * 0.40)
      ..lineTo(w * 0.82, h * 0.21)
      ..lineTo(w * 0.62, h * 0.28)
      ..close();
    canvas.drawPath(innerRightEar, innerEarPaint);

    // Head Base
    final headRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.56), width: w * 0.70, height: h * 0.58);
    canvas.drawOval(headRect, earPaint);

    // Eyes
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.38, h * 0.52), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.52), w * 0.055, eyePaint);
    // Eye Sparkles
    canvas.drawCircle(Offset(w * 0.36, h * 0.50), w * 0.020, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.60, h * 0.50), w * 0.020, Paint()..color = Colors.white);

    // Nose (Pink triangle)
    final nosePath = Path()
      ..moveTo(w * 0.47, h * 0.58)
      ..lineTo(w * 0.53, h * 0.58)
      ..lineTo(w * 0.50, h * 0.62)
      ..close();
    canvas.drawPath(nosePath, innerEarPaint);

    // W-shaped Cat Mouth
    final mouthPath = Path()
      ..moveTo(w * 0.42, h * 0.64)
      ..quadraticBezierTo(w * 0.46, h * 0.68, w * 0.50, h * 0.63)
      ..quadraticBezierTo(w * 0.54, h * 0.68, w * 0.58, h * 0.64);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.030
        ..strokeCap = StrokeCap.round,
    );

    // Rosy Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(120);
    canvas.drawCircle(Offset(w * 0.27, h * 0.58), w * 0.055, blush);
    canvas.drawCircle(Offset(w * 0.73, h * 0.58), w * 0.055, blush);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = AppColors.deepBerry.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    // Left Whiskers
    canvas.drawLine(Offset(w * 0.16, h * 0.58), Offset(w * 0.28, h * 0.60), whiskerPaint);
    canvas.drawLine(Offset(w * 0.16, h * 0.66), Offset(w * 0.28, h * 0.65), whiskerPaint);
    // Right Whiskers
    canvas.drawLine(Offset(w * 0.84, h * 0.58), Offset(w * 0.72, h * 0.60), whiskerPaint);
    canvas.drawLine(Offset(w * 0.84, h * 0.66), Offset(w * 0.72, h * 0.65), whiskerPaint);

    // Border Ring
    final ringPaint = Paint()
      ..color = AppColors.berryRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 8. BUNNY AVATAR =================
class BunnyAvatarPainter extends CustomPainter {
  const BunnyAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.berryBlush);

    // Tall Bunny Ears
    final earPaint = Paint()..color = Colors.white;
    final innerEarPaint = Paint()..color = AppColors.softBerryPink;

    // Left Ear
    canvas.save();
    canvas.translate(w * 0.35, h * 0.26);
    canvas.rotate(-0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.44), Radius.circular(w * 0.09)), earPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.10, height: h * 0.34), Radius.circular(w * 0.05)), innerEarPaint);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(w * 0.65, h * 0.26);
    canvas.rotate(0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.44), Radius.circular(w * 0.09)), earPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.10, height: h * 0.34), Radius.circular(w * 0.05)), innerEarPaint);
    canvas.restore();

    // Bunny Head
    final headRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.62), width: w * 0.68, height: h * 0.54);
    canvas.drawOval(headRect, earPaint);

    // Eyes
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.38, h * 0.58), w * 0.052, eyePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.58), w * 0.052, eyePaint);
    // Sparkles
    canvas.drawCircle(Offset(w * 0.36, h * 0.56), w * 0.018, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.60, h * 0.56), w * 0.018, Paint()..color = Colors.white);

    // Heart/Triangle Nose
    final nosePath = Path()
      ..moveTo(w * 0.48, h * 0.64)
      ..lineTo(w * 0.52, h * 0.64)
      ..lineTo(w * 0.50, h * 0.67)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = AppColors.berryRose);

    // Smile & Tooth
    final smilePath = Path()
      ..moveTo(w * 0.43, h * 0.70)
      ..quadraticBezierTo(w * 0.47, h * 0.74, w * 0.50, h * 0.69)
      ..quadraticBezierTo(w * 0.53, h * 0.74, w * 0.57, h * 0.70);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );

    // Rosy Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(130);
    canvas.drawCircle(Offset(w * 0.28, h * 0.64), w * 0.050, blush);
    canvas.drawCircle(Offset(w * 0.72, h * 0.64), w * 0.050, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = AppColors.berryRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 9. PANDA AVATAR =================
class PandaAvatarPainter extends CustomPainter {
  const PandaAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.mintLight);

    final blackPaint = Paint()..color = AppColors.deepBerry;

    // Round Black Ears
    canvas.drawCircle(Offset(w * 0.22, h * 0.26), w * 0.14, blackPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.26), w * 0.14, blackPaint);

    // White Head Base
    final headRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.55), width: w * 0.74, height: h * 0.60);
    canvas.drawOval(headRect, Paint()..color = Colors.white);

    // Diagonal Black Eye Patches
    canvas.save();
    canvas.translate(w * 0.36, h * 0.50);
    canvas.rotate(-0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: h * 0.20), blackPaint);
    canvas.drawCircle(const Offset(0, -2), w * 0.040, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(1, -2), w * 0.018, blackPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(w * 0.64, h * 0.50);
    canvas.rotate(0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: h * 0.20), blackPaint);
    canvas.drawCircle(const Offset(0, -2), w * 0.040, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(-1, -2), w * 0.018, blackPaint);
    canvas.restore();

    // Nose
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.62), width: w * 0.10, height: h * 0.06), blackPaint);

    // Smile
    final smilePath = Path()
      ..moveTo(w * 0.44, h * 0.67)
      ..quadraticBezierTo(w * 0.50, h * 0.73, w * 0.56, h * 0.67);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.030
        ..strokeCap = StrokeCap.round,
    );

    // Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(110);
    canvas.drawCircle(Offset(w * 0.23, h * 0.60), w * 0.045, blush);
    canvas.drawCircle(Offset(w * 0.77, h * 0.60), w * 0.045, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 10. FOX AVATAR =================
class FoxAvatarPainter extends CustomPainter {
  const FoxAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFF3E0));

    final foxOrange = Paint()..color = const Color(0xFFE65100);
    final darkTips = Paint()..color = AppColors.deepBerry;

    // Ears
    final leftEar = Path()
      ..moveTo(w * 0.16, h * 0.42)
      ..lineTo(w * 0.18, h * 0.12)
      ..lineTo(w * 0.44, h * 0.28)
      ..close();
    canvas.drawPath(leftEar, foxOrange);

    final leftEarTip = Path()
      ..moveTo(w * 0.17, h * 0.24)
      ..lineTo(w * 0.18, h * 0.12)
      ..lineTo(w * 0.29, h * 0.19)
      ..close();
    canvas.drawPath(leftEarTip, darkTips);

    final rightEar = Path()
      ..moveTo(w * 0.84, h * 0.42)
      ..lineTo(w * 0.82, h * 0.12)
      ..lineTo(w * 0.56, h * 0.28)
      ..close();
    canvas.drawPath(rightEar, foxOrange);

    final rightEarTip = Path()
      ..moveTo(w * 0.83, h * 0.24)
      ..lineTo(w * 0.82, h * 0.12)
      ..lineTo(w * 0.71, h * 0.19)
      ..close();
    canvas.drawPath(rightEarTip, darkTips);

    // Fox Head Orange Base
    final headPath = Path()
      ..moveTo(w * 0.20, h * 0.35)
      ..quadraticBezierTo(w * 0.50, h * 0.24, w * 0.80, h * 0.35)
      ..quadraticBezierTo(w * 0.88, h * 0.58, w * 0.50, h * 0.84)
      ..quadraticBezierTo(w * 0.12, h * 0.58, w * 0.20, h * 0.35)
      ..close();
    canvas.drawPath(headPath, foxOrange);

    // White Cheek Tufts
    final whitePaint = Paint()..color = Colors.white;
    final leftCheek = Path()
      ..moveTo(w * 0.50, h * 0.84)
      ..quadraticBezierTo(w * 0.20, h * 0.68, w * 0.15, h * 0.54)
      ..quadraticBezierTo(w * 0.32, h * 0.48, w * 0.50, h * 0.65)
      ..close();
    canvas.drawPath(leftCheek, whitePaint);

    final rightCheek = Path()
      ..moveTo(w * 0.50, h * 0.84)
      ..quadraticBezierTo(w * 0.80, h * 0.68, w * 0.85, h * 0.54)
      ..quadraticBezierTo(w * 0.68, h * 0.48, w * 0.50, h * 0.65)
      ..close();
    canvas.drawPath(rightCheek, whitePaint);

    // Eyes (Happy Arching Winks)
    final eyeStroke = Paint()
      ..color = AppColors.deepBerry
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.040
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(w * 0.30, h * 0.53)
      ..quadraticBezierTo(w * 0.36, h * 0.48, w * 0.42, h * 0.53);
    canvas.drawPath(leftEye, eyeStroke);

    final rightEye = Path()
      ..moveTo(w * 0.58, h * 0.53)
      ..quadraticBezierTo(w * 0.64, h * 0.48, w * 0.70, h * 0.53);
    canvas.drawPath(rightEye, eyeStroke);

    // Nose
    canvas.drawCircle(Offset(w * 0.50, h * 0.78), w * 0.050, darkTips);

    // Border Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFD84315)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 11. BEAR AVATAR =================
class BearAvatarPainter extends CustomPainter {
  const BearAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFF3E0));

    final bearBrown = Paint()..color = const Color(0xFF8D6E63);
    final innerEar = Paint()..color = const Color(0xFFBCAAA4);

    // Ears
    canvas.drawCircle(Offset(w * 0.22, h * 0.30), w * 0.14, bearBrown);
    canvas.drawCircle(Offset(w * 0.22, h * 0.30), w * 0.075, innerEar);
    canvas.drawCircle(Offset(w * 0.78, h * 0.30), w * 0.14, bearBrown);
    canvas.drawCircle(Offset(w * 0.78, h * 0.30), w * 0.075, innerEar);

    // Head
    canvas.drawCircle(Offset(w * 0.50, h * 0.56), w * 0.36, bearBrown);

    // Cream Snout
    final muzzleRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.64), width: w * 0.34, height: h * 0.24);
    canvas.drawOval(muzzleRect, Paint()..color = const Color(0xFFEFEBE9));

    // Nose
    final darkBrown = Paint()..color = AppColors.deepBerry;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.58), width: w * 0.10, height: h * 0.065), darkBrown);

    // Smile
    final smilePath = Path()
      ..moveTo(w * 0.50, h * 0.62)
      ..lineTo(w * 0.50, h * 0.68)
      ..moveTo(w * 0.44, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.73, w * 0.56, h * 0.68);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.026
        ..strokeCap = StrokeCap.round,
    );

    // Eyes
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.048, darkBrown);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.048, darkBrown);
    canvas.drawCircle(Offset(w * 0.34, h * 0.46), w * 0.016, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.62, h * 0.46), w * 0.016, Paint()..color = Colors.white);

    // Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(120);
    canvas.drawCircle(Offset(w * 0.24, h * 0.58), w * 0.045, blush);
    canvas.drawCircle(Offset(w * 0.76, h * 0.58), w * 0.045, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 12. KOALA AVATAR =================
class KoalaAvatarPainter extends CustomPainter {
  const KoalaAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.sageGreen.withAlpha(100));

    final koalaGrey = Paint()..color = const Color(0xFFB0BEC5);
    final fluffyWhite = Paint()..color = Colors.white;

    // Big Fuzzy Ears
    canvas.drawCircle(Offset(w * 0.18, h * 0.32), w * 0.17, koalaGrey);
    canvas.drawCircle(Offset(w * 0.18, h * 0.32), w * 0.10, fluffyWhite);

    canvas.drawCircle(Offset(w * 0.82, h * 0.32), w * 0.17, koalaGrey);
    canvas.drawCircle(Offset(w * 0.82, h * 0.32), w * 0.10, fluffyWhite);

    // Head
    canvas.drawCircle(Offset(w * 0.50, h * 0.56), w * 0.36, koalaGrey);

    // Big Oval Dark Koala Nose
    final darkNose = Paint()..color = AppColors.deepBerry;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.58), width: w * 0.18, height: h * 0.22),
        Radius.circular(w * 0.09),
      ),
      darkNose,
    );

    // Eyes
    canvas.drawCircle(Offset(w * 0.32, h * 0.50), w * 0.042, darkNose);
    canvas.drawCircle(Offset(w * 0.68, h * 0.50), w * 0.042, darkNose);
    canvas.drawCircle(Offset(w * 0.30, h * 0.48), w * 0.015, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.66, h * 0.48), w * 0.015, Paint()..color = Colors.white);

    // Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(120);
    canvas.drawCircle(Offset(w * 0.24, h * 0.62), w * 0.045, blush);
    canvas.drawCircle(Offset(w * 0.76, h * 0.62), w * 0.045, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 13. LION AVATAR =================
class LionAvatarPainter extends CustomPainter {
  const LionAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFF8E1));

    // Fluffy Mane (Sun/Scallop Ring)
    final manePaint = Paint()..color = const Color(0xFFFFB74D);
    const count = 10;
    for (int i = 0; i < count; i++) {
      final angle = i * (2 * 3.14159265 / count);
      final p = Offset(center.dx + (r * 0.46) * cos(angle), (center.dy + (h * 0.04)) + (r * 0.46) * sin(angle));
      canvas.drawCircle(p, r * 0.26, manePaint);
    }

    // Cub Face
    final facePaint = Paint()..color = const Color(0xFFFFE082);
    canvas.drawCircle(Offset(w * 0.50, h * 0.54), w * 0.32, facePaint);

    // Ears
    canvas.drawCircle(Offset(w * 0.26, h * 0.34), w * 0.09, Paint()..color = const Color(0xFFFFB74D));
    canvas.drawCircle(Offset(w * 0.74, h * 0.34), w * 0.09, Paint()..color = const Color(0xFFFFB74D));
    canvas.drawCircle(Offset(w * 0.26, h * 0.34), w * 0.05, Paint()..color = const Color(0xFFFFE082));
    canvas.drawCircle(Offset(w * 0.74, h * 0.34), w * 0.05, Paint()..color = const Color(0xFFFFE082));

    // Eyes
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.39, h * 0.50), w * 0.045, eyePaint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.50), w * 0.045, eyePaint);
    canvas.drawCircle(Offset(w * 0.37, h * 0.48), w * 0.016, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.59, h * 0.48), w * 0.016, Paint()..color = Colors.white);

    // Snout
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.62), width: w * 0.22, height: h * 0.16), Paint()..color = Colors.white);

    // Pink Nose
    final nose = Path()
      ..moveTo(w * 0.46, h * 0.57)
      ..lineTo(w * 0.54, h * 0.57)
      ..lineTo(w * 0.50, h * 0.62)
      ..close();
    canvas.drawPath(nose, Paint()..color = AppColors.berryRose);

    // Smile
    final smilePath = Path()
      ..moveTo(w * 0.43, h * 0.66)
      ..quadraticBezierTo(w * 0.50, h * 0.71, w * 0.57, h * 0.66);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.026
        ..strokeCap = StrokeCap.round,
    );

    // Blush
    final blush = Paint()..color = AppColors.berryRose.withAlpha(120);
    canvas.drawCircle(Offset(w * 0.29, h * 0.58), w * 0.040, blush);
    canvas.drawCircle(Offset(w * 0.71, h * 0.58), w * 0.040, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFF57C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 14. PENGUIN AVATAR =================
class PenguinAvatarPainter extends CustomPainter {
  const PenguinAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFE0F2F1));

    // Penguin Black Body/Head
    final bodyPaint = Paint()..color = AppColors.deepBerry;
    final bodyPath = Path()
      ..moveTo(w * 0.20, h * 0.95)
      ..quadraticBezierTo(w * 0.14, h * 0.40, w * 0.50, h * 0.24)
      ..quadraticBezierTo(w * 0.86, h * 0.40, w * 0.80, h * 0.95)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // White Face & Belly Mask
    final bellyPaint = Paint()..color = Colors.white;
    final bellyPath = Path()
      ..moveTo(w * 0.50, h * 0.36)
      ..quadraticBezierTo(w * 0.32, h * 0.36, w * 0.28, h * 0.54)
      ..quadraticBezierTo(w * 0.26, h * 0.88, w * 0.50, h * 0.92)
      ..quadraticBezierTo(w * 0.74, h * 0.88, w * 0.72, h * 0.54)
      ..quadraticBezierTo(w * 0.68, h * 0.36, w * 0.50, h * 0.36)
      ..close();
    canvas.drawPath(bellyPath, bellyPaint);

    // Eyes (Sweet Happy Arching Eyes)
    final eyeStroke = Paint()
      ..color = AppColors.deepBerry
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(w * 0.34, h * 0.52)
      ..quadraticBezierTo(w * 0.40, h * 0.47, w * 0.45, h * 0.52);
    canvas.drawPath(leftEye, eyeStroke);

    final rightEye = Path()
      ..moveTo(w * 0.55, h * 0.52)
      ..quadraticBezierTo(w * 0.60, h * 0.47, w * 0.66, h * 0.52);
    canvas.drawPath(rightEye, eyeStroke);

    // Orange Beak (Inverted triangle)
    final beak = Path()
      ..moveTo(w * 0.44, h * 0.58)
      ..lineTo(w * 0.56, h * 0.58)
      ..lineTo(w * 0.50, h * 0.68)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF9800));

    // Rosy Pink Cheeks
    final blush = Paint()..color = AppColors.berryRose.withAlpha(140);
    canvas.drawCircle(Offset(w * 0.30, h * 0.62), w * 0.045, blush);
    canvas.drawCircle(Offset(w * 0.70, h * 0.62), w * 0.045, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF00897B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 15. WHALE AVATAR =================
class WhaleAvatarPainter extends CustomPainter {
  const WhaleAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFE0F7FA));

    // Water Spout Droplets on Top
    final spoutPaint = Paint()..color = const Color(0xFF00ACC1);
    canvas.drawCircle(Offset(w * 0.42, h * 0.22), w * 0.035, spoutPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.16), w * 0.040, spoutPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.22), w * 0.035, spoutPaint);

    final spoutLines = Path()
      ..moveTo(w * 0.48, h * 0.32)
      ..quadraticBezierTo(w * 0.42, h * 0.24, w * 0.42, h * 0.22)
      ..moveTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.50, h * 0.16)
      ..moveTo(w * 0.52, h * 0.32)
      ..quadraticBezierTo(w * 0.58, h * 0.24, w * 0.58, h * 0.22);
    canvas.drawPath(
      spoutLines,
      Paint()
        ..color = const Color(0xFF00ACC1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.024
        ..strokeCap = StrokeCap.round,
    );

    // Whale Body
    final whalePaint = Paint()..color = const Color(0xFF4DD0E1);
    final bodyPath = Path()
      ..moveTo(w * 0.12, h * 0.64)
      ..quadraticBezierTo(w * 0.18, h * 0.32, w * 0.62, h * 0.32)
      ..quadraticBezierTo(w * 0.88, h * 0.36, w * 0.88, h * 0.64)
      ..quadraticBezierTo(w * 0.84, h * 0.82, w * 0.48, h * 0.82)
      ..quadraticBezierTo(w * 0.22, h * 0.82, w * 0.12, h * 0.64)
      ..close();
    canvas.drawPath(bodyPath, whalePaint);

    // White Underbelly
    final bellyPaint = Paint()..color = Colors.white;
    final bellyPath = Path()
      ..moveTo(w * 0.24, h * 0.66)
      ..quadraticBezierTo(w * 0.48, h * 0.64, w * 0.74, h * 0.66)
      ..quadraticBezierTo(w * 0.68, h * 0.80, w * 0.48, h * 0.80)
      ..quadraticBezierTo(w * 0.30, h * 0.80, w * 0.24, h * 0.66)
      ..close();
    canvas.drawPath(bellyPath, bellyPaint);

    // Whale Eye
    final eyePaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.66, h * 0.52), w * 0.048, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.50), w * 0.016, Paint()..color = Colors.white);

    // Cheerful Smile
    final smilePath = Path()
      ..moveTo(w * 0.74, h * 0.58)
      ..quadraticBezierTo(w * 0.78, h * 0.66, w * 0.84, h * 0.62);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );

    // Pink Cheek
    final blush = Paint()..color = AppColors.berryRose.withAlpha(140);
    canvas.drawCircle(Offset(w * 0.58, h * 0.60), w * 0.045, blush);

    // Border Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF0097A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 16. FROG AVATAR =================
class FrogAvatarPainter extends CustomPainter {
  const FrogAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.mintLight);

    final frogGreen = Paint()..color = AppColors.sageGreen;

    // Big Bulbous Eyes on Top
    canvas.drawCircle(Offset(w * 0.32, h * 0.34), w * 0.16, frogGreen);
    canvas.drawCircle(Offset(w * 0.68, h * 0.34), w * 0.16, frogGreen);
    // Inner Eye Whites
    canvas.drawCircle(Offset(w * 0.32, h * 0.34), w * 0.11, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.68, h * 0.34), w * 0.11, Paint()..color = Colors.white);
    // Black Pupils & Catchlights
    final pupilPaint = Paint()..color = AppColors.deepBerry;
    canvas.drawCircle(Offset(w * 0.32, h * 0.34), w * 0.065, pupilPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.34), w * 0.065, pupilPaint);
    canvas.drawCircle(Offset(w * 0.30, h * 0.31), w * 0.022, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.66, h * 0.31), w * 0.022, Paint()..color = Colors.white);

    // Frog Head Base
    final headRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.60), width: w * 0.76, height: h * 0.54);
    canvas.drawOval(headRect, frogGreen);

    // Wide Happy Frog Smile
    final smilePath = Path()
      ..moveTo(w * 0.28, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.72, h * 0.58);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = AppColors.deepBerry
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.038
        ..strokeCap = StrokeCap.round,
    );

    // Rosy Pink Cheeks
    final blush = Paint()..color = AppColors.berryRose.withAlpha(140);
    canvas.drawCircle(Offset(w * 0.24, h * 0.54), w * 0.052, blush);
    canvas.drawCircle(Offset(w * 0.76, h * 0.54), w * 0.052, blush);

    // Tiny Nostril Dots
    canvas.drawCircle(Offset(w * 0.46, h * 0.52), w * 0.015, pupilPaint);
    canvas.drawCircle(Offset(w * 0.54, h * 0.52), w * 0.015, pupilPaint);

    // Border Ring
    final ringPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= FALLBACK LETTER AVATAR =================
class _FallbackAvatarPainter extends CustomPainter {
  final String initial;
  const _FallbackAvatarPainter({required this.initial});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.softBerryPink);

    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: AppColors.deepBerry,
          fontSize: r * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    final ringPaint = Paint()
      ..color = AppColors.berryRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(center, r - (r * 0.07), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _FallbackAvatarPainter oldDelegate) => oldDelegate.initial != initial;
}

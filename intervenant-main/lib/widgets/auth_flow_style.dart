import 'package:flutter/material.dart';
import 'package:intervenant/theme/app_theme_data.dart';

/// Marron / beige — aligné sur `AppThemeData` (connexion / inscription).
abstract final class AuthFlowPalette {
  static const Color brown = Color(0xFF8B5A3C);
  static const Color brownDark = Color(0xFF5C3A21);
  static const Color brownMid = Color(0xFF6F4A30);
  static const Color beigeLight = Color(0xFFF5E6D3);
  static const Color waveCream = Color(0xFFF2E4DD);
  static const Color brownOnButton = Color(0xFF5C3A21);

  /// Fond type maquette (bleu pastel).
  static const Color pastelBlue = Color(0xFFB3E5FC);
  static const Color pastelBlueSoft = Color(0xFFE1F5FE);
  static const Color cardShadow = Color(0x1A000000);
  static const Color pillBorder = Color(0xDE212121);
  static const Color signUpGreyFill = Color(0xFFE0E0E0);
}

/// Champs soulignés blancs (connexion / inscription).
abstract final class AuthFlowInputDecor {
  static const BorderSide lineWhite = BorderSide(color: Color(0xE6FFFFFF), width: 1.2);
  static const BorderSide lineFocused = BorderSide(color: Colors.white, width: 2);

  static InputDecoration underlineField({
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: const TextStyle(
        color: Color(0xCCFFFFFF),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffix,
      filled: false,
      border: const UnderlineInputBorder(borderSide: lineWhite),
      enabledBorder: const UnderlineInputBorder(borderSide: lineWhite),
      focusedBorder: const UnderlineInputBorder(borderSide: lineFocused),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red.shade200)),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade100, width: 2),
      ),
      errorStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.95),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        shadows: const [
          Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x44000000)),
        ],
      ),
      contentPadding: const EdgeInsets.only(bottom: 4, top: 8),
    );
  }

  static const BorderSide lineGrey = BorderSide(color: Color(0xFFBDBDBD), width: 1);
  static const BorderSide lineFocusedDark = BorderSide(color: Color(0xFF424242), width: 1.8);

  /// Champs soulignés sur carte blanche (texte foncé).
  static InputDecoration underlineFieldLight({
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      floatingLabelStyle: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffix,
      filled: false,
      border: const UnderlineInputBorder(borderSide: lineGrey),
      enabledBorder: const UnderlineInputBorder(borderSide: lineGrey),
      focusedBorder: const UnderlineInputBorder(borderSide: lineFocusedDark),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red.shade300)),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      errorStyle: TextStyle(
        color: Colors.red.shade700,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.only(bottom: 4, top: 8),
    );
  }
}

/// Vagues en bas (même rendu que l’écran connexion).
class AuthFlowBottomWavesPainter extends CustomPainter {
  AuthFlowBottomWavesPainter({required this.base});

  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final double w = size.width;

    final Path p1 = Path()
      ..moveTo(0, h * 0.58)
      ..cubicTo(w * 0.15, h * 0.48, w * 0.35, h * 0.72, w * 0.5, h * 0.55)
      ..cubicTo(w * 0.68, h * 0.38, w * 0.85, h * 0.52, w, h * 0.45)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p1, Paint()..color = AuthFlowPalette.beigeLight);

    final Path p2 = Path()
      ..moveTo(0, h * 0.68)
      ..cubicTo(w * 0.2, h * 0.58, w * 0.4, h * 0.82, w * 0.55, h * 0.62)
      ..cubicTo(w * 0.72, h * 0.42, w * 0.88, h * 0.58, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p2, Paint()..color = kSoftBackgroundLight.withValues(alpha: 0.96));

    final Path p3 = Path()
      ..moveTo(0, h * 0.78)
      ..cubicTo(w * 0.22, h * 0.72, w * 0.45, h * 0.92, w * 0.62, h * 0.74)
      ..cubicTo(w * 0.78, h * 0.58, w * 0.9, h * 0.68, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(p3, Paint()..color = Color.lerp(AuthFlowPalette.waveCream, base, 0.22)!);
  }

  @override
  bool shouldRepaint(covariant AuthFlowBottomWavesPainter oldDelegate) => oldDelegate.base != base;
}

/// Dégradé + vagues + [child] (contenu scrollable).
class AuthFlowBrownBackground extends StatelessWidget {
  const AuthFlowBrownBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AuthFlowPalette.brownDark.withValues(alpha: 0.95),
                AuthFlowPalette.brownMid,
                AuthFlowPalette.brown.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: AuthFlowBottomWavesPainter(base: AuthFlowPalette.brown),
          ),
        ),
        child,
      ],
    );
  }
}

/// Illustration plate centrée (canapé / ordinateur) — style maquette.
class AuthFlowLoginIllustration extends StatelessWidget {
  const AuthFlowLoginIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 24,
            top: 28,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 36,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuthFlowPalette.pastelBlueSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 200,
            height: 88,
            decoration: BoxDecoration(
              color: AuthFlowPalette.pastelBlueSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AuthFlowPalette.pillBorder.withValues(alpha: 0.12)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Icon(Icons.weekend_rounded, size: 42, color: Colors.blueGrey.shade300),
                ),
                Positioned(
                  right: 28,
                  bottom: 20,
                  child: Icon(Icons.laptop_mac_rounded, size: 36, color: Colors.blueGrey.shade600),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(Icons.eco_rounded, size: 22, color: Colors.green.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Décor coin supérieur droit (branche stylisée + pastilles).
class AuthFlowRegisterCornerArt extends StatelessWidget {
  const AuthFlowRegisterCornerArt({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -8,
            right: -4,
            child: CustomPaint(
              size: const Size(100, 90),
              painter: _BranchPainter(),
            ),
          ),
          Positioned(
            top: 8,
            right: 52,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AuthFlowPalette.pastelBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 32,
            right: 28,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AuthFlowPalette.pastelBlue.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = const Color(0xDD212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final Path main = Path()
      ..moveTo(size.width * 0.85, 4)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.15, size.width * 0.2, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.78, 0, size.height * 0.92);
    canvas.drawPath(main, stroke);

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.65, size.height * 0.22)
        ..quadraticBezierTo(size.width * 0.45, size.height * 0.35, size.width * 0.25, size.height * 0.32),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.55, size.height * 0.42)
        ..quadraticBezierTo(size.width * 0.38, size.height * 0.55, size.width * 0.18, size.height * 0.5),
      stroke,
    );

    final Paint leaf = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.72, 18), width: 14, height: 8), leaf);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.42, 38), width: 12, height: 7), leaf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bouton pilule bordure foncée (maquette).
class AuthFlowPillButton extends StatelessWidget {
  const AuthFlowPillButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: const Color(0xFF212121),
          side: const BorderSide(color: AuthFlowPalette.pillBorder, width: 1.2),
          shape: const StadiumBorder(),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.blueGrey.shade700,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

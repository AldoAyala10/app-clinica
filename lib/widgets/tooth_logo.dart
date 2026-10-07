import 'package:flutter/material.dart';

class ToothLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const ToothLogo({
    super.key,
    this.size = 110,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ToothPainter(),
      ),
    );
  }
}

class _ToothPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Main Outer Blue Stroke
    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF004EC2),
          Color(0xFF0066FF),
          Color(0xFF00B4D8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Inner Lighter Cyan Accent Stroke
    final innerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    // Draw main molar tooth contour
    final path = Path();
    // Top center dip of the tooth crown
    path.moveTo(w * 0.50, h * 0.28);
    // Left crown cusp
    path.cubicTo(
      w * 0.35, h * 0.12, // control 1
      w * 0.16, h * 0.22, // control 2
      w * 0.18, h * 0.44, // left side
    );
    // Left root curve down
    path.cubicTo(
      w * 0.20, h * 0.62,
      w * 0.26, h * 0.82,
      w * 0.36, h * 0.86, // left root tip
    );
    // Left root tip curving inward
    path.cubicTo(
      w * 0.42, h * 0.88,
      w * 0.44, h * 0.68,
      w * 0.50, h * 0.56, // bifurcation center
    );
    // Right root inner curve
    path.cubicTo(
      w * 0.56, h * 0.68,
      w * 0.58, h * 0.88,
      w * 0.64, h * 0.86, // right root tip
    );
    // Right root curve up
    path.cubicTo(
      w * 0.74, h * 0.82,
      w * 0.80, h * 0.62,
      w * 0.82, h * 0.44, // right side
    );
    // Right crown cusp
    path.cubicTo(
      w * 0.84, h * 0.22,
      w * 0.65, h * 0.12,
      w * 0.50, h * 0.28, // back to top center dip
    );

    canvas.drawPath(path, outerPaint);

    // Dynamic inner swoosh curve for modern dental clinic flair
    final innerPath = Path();
    innerPath.moveTo(w * 0.38, h * 0.38);
    innerPath.cubicTo(
      w * 0.48, h * 0.46,
      w * 0.56, h * 0.48,
      w * 0.62, h * 0.38,
    );
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

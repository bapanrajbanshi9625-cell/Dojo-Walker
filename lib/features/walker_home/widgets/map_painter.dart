import 'package:flutter/material.dart';

class WalkerMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = const Color(0xFFE7EEF5);

    canvas.drawRect(
      Offset.zero & size,
      background,
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;

    final smallRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * .72),
      Offset(size.width, size.height * .35),
      road,
    );

    canvas.drawLine(
      Offset(size.width * .15, 0),
      Offset(size.width * .68, size.height),
      road,
    );

    canvas.drawLine(
      Offset(0, size.height * .18),
      Offset(size.width, size.height * .85),
      smallRoad,
    );

    // ==========================================================
    // WALK ROUTE
    // ==========================================================

    final route = Paint()
      ..color = const Color(0xFFFF4B16)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(
      size.width * .16,
      size.height * .72,
    );

    path.cubicTo(
      size.width * .24,
      size.height * .62,
      size.width * .34,
      size.height * .70,
      size.width * .43,
      size.height * .55,
    );

    path.cubicTo(
      size.width * .50,
      size.height * .42,
      size.width * .60,
      size.height * .52,
      size.width * .67,
      size.height * .36,
    );

    path.cubicTo(
      size.width * .72,
      size.height * .28,
      size.width * .78,
      size.height * .31,
      size.width * .83,
      size.height * .21,
    );

    canvas.drawPath(path, route);

    // ==========================================================
    // BUILDINGS
    // ==========================================================

    final block = Paint()
      ..color = const Color(0xFFD4E1EC);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .04,
          size.height * .42,
          80,
          45,
        ),
        const Radius.circular(8),
      ),
      block,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .67,
          size.height * .07,
          75,
          42,
        ),
        const Radius.circular(8),
      ),
      block,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .72,
          size.height * .68,
          90,
          50,
        ),
        const Radius.circular(8),
      ),
      block,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

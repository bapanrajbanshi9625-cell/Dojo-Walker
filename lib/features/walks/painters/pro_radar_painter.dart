import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/walks_constants.dart';

class ProRadarPainter extends CustomPainter {
  final double rotation;

  ProRadarPainter({
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.min(size.width, size.height) * .44;

    final Paint rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = WalksConstants.radarGreen.withOpacity(.30);

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        radius * i / 4,
        rings,
      );
    }

    final Paint grid = Paint()
      ..color = WalksConstants.radarGreen.withOpacity(.20)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      grid,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      grid,
    );

    canvas.save();

    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final Path sweep = Path()
      ..moveTo(0, 0)
      ..lineTo(radius, 0)
      ..arcTo(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius,
        ),
        0,
        math.pi / 5,
        false,
      )
      ..close();

    final Paint sweepPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x7016A34A),
          Color(0x3016A34A),
          Color(0x0016A34A),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius,
        ),
      );

    canvas.drawPath(sweep, sweepPaint);

    final Paint sweepLine = Paint()
      ..color = WalksConstants.radarGreen.withOpacity(.95)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset.zero,
      Offset(radius, 0),
      sweepLine,
    );

    canvas.restore();

    final Paint outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = WalksConstants.radarGreen.withOpacity(.45);

    canvas.drawCircle(
      center,
      radius,
      outer,
    );
  }

  @override
  bool shouldRepaint(
    covariant ProRadarPainter oldDelegate,
  ) {
    return oldDelegate.rotation != rotation;
  }
}

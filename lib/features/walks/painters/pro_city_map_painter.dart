import 'dart:math' as math;

import 'package:flutter/material.dart';

class ProCityMapPainter extends CustomPainter {
  const ProCityMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Base map
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF2E7),
    );

    // River
    final Path river = Path()
      ..moveTo(size.width * .82, -20)
      ..cubicTo(
        size.width * .68,
        size.height * .18,
        size.width * .91,
        size.height * .38,
        size.width * .73,
        size.height * .58,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .76,
        size.width * .78,
        size.height * .91,
        size.width * .65,
        size.height + 20,
      )
      ..lineTo(size.width * .82, size.height + 20)
      ..cubicTo(
        size.width * .92,
        size.height * .90,
        size.width * .75,
        size.height * .76,
        size.width * .88,
        size.height * .56,
      )
      ..cubicTo(
        size.width + .02,
        size.height * .35,
        size.width * .78,
        size.height * .17,
        size.width * .94,
        -20,
      )
      ..close();

    canvas.drawPath(
      river,
      Paint()..color = const Color(0xFFC9E7EC),
    );

    // Parks
    final Paint park = Paint()
      ..color = const Color(0xFFCDE6C8);

    final List<Rect> parks = [
      Rect.fromLTWH(
        size.width * .03,
        size.height * .06,
        size.width * .22,
        size.height * .18,
      ),
      Rect.fromLTWH(
        size.width * .62,
        size.height * .04,
        size.width * .18,
        size.height * .15,
      ),
      Rect.fromLTWH(
        size.width * .05,
        size.height * .70,
        size.width * .22,
        size.height * .19,
      ),
      Rect.fromLTWH(
        size.width * .62,
        size.height * .72,
        size.width * .20,
        size.height * .17,
      ),
    ];

    for (final rect in parks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(10),
        ),
        park,
      );
    }

    // Main roads
    final Paint mainRoad = Paint()
      ..color = const Color(0xFFD1D5D6)
      ..strokeWidth = 17
      ..style = PaintingStyle.stroke;

    final Path road1 = Path()
      ..moveTo(-20, size.height * .42)
      ..cubicTo(
        size.width * .22,
        size.height * .35,
        size.width * .53,
        size.height * .55,
        size.width + 20,
        size.height * .39,
      );

    final Path road2 = Path()
      ..moveTo(size.width * .43, -20)
      ..cubicTo(
        size.width * .38,
        size.height * .30,
        size.width * .58,
        size.height * .66,
        size.width * .48,
        size.height + 20,
      );

    canvas.drawPath(road1, mainRoad);
    canvas.drawPath(road2, mainRoad);

    // Road center lines
    final Paint roadLine = Paint()
      ..color = Colors.white.withOpacity(.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(road1, roadLine);
    canvas.drawPath(road2, roadLine);

    // Small streets
    final Paint smallRoad = Paint()
      ..color = const Color(0xFFDCE1E1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 9; i++) {
      final double y = size.height * i / 9;

      canvas.drawLine(
        Offset(0, y),
        Offset(
          size.width,
          y + (i.isEven ? 8 : -6),
        ),
        smallRoad,
      );
    }

    for (int i = 1; i < 8; i++) {
      final double x = size.width * i / 8;

      canvas.drawLine(
        Offset(x, 0),
        Offset(
          x + (i.isEven ? 8 : -6),
          size.height,
        ),
        smallRoad,
      );
    }

    // Buildings
    final Paint building = Paint()
      ..color = const Color(0xFFFDFDFB);

    final Paint building2 = Paint()
      ..color = const Color(0xFFE3E7E4);

    final math.Random random = math.Random(27);

    for (int i = 0; i < 42; i++) {
      final double x =
          size.width * (.03 + random.nextDouble() * .88);

      final double y =
          size.height * (.04 + random.nextDouble() * .88);

      final double w = 8 + random.nextDouble() * 10;
      final double h = 5 + random.nextDouble() * 8;

      final Rect rect = Rect.fromLTWH(
        x,
        y,
        w,
        h,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(2),
        ),
        i.isEven ? building : building2,
      );
    }

    // Trees
    final Paint tree = Paint()
      ..color = const Color(0xFF69A96E);

    final List<Offset> treePoints = [
      Offset(size.width * .11, size.height * .14),
      Offset(size.width * .16, size.height * .18),
      Offset(size.width * .22, size.height * .12),
      Offset(size.width * .12, size.height * .80),
      Offset(size.width * .20, size.height * .84),
      Offset(size.width * .73, size.height * .12),
      Offset(size.width * .78, size.height * .17),
      Offset(size.width * .72, size.height * .81),
      Offset(size.width * .80, size.height * .84),
    ];

    for (final point in treePoints) {
      canvas.drawCircle(point, 4, tree);

      canvas.drawCircle(
        point,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = tree.withOpacity(.35),
      );
    }

    // Map blocks
    final Paint block = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = const Color(0xFFCAD3CD).withOpacity(.65);

    for (int i = 0; i < 12; i++) {
      final double x = size.width * i / 12;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 15, size.height),
        block,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant ProCityMapPainter oldDelegate,
  ) {
    return false;
  }
}

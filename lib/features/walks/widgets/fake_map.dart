import 'package:flutter/material.dart';

class FakeMap extends StatelessWidget {
  const FakeMap({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FakeMapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class FakeMapPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    paint
      ..color = Colors.white
      ..strokeWidth = 28;

    final road = Path()
      ..moveTo(
        -20,
        size.height * .72,
      )
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .35,
        size.width + 30,
        size.height * .52,
      );

    canvas.drawPath(
      road,
      paint,
    );

    paint
      ..color = const Color(0xFFD5E0D7)
      ..strokeWidth = 2;

    for (int i = 0; i < 7; i++) {
      final y = 30.0 + i * 36;

      canvas.drawLine(
        Offset(0, y),
        Offset(
          size.width,
          y + 20,
        ),
        paint,
      );
    }

    for (int i = 0; i < 6; i++) {
      final x = 25.0 + i * 70;

      canvas.drawLine(
        Offset(x, 0),
        Offset(
          x + 30,
          size.height,
        ),
        paint,
      );
    }

    paint
      ..color = const Color(0xFFB9D9BF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        size.width * .78,
        size.height * .23,
      ),
      42,
      paint,
    );

    canvas.drawCircle(
      Offset(
        size.width * .22,
        size.height * .78,
      ),
      32,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const MapMarker({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.20),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
        ),
      ),
    );
  }
}

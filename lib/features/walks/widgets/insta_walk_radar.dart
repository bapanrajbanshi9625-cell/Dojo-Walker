import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/walks_constants.dart';
import '../painters/pro_city_map_painter.dart';
import '../painters/pro_radar_painter.dart';

class InstaWalkRadar extends StatelessWidget {
  final Animation<double> animation;
  final bool dotVisible;
  final double dotX;
  final double dotY;

  const InstaWalkRadar({
    super.key,
    required this.animation,
    required this.dotVisible,
    required this.dotX,
    required this.dotY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3E8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(.85),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LiveDot(),
              SizedBox(width: 7),
              Text(
                'SEARCHING NEARBY',
                style: TextStyle(
                  color: Color(0xFF26352A),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 245,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(
                    painter: ProCityMapPainter(),
                  ),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ProRadarPainter(
                          rotation:
                              animation.value * math.pi * 2,
                        ),
                      );
                    },
                  ),
                  if (dotVisible)
                    _RadarDot(
                      x: dotX,
                      y: dotY,
                    ),
                  const Center(
                    child: _CenterLocationDot(),
                  ),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: _MapChip(
                      icon: Icons.map_outlined,
                      text: '3.5 KM AREA',
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    bottom: 10,
                    child: _MapChip(
                      icon: Icons.gps_fixed,
                      text: 'LIVE',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.radar_rounded,
                color: Color(0xFF35443A),
                size: 17,
              ),
              SizedBox(width: 6),
              Text(
                'Searching within 3.5 kilometre',
                style: TextStyle(
                  color: Color(0xFF35443A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: WalksConstants.radarGreen,
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MapChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF35443A),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF35443A),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarDot extends StatelessWidget {
  final double x;
  final double y;

  const _RadarDot({
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(x, y),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WalksConstants.radarGreen,
          boxShadow: [
            BoxShadow(
              color: WalksConstants.radarGreen.withOpacity(.75),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterLocationDot extends StatelessWidget {
  const _CenterLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: WalksConstants.radarGreen,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 7,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: WalksConstants.radarGreen,
          ),
        ),
      ),
    );
  }
}

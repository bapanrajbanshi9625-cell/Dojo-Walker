import 'package:flutter/material.dart';

class InstaWalkInfo extends StatelessWidget {
  const InstaWalkInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Search for available Insta Walk requests within '
          '3.5 kilometre of your service area.',
          style: TextStyle(
            color: Color(0xFF23404D),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Color(0xFF23404D),
                size: 19,
              ),
              SizedBox(width: 7),
              Text(
                'Search range: 3.5 kilometre',
                style: TextStyle(
                  color: Color(0xFF23404D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

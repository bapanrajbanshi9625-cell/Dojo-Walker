import 'package:flutter/material.dart';

class LiveLocationBadge extends StatelessWidget {
  const LiveLocationBadge({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.green,
            size: 10,
          ),
          SizedBox(width: 7),
          Text(
            'Live Location',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF27394A),
            ),
          ),
        ],
      ),
    );
  }
}

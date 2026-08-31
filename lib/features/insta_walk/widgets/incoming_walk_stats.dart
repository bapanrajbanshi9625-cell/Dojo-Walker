import 'package:flutter/material.dart';

class IncomingWalkStats extends StatelessWidget {
  const IncomingWalkStats({
    super.key,
    required this.distanceText,
    required this.etaText,
    required this.paymentText,
  });

  final String distanceText;
  final String etaText;
  final String paymentText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatBox(
            icon: Icons.location_on_rounded,
            value: distanceText,
            label: 'FROM YOU',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            icon: Icons.schedule_rounded,
            value: etaText,
            label: 'ARRIVAL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBox(
            icon: Icons.payments_rounded,
            value: paymentText,
            label: 'PAYMENT',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: const Color(0xFFF4511E),
            size: 19,
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class VerificationStatusCard extends StatelessWidget {
  const VerificationStatusCard({
    super.key,
    required this.isVerifying,
    required this.aadhaarVerified,
    required this.nameMatched,
    required this.dobMatched,
    required this.message,
  });

  final bool isVerifying;
  final bool aadhaarVerified;
  final bool nameMatched;
  final bool dobMatched;
  final String message;

  static const Color green = Color(0xFF16A34A);
  static const Color text = Color(0xFF263746);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: aadhaarVerified
            ? const Color(0xFFEAF7EF)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: aadhaarVerified
              ? green.withOpacity(.25)
              : Colors.orange.withOpacity(.20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (isVerifying)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.orange,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle_rounded,
                  color: green,
                  size: 22,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              ),
            ],
          ),

          if (aadhaarVerified && !isVerifying) ...[
            const SizedBox(height: 12),
            _row('Aadhaar', aadhaarVerified),
            const SizedBox(height: 6),
            _row('Name', nameMatched),
            const SizedBox(height: 6),
            _row('Date of Birth', dobMatched),
          ],
        ],
      ),
    );
  }

  Widget _row(String title, bool verified) {
    return Row(
      children: [
        Icon(
          verified
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: verified ? green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ),
        Text(
          verified ? 'MATCHED' : 'NOT MATCHED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: verified ? green : Colors.red,
          ),
        ),
      ],
    );
  }
}

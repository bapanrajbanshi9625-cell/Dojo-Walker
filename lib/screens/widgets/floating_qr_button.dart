import 'package:flutter/material.dart';

class FloatingQrButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingQrButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFFF4B16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: orange.withOpacity(.30),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 27,
              ),
              SizedBox(width: 10),
              Text(
                'Scan Owner QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

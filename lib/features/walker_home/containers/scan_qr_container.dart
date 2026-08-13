import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class ScanQrContainer extends StatelessWidget {
  final VoidCallback? onTap;

  const ScanQrContainer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton.icon(
        onPressed: onTap ??
            () {
              WalkerHomeFeatures.openScanner(context);
            },
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 27,
        ),
        label: const Text(
          'Scan Owner QR Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: WalkerHomeFeatures.orange,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor:
              WalkerHomeFeatures.orange.withOpacity(.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

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
    return Material(
      color: Colors.transparent,
      elevation: 7,
      shadowColor: WalkerHomeFeatures.orange.withOpacity(.28),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap ??
            () {
              WalkerHomeFeatures.openScanner(context);
            },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          decoration: BoxDecoration(
            color: WalkerHomeFeatures.orange,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 23,
              ),

              const SizedBox(width: 9),

              const Text(
                'Scan Owner QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

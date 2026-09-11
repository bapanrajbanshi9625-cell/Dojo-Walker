import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class AcceptWalkCallChat extends StatelessWidget {
  const AcceptWalkCallChat({
    super.key,
    required this.ownerPhone,
    required this.onChat,
  });

  final String ownerPhone;
  final VoidCallback onChat;

  Future<void> _callOwner() async {
    final phone = ownerPhone.trim();

    if (phone.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _callOwner,
              style: ElevatedButton.styleFrom(
                backgroundColor: DojoWalkerColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(
                Icons.call_rounded,
                size: 19,
              ),
              label: const Text(
                'Call',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: DojoWalkerColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 19,
              ),
              label: const Text(
                'Chat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

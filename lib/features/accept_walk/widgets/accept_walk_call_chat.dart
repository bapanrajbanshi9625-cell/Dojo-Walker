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

  Future<void> _callOwner(BuildContext context) async {
    final String phone = ownerPhone.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Owner phone number is unavailable.'),
          ),
        );
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    final bool canLaunch = await canLaunchUrl(uri);

    if (!canLaunch) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open phone dialer.'),
          ),
        );
      return;
    }

    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                _callOwner(context);
              },
              icon: const Icon(
                Icons.call_rounded,
                size: 19,
              ),
              label: const Text(
                'CALL',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DojoWalkerColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 19,
              ),
              label: const Text(
                'CHAT',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DojoWalkerColors.primary,
                side: BorderSide(
                  color: DojoWalkerColors.primary,
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

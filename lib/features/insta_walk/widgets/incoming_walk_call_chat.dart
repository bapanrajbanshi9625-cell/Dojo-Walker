import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IncomingWalkCallChat extends StatelessWidget {
  const IncomingWalkCall({
    super.key,
    required this.ownerPhone,
    this.onChat,
  });

  final String ownerPhone;
  final VoidCallback? onChat;

  Future<void> _callOwner(BuildContext context) async {
    final String phone = ownerPhone.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Owner phone number is not available.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool canLaunch =
          await canLaunchUrl(phoneUri);

      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to open phone dialer.',
                ),
                behavior:
                    SnackBarBehavior.floating,
              ),
            );
        }
        return;
      }

      await launchUrl(phoneUri);
    } catch (error) {
      debugPrint(
        'Owner call error: $error',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to open phone dialer.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  void _openChat(BuildContext context) {
    if (onChat != null) {
      onChat!();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Chat screen not found yet.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _callOwner(context),
              icon: const Icon(
                Icons.call_rounded,
                size: 20,
              ),
              label: const Text(
                'CALL OWNER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFFF4511E),
                side: const BorderSide(
                  color: Color(0xFFF4511E),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openChat(context),
              icon: const Icon(
                Icons.chat_bubble_rounded,
                size: 19,
              ),
              label: const Text(
                'CHAT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF17202A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

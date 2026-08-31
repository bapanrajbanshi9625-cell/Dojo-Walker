import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IncomingWalkCallChat extends StatelessWidget {
  const IncomingWalkCallChat({
    super.key,
    required this.ownerPhone,
    this.onChat,
  });

  final String ownerPhone;
  final VoidCallback? onChat;

  Future<void> _callOwner(
    BuildContext context,
  ) async {
    final String phone =
        ownerPhone.trim();

    if (phone.isEmpty) {
      _showMessage(
        context,
        'Owner phone number is not available.',
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
          _showMessage(
            context,
            'Unable to open phone dialer.',
          );
        }
        return;
      }

      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint(
        'Owner call error: $error',
      );

      if (context.mounted) {
        _showMessage(
          context,
          'Unable to open phone dialer.',
        );
      }
    }
  }

  void _openChat(
    BuildContext context,
  ) {
    if (onChat != null) {
      onChat!();
      return;
    }

    _showMessage(
      context,
      'Chat screen not found yet.',
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _callOwner(context),
              icon: const Icon(
                Icons.call_rounded,
                size: 20,
              ),
              label: const Text(
                'CALL OWNER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFFF4511E,
                ),
                side: const BorderSide(
                  color: Color(0xFFF4511E),
                  width: 1.3,
                ),
                shape:
                    RoundedRectangleBorder(
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
              onPressed: () =>
                  _openChat(context),
              icon: const Icon(
                Icons.chat_bubble_rounded,
                size: 19,
              ),
              label: const Text(
                'CHAT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF17202A,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
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

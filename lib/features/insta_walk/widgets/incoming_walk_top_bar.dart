import 'package:flutter/material.dart';

class IncomingWalkTopBar extends StatelessWidget {
  const IncomingWalkTopBar({
    super.key,
    required this.accepted,
    required this.onBack,
  });

  final bool accepted;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          0,
        ),
        child: Row(
          children: <Widget>[
            _circleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(25),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    accepted
                        ? Icons.check_circle_rounded
                        : Icons.notifications_active_rounded,
                    color: accepted
                        ? Colors.green
                        : const Color(0xFFF4511E),
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    accepted
                        ? 'WALK ACCEPTED'
                        : 'INCOMING WALK',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(
              icon,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

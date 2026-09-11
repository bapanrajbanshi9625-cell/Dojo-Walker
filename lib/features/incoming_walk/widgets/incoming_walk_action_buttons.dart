import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class IncomingWalkActionButtons extends StatelessWidget {
  const IncomingWalkActionButtons({
    super.key,
    required this.onAccept,
    required this.onReject,
    required this.accepting,
    required this.rejecting,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;

  final bool accepting;
  final bool rejecting;

  @override
  Widget build(BuildContext context) {
    final bool busy = accepting || rejecting;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : onReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(
                color: Colors.grey.shade400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: rejecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: busy ? null : onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: DojoWalkerColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: accepting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Accept Walk',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

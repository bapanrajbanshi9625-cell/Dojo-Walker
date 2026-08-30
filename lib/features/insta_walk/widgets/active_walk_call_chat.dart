import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkCallChat extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onChat;

  const ActiveWalkCallChat({
    super.key,
    required this.onCall,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ========================================================
        // CALL
        // ========================================================

        Expanded(
          flex: 6,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onCall,
              icon: const Icon(
                Icons.call_rounded,
                color: AppColors.buttonText,
                size: 19,
              ),
              label: const Text(
                'Call Owner',
                style: TextStyle(
                  color: AppColors.buttonText,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.buttonPrimary,
                foregroundColor:
                    AppColors.buttonText,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ========================================================
        // CHAT
        // ========================================================

        Expanded(
          flex: 5,
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.secondary,
                size: 19,
              ),
              label: const Text(
                'Chat',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.secondary,
                backgroundColor:
                    AppColors.cardBackground,
                side: const BorderSide(
                  color: AppColors.border,
                  width: 1.3,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

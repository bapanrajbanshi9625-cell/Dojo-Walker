import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

void showPendingVerificationSupport(
  BuildContext context,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: DojoWalkerColors.white,
    isScrollControlled: true,
    shape:
        const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (
      BuildContext sheetContext,
    ) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration:
                    BoxDecoration(
                  color: DojoWalkerColors.border,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 18),

              const Icon(
                Icons.support_agent_rounded,
                color: DojoWalkerColors.info,
                size: 44,
              ),

              const SizedBox(height: 10),

              const Text(
                'DOJO Support',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: DojoWalkerColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Need help with your verification? '
                'Our support team is here to help.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: DojoWalkerColors.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        DojoWalkerColors.info,
                    foregroundColor:
                        DojoWalkerColors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                  icon: const Icon(
                    Icons.chat_rounded,
                  ),
                  label: const Text(
                    'Open Support Chat',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

import '../constants/walks_constants.dart';

class InstaWalkSearchButton extends StatelessWidget {
  final bool loading;
  final bool searching;
  final VoidCallback onPressed;

  const InstaWalkSearchButton({
    super.key,
    required this.loading,
    required this.searching,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: WalksConstants.buttonBlue,
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: WalksConstants.buttonBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      WalksConstants.buttonBlue,
                    ),
                  ),
                )
              : searching
                  ? const Row(
                      key: ValueKey('searching'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              WalksConstants.buttonBlue,
                            ),
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Searching Insta Walk 🔍',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      key: ValueKey('normal'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Insta Walk Search',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

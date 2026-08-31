import 'package:flutter/material.dart';

class IncomingWalkActionButtons extends StatelessWidget {
  const IncomingWalkActionButtons({
    super.key,
    required this.onAccept,
    required this.onReject,
    this.accepting = false,
    this.rejecting = false,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;

  final bool accepting;
  final bool rejecting;

  @override
  Widget build(BuildContext context) {
    final bool disabled =
        accepting || rejecting;

    return Row(
      children: <Widget>[
        // ========================================================
        // REJECT
        // ========================================================

        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed:
                  disabled ? null : onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(
                  color: Colors.red,
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: rejecting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'REJECT',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ========================================================
        // ACCEPT
        // ========================================================

        Expanded(
          flex: 2,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
                  disabled ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF4511E),
                foregroundColor:
                    Colors.white,
                disabledBackgroundColor:
                    Colors.black12,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: accepting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.check_rounded,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ACCEPT WALK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

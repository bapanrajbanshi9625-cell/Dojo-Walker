import 'package:flutter/material.dart';

class IncomingWalkReachButton extends StatelessWidget {
  const IncomingWalkReachButton({
    super.key,
    required this.canReachOwner,
    required this.onReach,
    this.reaching = false,
  });

  final bool canReachOwner;
  final VoidCallback onReach;
  final bool reaching;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            canReachOwner && !reaching
                ? onReach
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFF4511E),
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              Colors.black12,
          disabledForegroundColor:
              Colors.black38,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: reaching
            ? const SizedBox(
                width: 23,
                height: 23,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    canReachOwner
                        ? Icons
                            .location_on_rounded
                        : Icons
                            .directions_walk_rounded,
                    size: 23,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    canReachOwner
                        ? 'REACHED OWNER'
                        : 'REACH OWNER',
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

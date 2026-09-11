import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class AcceptWalkReachButton extends StatefulWidget {
  const AcceptWalkReachButton({
    super.key,
    required this.canReachOwner,
    required this.reaching,
    required this.onReach,
  });

  final bool canReachOwner;
  final bool reaching;
  final VoidCallback onReach;

  @override
  State<AcceptWalkReachButton> createState() =>
      _AcceptWalkReachButtonState();
}

class _AcceptWalkReachButtonState
    extends State<AcceptWalkReachButton> {
  double _dragValue = 0;

  void _reset() {
    if (!mounted) {
      return;
    }

    setState(() {
      _dragValue = 0;
    });
  }

  void _complete() {
    if (!widget.canReachOwner || widget.reaching) {
      _reset();
      return;
    }

    setState(() {
      _dragValue = 1;
    });

    widget.onReach();
  }

  @override
  void didUpdateWidget(covariant AcceptWalkReachButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.canReachOwner && _dragValue != 0) {
      _dragValue = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.canReachOwner && !widget.reaching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled
                ? DojoWalkerColors.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPadding = 5.0;
              const thumbSize = 48.0;

              final availableWidth =
                  constraints.maxWidth -
                  (horizontalPadding * 2) -
                  thumbSize;

              final thumbLeft =
                  horizontalPadding +
                  (availableWidth * _dragValue);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 58,
                        right: 28,
                      ),
                      child: widget.reaching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              enabled
                                  ? 'SLIDE TO REACH OWNER'
                                  : 'WITHIN 100 m TO REACH',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: enabled
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                  if (!widget.reaching)
                    Positioned(
                      left: thumbLeft,
                      top: horizontalPadding,
                      child: GestureDetector(
                        onHorizontalDragUpdate: enabled
                            ? (details) {
                                if (availableWidth <= 0) {
                                  return;
                                }

                                final next =
                                    _dragValue +
                                    (details.delta.dx /
                                        availableWidth);

                                setState(() {
                                  _dragValue =
                                      next.clamp(0.0, 1.0);
                                });
                              }
                            : null,
                        onHorizontalDragEnd: enabled
                            ? (_) {
                                if (_dragValue >= 0.85) {
                                  _complete();
                                } else {
                                  _reset();
                                }
                              }
                            : null,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 7,
                                offset: const Offset(0, 2),
                                color: Colors.black.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: enabled
                                ? DojoWalkerColors.primary
                                : Colors.grey.shade500,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        if (!widget.canReachOwner && !widget.reaching)
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 5),
              Text(
                'Reach Owner becomes available within 100 m.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveWalkBottomSheet extends StatefulWidget {
  const LiveWalkBottomSheet({
    super.key,
    required this.ownerName,
    required this.dogName,
    this.dogBreed = '',
    this.ownerPhone,
    required this.sessionData,
    required this.ending,
    required this.onEndWalk,
  });

  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  final Map<String, dynamic> sessionData;

  final bool ending;
  final VoidCallback onEndWalk;

  @override
  State<LiveWalkBottomSheet> createState() =>
      _LiveWalkBottomSheetState();
}

class _LiveWalkBottomSheetState
    extends State<LiveWalkBottomSheet> {
  static const Color orange = Color(0xFFFF6600);
  static const Color dark = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);
  static const Color green = Color(0xFF16A34A);
  static const Color blue = Color(0xFF2563EB);
  static const Color red = Color(0xFFE53935);

  double _slideValue = 0;

  // ============================================================
  // DATA
  // ============================================================

  int get _steps {
    final dynamic value = widget.sessionData['steps'];
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get _peeCount {
    final dynamic value = widget.sessionData['peeCount'];
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get _poopCount {
    final dynamic value = widget.sessionData['poopCount'];
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get _distanceKm {
    final dynamic value =
        widget.sessionData['distanceKm'];

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String get _duration {
    final dynamic seconds =
        widget.sessionData['durationSeconds'];

    final int totalSeconds =
        int.tryParse(
              seconds?.toString() ?? '',
            ) ??
            0;

    if (totalSeconds <= 0) {
      return '00:00:00';
    }

    final int hours = totalSeconds ~/ 3600;
    final int minutes =
        (totalSeconds % 3600) ~/ 60;
    final int secs = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _callOwner() async {
    final String phone =
        widget.ownerPhone?.trim() ?? '';

    if (phone.isEmpty) {
      _showMessage('Owner phone number unavailable.');
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showMessage('Unable to open phone app.');
      }
    } catch (_) {
      _showMessage('Unable to make call.');
    }
  }

  // ============================================================
  // CHAT
  // ============================================================

  void _openChat() {
    // Keep navigation isolated here.
    //
    // Replace this with your existing chat route when available.
    _showMessage('Chat will open here.');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // SLIDER
  // ============================================================

  void _completeSlider() {
    if (widget.ending) return;

    if (_slideValue >= .96) {
      setState(() {
        _slideValue = 1;
      });

      widget.onEndWalk();
    } else {
      setState(() {
        _slideValue = 0;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            8,
            14,
            10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DADF),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // OWNER
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // PROFILE
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFE8DE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: orange
                            .withValues(alpha: .25),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: orange,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // NAME
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ownerName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: dark,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.dogBreed
                                  .trim()
                                  .isNotEmpty
                              ? '${widget.dogName} • '
                                  '${widget.dogBreed}'
                              : widget.dogName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 7),

                        // CALL + CHAT
                        Row(
                          children: [
                            _miniAction(
                              icon:
                                  Icons.call_rounded,
                              label: 'Call',
                              background:
                                  const Color(
                                0xFF111111,
                              ),
                              foreground:
                                  Colors.white,
                              onTap: _callOwner,
                            ),
                            const SizedBox(width: 7),
                            _miniAction(
                              icon:
                                  Icons.chat_bubble_rounded,
                              label: 'Chat',
                              background:
                                  const Color(
                                0xFFEAF1FF,
                              ),
                              foreground: blue,
                              onTap: _openChat,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 11),

              // ==================================================
              // STATS
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF7F8FA),
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        const Color(0xFFE7EAED),
                  ),
                ),
                child: Row(
                  children: [
                    _stat(
                      Icons.timer_outlined,
                      _duration,
                      'Duration',
                    ),
                    _divider(),
                    _stat(
                      Icons.route_rounded,
                      '${_distanceKm.toStringAsFixed(2)} km',
                      'Distance',
                    ),
                    _divider(),
                    _stat(
                      Icons.directions_walk_rounded,
                      '$_steps',
                      'Steps',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // ACTIVITY
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: _activity(
                      icon:
                          Icons.water_drop_outlined,
                      label: 'Pee',
                      value: _peeCount,
                      iconColor:
                          const Color(0xFFCA8A04),
                      background:
                          const Color(0xFFFFF8D8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _activity(
                      icon:
                          Icons.circle_outlined,
                      label: 'Poop',
                      value: _poopCount,
                      iconColor:
                          const Color(0xFF92400E),
                      background:
                          const Color(0xFFF7EDE4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              // ==================================================
              // SLIDE TO COMPLETE
              // ==================================================

              _completeSlider(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MINI ACTION
  // ============================================================

  Widget _miniAction({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 31,
      child: Material(
        color: background,
        borderRadius:
            BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(9),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: foreground,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat(
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: orange,
            size: 17,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 8,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 31,
      color: const Color(0xFFE0E4E8),
    );
  }

  // ============================================================
  // ACTIVITY
  // ============================================================

  Widget _activity({
    required IconData icon,
    required String label,
    required int value,
    required Color iconColor,
    required Color background,
  }) {
    return Container(
      height: 34,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            constraints:
                const BoxConstraints(
              minWidth: 22,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: .75),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETE SLIDER
  // ============================================================

  Widget _completeSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double height = 50;
        const double knob = 42;

        final double maxSlide =
            math.max(
          0,
          constraints.maxWidth - knob,
        );

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEE),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color:
                  red.withValues(alpha: .16),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // TEXT
              Center(
                child: Text(
                  widget.ending
                      ? 'Completing Walk...'
                      : 'SLIDE TO COMPLETE WALK',
                  style: const TextStyle(
                    color: red,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),

              // KNOB
              Positioned(
                left:
                    _slideValue * maxSlide,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      widget.ending
                          ? null
                          : (details) {
                              setState(() {
                                final double next =
                                    (_slideValue *
                                            maxSlide +
                                        details
                                            .delta
                                            .dx)
                                        .clamp(
                                  0.0,
                                  maxSlide,
                                );

                                _slideValue =
                                    maxSlide == 0
                                        ? 0
                                        : next /
                                            maxSlide;
                              });
                            },
                  onHorizontalDragEnd:
                      widget.ending
                          ? null
                          : (_) {
                              _completeSlider();
                            },
                  child: Container(
                    width: knob,
                    height: knob,
                    margin:
                        const EdgeInsets.only(
                      top: 4,
                    ),
                    decoration:
                        const BoxDecoration(
                      color: red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.ending
                          ? Icons.sync_rounded
                          : Icons
                              .arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

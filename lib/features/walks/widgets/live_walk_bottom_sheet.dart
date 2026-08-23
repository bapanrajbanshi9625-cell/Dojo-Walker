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
    this.sessionData = const <String, dynamic>{},
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
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color dark = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);
  static const Color blue = Color(0xFF2563EB);
  static const Color red = Color(0xFFE53935);

  double _slideValue = 0.0;

  // ============================================================
  // DATA HELPERS
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ============================================================
  // WALK DATA
  // ============================================================

  int get _steps {
    return _toInt(
      widget.sessionData['steps'],
    );
  }

  int get _peeCount {
    return _toInt(
      widget.sessionData['peeCount'],
    );
  }

  int get _poopCount {
    return _toInt(
      widget.sessionData['poopCount'],
    );
  }

  double get _distanceKm {
    return _toDouble(
      widget.sessionData['distanceKm'],
    );
  }

  int get _durationSeconds {
    final dynamic value =
        widget.sessionData['durationSeconds'];

    return _toInt(value);
  }

  String get _duration {
    final int totalSeconds =
        _durationSeconds;

    if (totalSeconds <= 0) {
      return '00:00:00';
    }

    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // CALL OWNER
  // ============================================================

  Future<void> _callOwner() async {
    final String phone =
        widget.ownerPhone?.trim() ?? '';

    if (phone.isEmpty) {
      _showMessage(
        'Owner phone number unavailable.',
      );
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool canCall =
          await canLaunchUrl(uri);

      if (!canCall) {
        _showMessage(
          'Unable to open phone app.',
        );
        return;
      }

      await launchUrl(uri);
    } catch (_) {
      _showMessage(
        'Unable to make call.',
      );
    }
  }

  // ============================================================
  // CHAT
  // ============================================================

  void _openChat() {
    // Keep chat navigation isolated.
    //
    // Connect your existing chat screen/route here.
    _showMessage(
      'Chat will open here.',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // SLIDER COMPLETE
  // ============================================================

  void _handleSliderEnd() {
    if (widget.ending) {
      return;
    }

    if (_slideValue >= 0.96) {
      setState(() {
        _slideValue = 1.0;
      });

      // IMPORTANT:
      // Do not call _completeSlider() here.
      // Directly trigger parent's end callback.
      widget.onEndWalk();
      return;
    }

    setState(() {
      _slideValue = 0.0;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(22),
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
          padding:
              const EdgeInsets.fromLTRB(
            14,
            7,
            14,
            8,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              // =================================================
              // HANDLE
              // =================================================

              Container(
                width: 38,
                height: 4,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFD6DADF),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              const SizedBox(height: 9),

              // =================================================
              // OWNER INFO
              // =================================================

              _buildOwnerSection(),

              const SizedBox(height: 9),

              // =================================================
              // WALK STATS
              // =================================================

              _buildStats(),

              const SizedBox(height: 7),

              // =================================================
              // PEE / POOP
              // =================================================

              _buildActivities(),

              const SizedBox(height: 8),

              // =================================================
              // COMPLETE WALK
              // =================================================

              _buildCompleteSlider(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OWNER SECTION
  // ============================================================

  Widget _buildOwnerSection() {
    final String breed =
        widget.dogBreed.trim();

    final String dogInfo =
        breed.isNotEmpty
            ? '${widget.dogName} • $breed'
            : widget.dogName;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // PROFILE
        // ------------------------------------------------------

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                const Color(0xFFFFE8DE),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  orange.withOpacity(0.25),
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: orange,
            size: 25,
          ),
        ),

        const SizedBox(width: 10),

        // ------------------------------------------------------
        // NAME + DOG + ACTIONS
        // ------------------------------------------------------

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
                dogInfo,
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

              const SizedBox(height: 6),

              // ------------------------------------------------
              // CALL + CHAT
              // ------------------------------------------------

              Row(
                mainAxisSize:
                    MainAxisSize.min,
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
                    icon: Icons
                        .chat_bubble_rounded,
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
      height: 30,
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
  // STATS
  // ============================================================

  Widget _buildStats() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8FA),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              const Color(0xFFE7EAED),
        ),
      ),
      child: Row(
        children: [
          _stat(
            icon:
                Icons.timer_outlined,
            value: _duration,
            label: 'Time',
          ),

          _divider(),

          _stat(
            icon:
                Icons.route_rounded,
            value:
                '${_distanceKm.toStringAsFixed(2)} km',
            label: 'Distance',
          ),

          _divider(),

          _stat(
            icon:
                Icons.directions_walk_rounded,
            value: '$_steps',
            label: 'Steps',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT ITEM
  // ============================================================

  Widget _stat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
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
            style:
                const TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            label,
            style:
                const TextStyle(
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

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color:
          const Color(0xFFE0E4E8),
    );
  }

  // ============================================================
  // PEE / POOP
  // ============================================================

  Widget _buildActivities() {
    return Row(
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
    );
  }

  // ============================================================
  // ACTIVITY ITEM
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
      decoration:
          BoxDecoration(
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
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.75),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              textAlign:
                  TextAlign.center,
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

  Widget _buildCompleteSlider() {
    return LayoutBuilder(
      builder:
          (
            BuildContext context,
            BoxConstraints constraints,
          ) {
        const double height = 48;
        const double knob = 40;

        final double maxSlide =
            math.max(
          0.0,
          constraints.maxWidth -
              knob -
              2,
        );

        final double knobLeft =
            _slideValue * maxSlide;

        return Container(
          height: height,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFEEEE),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  red.withOpacity(0.16),
            ),
          ),
          child: Stack(
            children: [
              // ------------------------------------------------
              // CENTER TEXT
              // ------------------------------------------------

              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      left: 45,
                      right: 12,
                    ),
                    child: Text(
                      widget.ending
                          ? 'Completing Walk...'
                          : 'SLIDE TO COMPLETE WALK',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: red,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------
              // SLIDER KNOB
              // ------------------------------------------------

              Positioned(
                left: knobLeft,
                top: 4,
                child:
                    GestureDetector(
                  behavior:
                      HitTestBehavior.opaque,

                  onHorizontalDragUpdate:
                      widget.ending
                          ? null
                          : (
                              DragUpdateDetails
                                  details,
                            ) {
                              setState(() {
                                final double
                                    current =
                                    _slideValue *
                                        maxSlide;

                                final double
                                    next =
                                    (current +
                                            details
                                                .delta
                                                .dx)
                                        .clamp(
                                  0.0,
                                  maxSlide,
                                );

                                _slideValue =
                                    maxSlide <= 0
                                        ? 0.0
                                        : next /
                                            maxSlide;
                              });
                            },

                  onHorizontalDragEnd:
                      widget.ending
                          ? null
                          : (
                              DragEndDetails
                                  details,
                            ) {
                              _handleSliderEnd();
                            },

                  child: Container(
                    width: knob,
                    height: knob,
                    decoration:
                        const BoxDecoration(
                      color: red,
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      widget.ending
                          ? Icons.sync_rounded
                          : Icons
                              .arrow_forward_rounded,
                      color:
                          Colors.white,
                      size: 19,
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

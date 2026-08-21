import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveWalkBottomSheet extends StatelessWidget {
  const LiveWalkBottomSheet({
    super.key,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.ownerPhone,
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

  static const Color orange =
      Color(0xFFFF6600);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color green =
      Color(0xFF16A34A);

  static const Color red =
      Color(0xFFE53935);

  static const Color dark =
      Color(0xFF263746);

  static const Color muted =
      Color(0xFF7A8289);

  String _duration() {
    final dynamic value =
        sessionData['elapsedSeconds'];

    final int seconds =
        int.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    final int h = seconds ~/ 3600;
    final int m =
        (seconds % 3600) ~/ 60;
    final int s = seconds % 60;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String _distance() {
    final dynamic value =
        sessionData['distanceKm'];

    final double distance =
        double.tryParse(
              value?.toString() ?? '',
            ) ??
            0;

    return '${distance.toStringAsFixed(1)} km';
  }

  int _count(String key) {
    return int.tryParse(
          sessionData[key]?.toString() ??
              '',
        ) ??
        0;
  }

  Future<void> _callOwner() async {
    final phone =
        ownerPhone?.trim() ?? '';

    if (phone.isEmpty) return;

    final uri =
        Uri.parse('tel:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _smsOwner() async {
    final phone =
        ownerPhone?.trim() ?? '';

    if (phone.isEmpty) return;

    final uri =
        Uri.parse('sms:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .30,
      minChildSize: .30,
      maxChildSize: .78,
      snap: true,
      snapSizes: const [
        .30,
        .52,
        .78,
      ],
      builder: (
        context,
        controller,
      ) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(27),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
              17,
              10,
              17,
              25,
            ),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFD5DADD),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // OWNER
              Row(
                children: [
                  Container(
                    width: 51,
                    height: 51,
                    decoration:
                        BoxDecoration(
                      color:
                          orange.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: orange,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownerName.isEmpty
                              ? 'Owner'
                              : ownerName,
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
                        const SizedBox(height: 3),
                        Text(
                          dogBreed.isEmpty
                              ? dogName
                              : '$dogName • $dogBreed',
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
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFFEAF7EF),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: green,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              // CALL / SMS
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.call_rounded,
                      label: 'Call Owner',
                      color: green,
                      onPressed:
                          ownerPhone
                                      ?.trim()
                                      .isNotEmpty ==
                                  true
                              ? _callOwner
                              : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      icon:
                          Icons.sms_rounded,
                      label: 'SMS',
                      color: blue,
                      onPressed:
                          ownerPhone
                                      ?.trim()
                                      .isNotEmpty ==
                                  true
                              ? _smsOwner
                              : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // STATS
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      Icons.route_rounded,
                      'Distance',
                      _distance(),
                      blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _stat(
                      Icons.timer_outlined,
                      'Duration',
                      _duration(),
                      orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _stat(
                      Icons.pets_rounded,
                      'Events',
                      '${_count('peeCount') + _count('poopCount')}',
                      green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // EVENTS
              Container(
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF7F8F8),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _event(
                        Icons.water_drop_rounded,
                        'Pee',
                        _count('peeCount'),
                        blue,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 35,
                      color:
                          const Color(0xFFE1E5E7),
                    ),
                    Expanded(
                      child: _event(
                        Icons.pets_rounded,
                        'Poop',
                        _count('poopCount'),
                        green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // END WALK
              SizedBox(
                width: double.infinity,
                height: 53,
                child: ElevatedButton.icon(
                  onPressed:
                      ending ? null : onEndWalk,
                  icon: ending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .stop_circle_outlined,
                        ),
                  label: Text(
                    ending
                        ? 'Ending Walk...'
                        : 'End Walk',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        red.withOpacity(.60),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              color.withOpacity(.10),
          foregroundColor: color,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _stat(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color:
              const Color(0xFFE2E6E8),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _event(
    IconData icon,
    String title,
    int count,
    Color color,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 19,
        ),
        const SizedBox(width: 7),
        Text(
          '$title: $count',
          style: const TextStyle(
            color: dark,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/walk_request.dart';

class WalkRequestCard extends StatelessWidget {
  final WalkRequest request;

  /// Accept button callback
  final VoidCallback onAccept;

  /// Reject button callback.
  ///
  /// Optional रखा गया है ताकि पुराना code भी compile हो।
  final VoidCallback? onReject;

  const WalkRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    this.onReject,
  });

  // ============================================================
  // DOJO WALKER THEME
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color orangeDark = Color(0xFFE45D32);

  static const Color blue = Color(0xFF238EAE);
  static const Color blueLight = Color(0xFFEAF7FB);

  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFEAF7EF);

  static const Color red = Color(0xFFDC3545);
  static const Color redLight = Color(0xFFFFF0F1);

  static const Color dark = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);

  static const Color border = Color(0xFFE1E6E8);
  static const Color softBackground = Color(0xFFF7F9F9);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.055),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: green,
                  size: 24,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${request.dogName} • ${request.dogBreed}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // NEW BADGE
              // ==================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: orange.withOpacity(.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: orange.withOpacity(.20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      color: orange,
                      size: 11,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'NEW',
                      style: TextStyle(
                        color: orange,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // PICKUP ADDRESS
          // ======================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border.withOpacity(.65),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: greenLight,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: green,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PICKUP LOCATION',
                        style: TextStyle(
                          color: muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        request.pickupAddress,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // DISTANCE + ESTIMATED TIME
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  icon: Icons.route_rounded,
                  value:
                      '${request.distanceKm.toStringAsFixed(1)} km',
                  label: 'Distance',
                  iconColor: blue,
                  backgroundColor: blueLight,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _infoBox(
                  icon: Icons.access_time_rounded,
                  value: request.estimatedTime,
                  label: 'Estimated',
                  iconColor: orange,
                  backgroundColor:
                      orange.withOpacity(.08),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ======================================================
          // WALK TYPE + STATUS
          // ======================================================

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: orange.withOpacity(.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flash_on_rounded,
                      color: orange,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      request.walkType,
                      style: const TextStyle(
                        color: orangeDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: const TextStyle(
                    color: green,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // ACCEPT + REJECT BUTTONS
          // ======================================================

          Row(
            children: [
              // ==================================================
              // REJECT
              // ==================================================

              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 47,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      side: BorderSide(
                        color: red.withOpacity(.55),
                        width: 1.2,
                      ),
                      backgroundColor: redLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 18,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              // ==================================================
              // ACCEPT
              // ==================================================

              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 47,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 19,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Accept Walk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  static Widget _infoBox({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 17,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

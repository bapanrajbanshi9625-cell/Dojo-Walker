import 'package:flutter/material.dart';

import '../models/walk_request.dart';

class WalkRequestCard extends StatelessWidget {
  final WalkRequest request;
  final VoidCallback onAccept;

  const WalkRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
  });

  static const Color orange =
      Color(0xFFFF6600);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color green =
      Color(0xFF16A34A);

  static const Color greenLight =
      Color(0xFFEAF7EF);

  static const Color dark =
      Color(0xFF263746);

  static const Color muted =
      Color(0xFF7A8289);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFE1E6E8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

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
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: green,
                  size: 24,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.ownerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${request.dogName} • '
                      '${request.dogBreed}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
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
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: green,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ======================================================
          // PICKUP
          // ======================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF7FAF8,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: green,
                  size: 20,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    request.pickupAddress,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ======================================================
          // DISTANCE + TIME
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _infoBox(
                  icon: Icons.route_rounded,
                  value:
                      '${request.distanceKm.toStringAsFixed(1)} km',
                  label: 'Distance',
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: _infoBox(
                  icon:
                      Icons.access_time_rounded,
                  value:
                      request.estimatedTime,
                  label: 'Estimated',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ======================================================
          // WALK TYPE
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: orange,
                size: 17,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                request.walkType,
                style: const TextStyle(
                  color: orange,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const Spacer(),

              Text(
                request.status
                    .toUpperCase(),
                style: const TextStyle(
                  color: green,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ======================================================
          // ACCEPT BUTTON
          // ======================================================

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onAccept,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
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

                  SizedBox(
                    width: 7,
                  ),

                  Text(
                    'Accept Walk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF7F8F8,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFFE5E8E8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: blue,
            size: 17,
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 8,
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

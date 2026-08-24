// File:
// lib/features/insta_walk/widgets/insta_walk_request_card.dart

import 'package:flutter/material.dart';

import '../models/insta_walk_request.dart';

class InstaWalkRequestCard extends StatelessWidget {
  final InstaWalkRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const InstaWalkRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  // ============================================================
  // COLORS
  // ============================================================

  static const Color dark = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);

  static const Color orange = Color(0xFFFF6600);
  static const Color orangeLight = Color(0xFFFFF1E8);

  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFEAF7EF);

  static const Color red = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFEF2F2);

  static const Color blue = Color(0xFF238EAE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1E8E4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.055),
            blurRadius: 14,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: orangeLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: orange,
                  size: 23,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INSTA WALK REQUEST',
                      style: TextStyle(
                        color: dark,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: green,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ======================================================
          // PICKUP LOCATION
          // ======================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: green,
                  size: 18,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    _pickupAddress(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          // ======================================================
          // QUICK INFO
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _info(
                  Icons.route_rounded,
                  '${request.distanceKm.toStringAsFixed(1)} km',
                  'Distance',
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _info(
                  Icons.access_time_rounded,
                  _estimatedTime(),
                  'Estimated',
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ======================================================
          // ACTION BUTTONS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 43,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      side: const BorderSide(
                        color: Color(0xFFFECACA),
                      ),
                      backgroundColor: redLight,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 43,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Accept Walk',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
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
  // TITLE
  // ============================================================

  String _title() {
    final String owner =
        request.ownerName.trim();

    final String dog =
        request.dogName.trim();

    if (owner.isNotEmpty && dog.isNotEmpty) {
      return '$owner • $dog';
    }

    if (dog.isNotEmpty) {
      return dog;
    }

    if (owner.isNotEmpty) {
      return owner;
    }

    return 'Nearby walk request';
  }

  // ============================================================
  // PICKUP
  // ============================================================

  String _pickupAddress() {
    final String address =
        request.pickupAddress.trim();

    if (address.isEmpty) {
      return 'Pickup location';
    }

    return address;
  }

  // ============================================================
  // ESTIMATED TIME
  // ============================================================

  String _estimatedTime() {
    final String value =
        request.estimatedTime.trim();

    if (value.isEmpty) {
      return '--';
    }

    return value;
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  static Widget _info(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE5E8E8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: blue,
            size: 16,
          ),

          const SizedBox(width: 6),

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
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 7,
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

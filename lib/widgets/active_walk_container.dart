import 'package:flutter/material.dart';

import '../features/walks/models/walk_request.dart';
import '../screens/active_walk_details_screen.dart';

class ActiveWalkContainer extends StatelessWidget {
  final WalkRequest request;

  const ActiveWalkContainer({
    super.key,
    required this.request,
  });

  static const Color dark = Color(0xFF263746);
  static const Color muted = Color(0xFF7A8289);
  static const Color blue = Color(0xFF238EAE);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFEAF7EF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ActiveWalkDetailsScreen(
              request: request,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDDE7E1),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(.07),
              blurRadius: 17,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ================================================================
            // TOP STRIP
            // ================================================================

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: greenLight,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: green,
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
                        'ACTIVE WALK',
                        style: TextStyle(
                          color: dark,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _title(),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
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
                    'ACCEPTED',
                    style: TextStyle(
                      color: green,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(width: 7),

                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: green,
                  size: 22,
                ),
              ],
            ),

            const SizedBox(height: 11),

            // ================================================================
            // PICKUP
            // ================================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius:
                    BorderRadius.circular(14),
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
                      request.pickupAddress
                              .trim()
                              .isEmpty
                          ? 'Pickup location'
                          : request.pickupAddress,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: blue,
                    size: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 9),

            // ================================================================
            // QUICK INFO
            // ================================================================

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
                    request.estimatedTime.isEmpty
                        ? '--'
                        : request.estimatedTime,
                    'Estimated',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title() {
    final String owner =
        request.ownerName.trim();

    final String dog =
        request.dogName.trim();

    if (owner.isNotEmpty &&
        dog.isNotEmpty) {
      return '$owner • $dog';
    }

    if (dog.isNotEmpty) {
      return dog;
    }

    if (owner.isNotEmpty) {
      return owner;
    }

    return 'Walk accepted';
  }

  static Widget _info(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius:
            BorderRadius.circular(11),
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
                    fontWeight:
                        FontWeight.w800,
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

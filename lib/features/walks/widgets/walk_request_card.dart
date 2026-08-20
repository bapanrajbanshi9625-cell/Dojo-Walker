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
      margin:
          const EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFDDE7E1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.07),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: greenLight,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEW WALK REQUEST',
                      style: TextStyle(
                        color: dark,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.ownerName} • ${request.dogName}',
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
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7FAF8),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: green,
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    request.pickupAddress,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _info(
                  Icons.route_rounded,
                  '${request.distanceKm.toStringAsFixed(1)} km',
                  'Distance',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _info(
                  Icons.access_time_rounded,
                  request.estimatedTime,
                  'Estimated',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(
                Icons.check_circle_outline_rounded,
              ),
              label: const Text(
                'Accept Walk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _info(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F8),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF238EAE),
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

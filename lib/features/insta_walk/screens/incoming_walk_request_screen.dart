import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class IncomingWalkRequestScreen extends StatelessWidget {
  const IncomingWalkRequestScreen({
    super.key,
    required this.walkId,
    required this.ownerName,
    required this.dogName,
    this.dogBreed = '',
    this.pickupAddress = '',
    this.distanceKm,
    this.estimatedMinutes,
  });

  final String walkId;
  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String pickupAddress;
  final double? distanceKm;
  final int? estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'INCOMING WALK',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
      ),
      body: Column(
        children: [
          // =====================================================
          // MAP PLACEHOLDER
          // =====================================================

          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.map_rounded,
                      size: 70,
                      color: Colors.grey,
                    ),
                  ),

                  // Walker location
                  const Positioned(
                    left: 70,
                    top: 170,
                    child: _MapMarker(
                      icon: Icons.person_pin_circle_rounded,
                      label: 'You',
                    ),
                  ),

                  // Pickup location
                  const Positioned(
                    right: 65,
                    top: 90,
                    child: _MapMarker(
                      icon: Icons.location_on_rounded,
                      label: 'Pickup',
                    ),
                  ),

                  // Distance
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            offset: Offset(0, 4),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_walk_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _distanceText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Text(
                            _etaText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =====================================================
          // REQUEST DETAILS
          // =====================================================

          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'New Walk Request',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _InfoRow(
                      icon: Icons.person_rounded,
                      title: 'Owner',
                      value: ownerName.isEmpty
                          ? 'Owner'
                          : ownerName,
                    ),

                    _InfoRow(
                      icon: Icons.pets_rounded,
                      title: 'Dog',
                      value: dogName.isEmpty
                          ? 'Dog'
                          : dogName,
                    ),

                    if (dogBreed.trim().isNotEmpty)
                      _InfoRow(
                        icon: Icons.category_rounded,
                        title: 'Breed',
                        value: dogBreed,
                      ),

                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      title: 'Pickup',
                      value: pickupAddress.isEmpty
                          ? 'Pickup location'
                          : pickupAddress,
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // ACTIONS
                    // =================================================

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                  false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    AppColors.secondary,
                                side: const BorderSide(
                                  color: AppColors.border,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'REJECT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                  true,
                                );
                              },
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary,
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
                              child: const Text(
                                'ACCEPT WALK',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _distanceText {
    if (distanceKm == null) {
      return 'Calculating distance...';
    }

    return '${distanceKm!.toStringAsFixed(1)} km away';
  }

  String get _etaText {
    if (estimatedMinutes == null) {
      return 'Calculating ETA';
    }

    return '~$estimatedMinutes min';
  }
}

// ===============================================================
// MAP MARKER
// ===============================================================

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 42,
          color: AppColors.primary,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ===============================================================
// INFO ROW
// ===============================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

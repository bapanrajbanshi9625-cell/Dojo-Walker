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

  static const Color _darkText = Color(0xFF263746);
  static const Color _mutedText = Color(0xFF7A8289);
  static const Color _green = Color(0xFF16A34A);
  static const Color _greenLight = Color(0xFFEAF7EF);
  static const Color _blue = Color(0xFF238EAE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDDE7E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          _buildLocationBox(),

          const SizedBox(height: 12),

          _buildDistanceTime(),

          const SizedBox(height: 15),

          _buildAcceptButton(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: _green,
            size: 25,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NEW WALK REQUEST',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${request.ownerName} • ${request.dogName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Text(
            'NEW',
            style: TextStyle(
              color: _green,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1E8E3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: _green,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PICK-UP LOCATION',
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.55,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  request.pickupAddress,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISTANCE + TIME
  // ============================================================

  Widget _buildDistanceTime() {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            icon: Icons.route_rounded,
            value:
                '${request.distanceKm.toStringAsFixed(1)} km',
            label: 'Distance',
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: _infoBox(
            icon: Icons.access_time_rounded,
            value: request.estimatedTime,
            label: 'Estimated time',
          ),
        ),
      ],
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE5E8E8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4F7),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: _blue,
              size: 17,
            ),
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
                    color: _darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A9298),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCEPT BUTTON
  // ============================================================

  Widget _buildAcceptButton() {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: ElevatedButton.icon(
        onPressed: onAccept,
        icon: const Icon(
          Icons.check_circle_outline_rounded,
          size: 20,
        ),
        label: const Text(
          'Accept Walk',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

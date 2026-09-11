import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class IncomingWalkOwnerDogDetails extends StatelessWidget {
  const IncomingWalkOwnerDogDetails({
    super.key,
    required this.dogName,
    required this.dogBreed,
    required this.ownerName,
    this.ownerPhotoUrl,
    this.dogPhotoUrl,
  });

  final String dogName;
  final String dogBreed;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String? dogPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _Avatar(
            imageUrl: dogPhotoUrl,
            icon: Icons.pets_rounded,
            size: 58,
            iconSize: 28,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogName.trim().isEmpty ? 'Dog' : dogName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                if (dogBreed.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dogBreed.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    _Avatar(
                      imageUrl: ownerPhotoUrl,
                      icon: Icons.person_rounded,
                      size: 22,
                      iconSize: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ownerName.trim().isEmpty
                            ? 'Owner'
                            : ownerName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DojoWalkerColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 18,
              color: DojoWalkerColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.icon,
    required this.size,
    required this.iconSize,
  });

  final String? imageUrl;
  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DojoWalkerColors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: DojoWalkerColors.primary.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: iconSize,
                  color: DojoWalkerColors.primary,
                ),
              )
            : Icon(
                icon,
                size: iconSize,
                color: DojoWalkerColors.primary,
              ),
      ),
    );
  }
}

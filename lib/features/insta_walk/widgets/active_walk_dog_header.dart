import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/insta_walk_request.dart';

class ActiveWalkDogHeader extends StatelessWidget {
  final InstaWalkRequest request;
  final double distanceKm;

  const ActiveWalkDogHeader({
    super.key,
    required this.request,
    required this.distanceKm,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String dogName =
        request.dogName.trim().isEmpty
            ? 'Dog'
            : request.dogName.trim();

    final String breed =
        request.dogBreed.trim().isEmpty
            ? 'Breed not available'
            : request.dogBreed.trim();

    final String owner =
        request.ownerName.trim().isEmpty
            ? 'Owner'
            : request.ownerName.trim();

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.pets_rounded,
            color: AppColors.primary,
            size: 31,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                dogName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                breed,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Owner: $owner',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                distanceKm > 0
                    ? '${distanceKm.toStringAsFixed(1)} km'
                    : '--',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'distance',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

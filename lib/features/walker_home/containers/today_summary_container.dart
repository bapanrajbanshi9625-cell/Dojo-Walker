import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/past_walk_model.dart';
import '../services/walker_home_service.dart';
import '../widgets/section_title.dart';
import '../widgets/summary_stat_card.dart';

class TodaySummaryContainer extends StatelessWidget {
  final void Function({
    required String title,
    required String description,
    required IconData icon,
  }) onDetails;

  TodaySummaryContainer({
    super.key,
    required this.onDetails,
  });

  final WalkerHomeService _service = WalkerHomeService();

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: "Today's Summary",
        ),

        const SizedBox(height: 8),

        StreamBuilder<List<PastWalkModel>>(
          stream: _service.watchWalksForDate(today),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Container(
                height: 112,
                decoration: BoxDecoration(
                  color: DojoWalkerColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: DojoWalkerColors.border,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Unable to load today\'s summary.',
              );
            }

            final List<PastWalkModel> walks =
                snapshot.data ?? const <PastWalkModel>[];

            final int totalWalks =
                _service.totalWalks(walks);

            final double distanceKm =
                _service.totalDistanceKm(walks);

            final double durationMinutes =
                _service.totalDurationMinutes(walks);

            final double rating =
                _service.averageRating(walks);

            final String performance =
                _performanceText(
              totalWalks: totalWalks,
              rating: rating,
            );

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DojoWalkerColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DojoWalkerColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.035,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SummaryStatCard(
                        icon: Icons.directions_walk_rounded,
                        title: 'Total Walks',
                        value: '$totalWalks',
                        background:
                            DojoWalkerColors.orangeLight,
                        iconColor:
                            DojoWalkerColors.orange,
                        onTap: () {
                          onDetails(
                            title: 'Total Walks',
                            icon:
                                Icons.directions_walk_rounded,
                            description:
                                'Today you completed '
                                '$totalWalks walk(s).',
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SummaryStatCard(
                        icon: Icons.route_rounded,
                        title: 'Distance',
                        value:
                            '${distanceKm.toStringAsFixed(1)} km',
                        background:
                            DojoWalkerColors.blueLight,
                        iconColor:
                            DojoWalkerColors.blue,
                        onTap: () {
                          onDetails(
                            title: 'Distance',
                            icon: Icons.route_rounded,
                            description:
                                'Today you walked '
                                '${distanceKm.toStringAsFixed(1)} km.',
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SummaryStatCard(
                        icon: Icons.timer_outlined,
                        title: 'Duration',
                        value:
                            '${durationMinutes.round()} min',
                        background:
                            DojoWalkerColors.greenLight,
                        iconColor:
                            DojoWalkerColors.green,
                        onTap: () {
                          onDetails(
                            title: 'Walk Duration',
                            icon:
                                Icons.timer_outlined,
                            description:
                                'Today you walked for '
                                '${durationMinutes.round()} minutes.',
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SummaryStatCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Report Card',
                        value: performance,
                        background:
                            DojoWalkerColors.orangeLight,
                        iconColor:
                            DojoWalkerColors.orange,
                        onTap: () {
                          onDetails(
                            title: 'Performance Report',
                            icon:
                                Icons.bar_chart_rounded,
                            description:
                                _performanceDescription(
                              totalWalks: totalWalks,
                              rating: rating,
                              performance: performance,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _performanceText({
    required int totalWalks,
    required double rating,
  }) {
    if (totalWalks == 0) {
      return 'No walks';
    }

    if (rating >= 4.5) {
      return 'Excellent';
    }

    if (rating >= 4.0) {
      return 'Great';
    }

    if (rating >= 3.0) {
      return 'Good';
    }

    if (rating > 0) {
      return 'Keep going';
    }

    return 'Active';
  }

  String _performanceDescription({
    required int totalWalks,
    required double rating,
    required String performance,
  }) {
    if (totalWalks == 0) {
      return 'You have no completed walks for today yet.';
    }

    if (rating > 0) {
      return 'Your performance for today is '
          '$performance with an average rating of '
          '${rating.toStringAsFixed(1)}/5.';
    }

    return 'Your performance for today is '
        '$performance based on $totalWalks completed walk(s).';
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DojoWalkerColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: DojoWalkerColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: DojoWalkerColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: "Today's Summary",
        ),

        const SizedBox(height: 8),

        StreamBuilder<WalkerHomeSummary>(
          stream: _service.watchTodaySummary(),
          builder: (
            BuildContext context,
            AsyncSnapshot<WalkerHomeSummary> snapshot,
          ) {
            final WalkerHomeSummary summary =
                snapshot.data ?? const WalkerHomeSummary();

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
                    color: Colors.black.withValues(alpha: 0.035),
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
                        value: '${summary.totalWalks}',
                        background:
                            DojoWalkerColors.orangeLight,
                        iconColor: DojoWalkerColors.orange,
                        onTap: () {
                          onDetails(
                            title: 'Total Walks',
                            icon: Icons.directions_walk_rounded,
                            description:
                                'Today you completed '
                                '${summary.totalWalks} walk(s).',
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
                            '${summary.distanceKm.toStringAsFixed(1)} km',
                        background:
                            DojoWalkerColors.blueLight,
                        iconColor: DojoWalkerColors.blue,
                        onTap: () {
                          onDetails(
                            title: 'Distance',
                            icon: Icons.route_rounded,
                            description:
                                'Today you walked '
                                '${summary.distanceKm.toStringAsFixed(1)} km.',
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
                            '${summary.durationMinutes.round()} min',
                        background:
                            DojoWalkerColors.greenLight,
                        iconColor: DojoWalkerColors.green,
                        onTap: () {
                          onDetails(
                            title: 'Walk Duration',
                            icon: Icons.timer_outlined,
                            description:
                                'Today you walked for '
                                '${summary.durationMinutes.round()} minutes.',
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
                        value: summary.performance,
                        background:
                            DojoWalkerColors.orangeLight,
                        iconColor: DojoWalkerColors.orange,
                        onTap: () {
                          onDetails(
                            title: 'Performance Report',
                            icon: Icons.bar_chart_rounded,
                            description:
                                'Your performance for today is '
                                '${summary.performance}.',
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
}

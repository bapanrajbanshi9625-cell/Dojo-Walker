import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';
import '../widgets/section_title.dart';
import '../widgets/summary_stat_card.dart';

class TodaySummaryContainer extends StatelessWidget {
  final void Function({
    required String title,
    required String description,
    required IconData icon,
  }) onDetails;

  const TodaySummaryContainer({
    super.key,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: "Today's Summary",
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DojoColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DojoColors.border,
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
                    value: '0',
                    background: DojoColors.orangeLight,
                    iconColor: DojoColors.orange,
                    onTap: () {
                      onDetails(
                        title: 'Total Walks',
                        icon: Icons.directions_walk_rounded,
                        description:
                            'Your total completed walks.',
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
                    value: '0 km',
                    background: DojoColors.blueLight,
                    iconColor: DojoColors.blue,
                    onTap: () {
                      onDetails(
                        title: 'Distance',
                        icon: Icons.route_rounded,
                        description:
                            'Your total walking distance.',
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
                    value: '0 min',
                    background: DojoColors.greenLight,
                    iconColor: DojoColors.green,
                    onTap: () {
                      onDetails(
                        title: 'Walk Duration',
                        icon: Icons.timer_outlined,
                        description:
                            'Your total walking duration.',
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
                    value: '—',
                    background: DojoColors.orangeLight,
                    iconColor: DojoColors.orange,
                    onTap: () {
                      onDetails(
                        title: 'Performance Report',
                        icon: Icons.bar_chart_rounded,
                        description:
                            'Your walking performance report.',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

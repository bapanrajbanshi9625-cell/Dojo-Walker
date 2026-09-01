import 'package:flutter/material.dart';

import '../widgets/section_title.dart';
import '../widgets/summary_stat_card.dart';
import '../services/walker_home_service.dart';

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1E4E8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .035),
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
                    background: const Color(0xFFFFE9E2),
                    iconColor: const Color(0xFFFF6B35),
                    onTap: () {
                      onDetails(
                        title: 'Total Walks',
                        icon: Icons.directions_walk_rounded,
                        description: 'Your total completed walks.',
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
                    background: const Color(0xFFE5F1FF),
                    iconColor: Colors.blue,
                    onTap: () {
                      onDetails(
                        title: 'Distance',
                        icon: Icons.route_rounded,
                        description: 'Your total walking distance.',
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
                    background: const Color(0xFFE7F5EA),
                    iconColor: Colors.green,
                    onTap: () {
                      onDetails(
                        title: 'Walk Duration',
                        icon: Icons.timer_outlined,
                        description: 'Your total walking duration.',
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
                    background: const Color(0xFFFFEEE8),
                    iconColor: const Color(0xFFFF6B35),
                    onTap: () {
                      onDetails(
                        title: 'Performance Report',
                        icon: Icons.bar_chart_rounded,
                        description: 'Your walking performance report.',
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

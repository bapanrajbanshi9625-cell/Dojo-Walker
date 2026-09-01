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

        StreamBuilder(
          stream: _service.watchTodaySummary(),
          builder: (context, snapshot) {
            final summary = snapshot.data;

            if (summary == null) {
              return _buildSummaryCard(
                context,
                totalWalks: 0,
                distanceKm: 0,
                durationMinutes: 0,
                performance: '—',
              );
            }

            return _buildSummaryCard(
              context,
              totalWalks: summary.totalWalks,
              distanceKm: summary.distanceKm,
              durationMinutes: summary.durationMinutes,
              performance: summary.performance,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required int totalWalks,
    required double distanceKm,
    required double durationMinutes,
    required String performance,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DojoWalkerColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SummaryStatCard(
              icon: Icons.directions_walk_rounded,
              title: 'Total Walks',
              value: '$totalWalks',
              background: DojoColors.orange.withValues(alpha: 0.10),
              iconColor: DojoColors.orange,
              onTap: () {
                onDetails(
                  title: 'Total Walks',
                  icon: Icons.directions_walk_rounded,
                  description:
                      'Today you completed $totalWalks walk(s).',
                );
              },
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SummaryStatCard(
              icon: Icons.route_rounded,
              title: 'Distance',
              value: '${distanceKm.toStringAsFixed(1)} km',
              background: DojoWalkerColors.infoSoft,
              iconColor: DojoWalkerColors.info,
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

          const SizedBox(width: 6),

          Expanded(
            child: SummaryStatCard(
              icon: Icons.timer_outlined,
              title: 'Duration',
              value: '${durationMinutes.round()} min',
              background: DojoWalkerColors.successSoft,
              iconColor: DojoWalkerColors.success,
              onTap: () {
                onDetails(
                  title: 'Walk Duration',
                  icon: Icons.timer_outlined,
                  description:
                      'Today you walked for '
                      '${durationMinutes.round()} minutes.',
                );
              },
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SummaryStatCard(
              icon: Icons.bar_chart_rounded,
              title: 'Report Card',
              value: performance,
              background: DojoColors.orange.withValues(alpha: 0.10),
              iconColor: DojoColors.orange,
              onTap: () {
                onDetails(
                  title: 'Performance Report',
                  icon: Icons.bar_chart_rounded,
                  description:
                      'Your performance for today is $performance.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../walker_home_features.dart';
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: "Today's Summary",
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFE1E4E8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.045),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon:
                          Icons.directions_walk_rounded,
                      title: 'Total Walks',
                      value:
                          WalkerHomeFeatures.totalWalks,
                      background:
                          const Color(0xFFFFE9E2),
                      iconColor:
                          WalkerHomeFeatures.orange,
                      onTap: () {
                        onDetails(
                          title: 'Total Walks',
                          icon: Icons
                              .directions_walk_rounded,
                          description:
                              WalkerHomeFeatures
                                  .summaryDetails(
                            'walks',
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.route_rounded,
                      title: 'Distance',
                      value:
                          WalkerHomeFeatures.distance,
                      background:
                          const Color(0xFFE5F1FF),
                      iconColor: Colors.blue,
                      onTap: () {
                        onDetails(
                          title: 'Distance',
                          icon: Icons.route_rounded,
                          description:
                              WalkerHomeFeatures
                                  .summaryDetails(
                            'distance',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.timer_outlined,
                      title: 'Duration',
                      value:
                          WalkerHomeFeatures.duration,
                      background:
                          const Color(0xFFE7F5EA),
                      iconColor: Colors.green,
                      onTap: () {
                        onDetails(
                          title: 'Walk Duration',
                          icon: Icons.timer_outlined,
                          description:
                              WalkerHomeFeatures
                                  .summaryDetails(
                            'duration',
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Report Card',
                      value:
                          WalkerHomeFeatures.performance,
                      background:
                          const Color(0xFFFFEEE8),
                      iconColor:
                          WalkerHomeFeatures.orange,
                      onTap: () {
                        onDetails(
                          title: 'Performance Report',
                          icon:
                              Icons.bar_chart_rounded,
                          description:
                              WalkerHomeFeatures
                                  .summaryDetails(
                            'report',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

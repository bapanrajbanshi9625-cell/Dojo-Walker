import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/details_date_filter.dart';

class WalkDetailsScreen extends StatefulWidget {
  const WalkDetailsScreen({super.key});

  @override
  State<WalkDetailsScreen> createState() =>
      _WalkDetailsScreenState();
}

class _WalkDetailsScreenState
    extends State<WalkDetailsScreen> {
  DetailsFilterType _filterType =
      DetailsFilterType.date;

  DateTime _selectedDate = DateTime.now();

  // ============================================================
  // FILTER TYPE
  // ============================================================

  void _changeFilterType(
    DetailsFilterType type,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _filterType = type;
    });
  }

  // ============================================================
  // DATE
  // ============================================================

  void _changeDate(DateTime date) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDateFilter =
        _filterType == DetailsFilterType.date;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.buttonText,
        title: const Text(
          'Walk Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          // ======================================================
          // DATE / WEEK FILTER
          // ======================================================

          DetailsDateFilter(
            selectedType: _filterType,
            selectedDate: _selectedDate,
            onTypeChanged: _changeFilterType,
            onDateChanged: _changeDate,
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // TITLE
                  // ==================================================

                  Text(
                    isDateFilter
                        ? 'Walks for selected date'
                        : 'Walks for selected week',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // TOTAL WALKS
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons
                                .directions_walk_rounded,
                            color:
                                AppColors.iconPrimary,
                            size: 25,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Walks',
                                style: TextStyle(
                                  color:
                                      AppColors
                                          .textSecondary,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '0',
                                style: TextStyle(
                                  color:
                                      AppColors
                                          .textPrimary,
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // WALK HISTORY
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.pets_rounded,
                          size: 42,
                          color:
                              AppColors.iconMuted,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'No walks found',
                          style: TextStyle(
                            color:
                                AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Walk history for the selected period will appear here.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                AppColors
                                    .textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

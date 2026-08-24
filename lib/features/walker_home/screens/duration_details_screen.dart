import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../widgets/details_date_filter.dart';

class DurationDetailsScreen extends StatefulWidget {
  const DurationDetailsScreen({super.key});

  @override
  State<DurationDetailsScreen> createState() =>
      _DurationDetailsScreenState();
}

class _DurationDetailsScreenState
    extends State<DurationDetailsScreen> {
  DetailsFilterType _filterType =
      DetailsFilterType.date;

  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  void _changeFilterType(
    DetailsFilterType type,
  ) {
    setState(() {
      _filterType = type;
    });

    if (type == DetailsFilterType.date) {
      _selectDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.buttonText,
        title: const Text(
          'Duration Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Column(
        children: [
          // ====================================================
          // DATE / WEEK FILTER
          // ====================================================

          DetailsDateFilter(
            selectedType: _filterType,
            selectedDate: _selectedDate,
            onTypeChanged: _changeFilterType,
            onDateChanged: (DateTime date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),

          // ====================================================
          // CONTENT
          // ====================================================

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _filterType ==
                            DetailsFilterType.date
                        ? 'Duration for selected date'
                        : 'Duration for selected week',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // TOTAL DURATION
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
                            color: AppColors.successSoft,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: AppColors.success,
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
                                'Total Duration',
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '0 min',
                                style: TextStyle(
                                  color:
                                      AppColors.textPrimary,
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
                  // DURATION DETAILS
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
                        Icon(
                          Icons.timer_rounded,
                          size: 42,
                          color: AppColors.iconMuted,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'No duration data found',
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
                          'Walk duration records for the selected period will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                AppColors.textSecondary,
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

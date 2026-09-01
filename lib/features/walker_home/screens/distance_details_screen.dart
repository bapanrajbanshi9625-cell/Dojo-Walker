import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';
import '../models/past_walk_model.dart';
import '../services/walker_home_service.dart';

enum _DistanceFilterType {
  week,
  date,
}

class DistanceDetailsScreen extends StatefulWidget {
  const DistanceDetailsScreen({
    super.key,
  });

  @override
  State<DistanceDetailsScreen> createState() =>
      _DistanceDetailsScreenState();
}

class _DistanceDetailsScreenState
    extends State<DistanceDetailsScreen> {
  final WalkerHomeService _service =
      WalkerHomeService();

  _DistanceFilterType _filterType =
      _DistanceFilterType.week;

  DateTime _selectedDate = DateTime.now();

  // ============================================================
  // START OF WEEK
  // Monday = first day
  // ============================================================

  DateTime _startOfWeek(
    DateTime date,
  ) {
    final DateTime day = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return day.subtract(
      Duration(
        days: day.weekday - 1,
      ),
    );
  }

  // ============================================================
  // WEEK START
  // ============================================================

  DateTime get _weekStart {
    return _startOfWeek(
      _selectedDate,
    );
  }

  // ============================================================
  // WEEK END
  // ============================================================

  DateTime get _weekEnd {
    return _weekStart.add(
      const Duration(days: 7),
    );
  }

  // ============================================================
  // DATE START
  // ============================================================

  DateTime get _dateStart {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
  }

  // ============================================================
  // DATE END
  // ============================================================

  DateTime get _dateEnd {
    return _dateStart.add(
      const Duration(days: 1),
    );
  }

  // ============================================================
  // DATE MATCH
  // ============================================================

  bool _matchesFilter(
    PastWalkModel walk,
  ) {
    final DateTime? date =
        walk.completedAt ??
            walk.startedAt ??
            walk.createdAt;

    if (date == null) {
      return false;
    }

    if (_filterType ==
        _DistanceFilterType.date) {
      return !date.isBefore(_dateStart) &&
          date.isBefore(_dateEnd);
    }

    return !date.isBefore(_weekStart) &&
        date.isBefore(_weekEnd);
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();

    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate:
          _selectedDate.isAfter(today)
              ? today
              : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final ThemeData theme =
            Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme:
                theme.colorScheme.copyWith(
              primary:
                  DojoColors.orange,
              surface:
                  DojoColors.surface,
              onSurface:
                  DojoColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _filterType =
          _DistanceFilterType.date;
    });
  }

  // ============================================================
  // WEEK PICKER
  // ============================================================

  Future<void> _showWeekPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          DojoColors.surface,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        DojoColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Distance Details',
                  style: TextStyle(
                    color:
                        DojoColors.dark,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                _WeekActionTile(
                  icon:
                      Icons.today_rounded,
                  title:
                      'Current Week',
                  subtitle:
                      _formatWeek(
                    _startOfWeek(
                      DateTime.now(),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _selectedDate =
                          DateTime.now();
                      _filterType =
                          _DistanceFilterType
                              .week;
                    });
                  },
                ),

                const SizedBox(height: 8),

                _WeekActionTile(
                  icon:
                      Icons.chevron_left_rounded,
                  title:
                      'Previous Week',
                  subtitle:
                      _formatWeek(
                    _weekStart.subtract(
                      const Duration(
                        days: 7,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _selectedDate =
                          _weekStart.subtract(
                        const Duration(
                          days: 7,
                        ),
                      );

                      _filterType =
                          _DistanceFilterType
                              .week;
                    });
                  },
                ),

                const SizedBox(height: 8),

                _WeekActionTile(
                  icon:
                      Icons.chevron_right_rounded,
                  title:
                      'Next Week',
                  subtitle:
                      _formatWeek(
                    _weekStart.add(
                      const Duration(
                        days: 7,
                      ),
                    ),
                  ),
                  enabled:
                      _canGoToNextWeek,
                  onTap:
                      _canGoToNextWeek
                          ? () {
                              Navigator.pop(
                                sheetContext,
                              );

                              if (!mounted) {
                                return;
                              }

                              setState(() {
                                _selectedDate =
                                    _weekStart.add(
                                  const Duration(
                                    days: 7,
                                  ),
                                );

                                _filterType =
                                    _DistanceFilterType
                                        .week;
                              });
                            }
                          : null,
                ),

                const SizedBox(height: 8),

                _WeekActionTile(
                  icon:
                      Icons.calendar_month_rounded,
                  title:
                      'Choose Date',
                  subtitle:
                      'Open calendar',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    _pickDate();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NEXT WEEK
  // ============================================================

  bool get _canGoToNextWeek {
    final DateTime currentWeek =
        _startOfWeek(
      DateTime.now(),
    );

    return _weekStart.isBefore(
      currentWeek,
    );
  }

  // ============================================================
  // FILTER VALUE
  // ============================================================

  String get _filterValue {
    if (_filterType ==
        _DistanceFilterType.date) {
      return _formatDate(
        _selectedDate,
      );
    }

    return _formatWeek(
      _weekStart,
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // WEEK FORMAT
  // ============================================================

  String _formatWeek(
    DateTime start,
  ) {
    final DateTime end =
        start.add(
      const Duration(days: 6),
    );

    if (start.year == end.year) {
      return '${start.day} '
          '${_monthName(start.month)}'
          ' - '
          '${end.day} '
          '${_monthName(end.month)}';
    }

    return '${start.day} '
        '${_monthName(start.month)} '
        '${start.year}'
        ' - '
        '${end.day} '
        '${_monthName(end.month)} '
        '${end.year}';
  }

  // ============================================================
  // MONTH
  // ============================================================

  String _monthName(
    int month,
  ) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          DojoColors.background,

      appBar: AppBar(
        backgroundColor:
            DojoColors.orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          'Distance Details',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // FILTER BAR
          // ======================================================

          Material(
            color:
                DojoColors.surface,
            child: Container(
              height: 48,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration:
                  const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        DojoColors.divider,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _filterType ==
                            _DistanceFilterType
                                .date
                        ? Icons
                            .calendar_today_rounded
                        : Icons
                            .date_range_rounded,
                    size: 18,
                    color:
                        DojoColors.iconPrimary,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      _filterValue,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            DojoColors
                                .textPrimary,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: _pickDate,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.all(6),
                      child: Icon(
                        Icons
                            .calendar_month_rounded,
                        size: 20,
                        color:
                            DojoColors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  InkWell(
                    onTap:
                        _showWeekPicker,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Week',
                            style:
                                TextStyle(
                              color:
                                  DojoColors
                                      .textSecondary,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons
                                .keyboard_arrow_down_rounded,
                            size: 19,
                            color:
                                DojoColors
                                    .iconSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: StreamBuilder<
                List<PastWalkModel>>(
              stream:
                  _service.watchPastWalks(),
              builder: (
                BuildContext context,
                AsyncSnapshot<
                        List<PastWalkModel>>
                    snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          DojoColors.orange,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const _ErrorState();
                }

                final List<PastWalkModel>
                    walks =
                    (snapshot.data ??
                            const <
                                PastWalkModel>[])
                        .where(
                          _matchesFilter,
                        )
                        .toList();

                final double totalDistance =
                    _service.totalDistanceKm(
                  walks,
                );

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24,
                  ),
                  children: [
                    Text(
                      _filterType ==
                              _DistanceFilterType
                                  .date
                          ? 'Distance for selected date'
                          : 'Distance for selected week',
                      style:
                          const TextStyle(
                        color:
                            DojoColors
                                .textPrimary,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // TOTAL DISTANCE
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            DojoColors.surface,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        border:
                            Border.all(
                          color:
                              DojoColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                                BoxDecoration(
                              color:
                                  DojoColors
                                      .orangeLight,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .map_rounded,
                              color:
                                  DojoColors
                                      .orange,
                              size: 25,
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Total Distance',
                                  style:
                                      TextStyle(
                                    color:
                                        DojoColors
                                            .textSecondary,
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '${totalDistance.toStringAsFixed(2)} km',
                                  style:
                                      const TextStyle(
                                    color:
                                        DojoColors
                                            .textPrimary,
                                    fontSize:
                                        24,
                                    fontWeight:
                                        FontWeight
                                            .w800,
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
                    // STATUS
                    // ==================================================

                    if (walks.isEmpty)
                      const _EmptyState()
                    else
                      _DistanceWalkList(
                        walks: walks,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// WALK LIST
// ================================================================

class _DistanceWalkList
    extends StatelessWidget {
  final List<PastWalkModel> walks;

  const _DistanceWalkList({
    required this.walks,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: walks.map(
        (PastWalkModel walk) {
          final double distance =
              walk.effectiveDistanceKm;

          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 8,
            ),
            padding:
                const EdgeInsets.all(14),
            decoration:
                BoxDecoration(
              color:
                  DojoColors.surface,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border:
                  Border.all(
                color:
                    DojoColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color:
                      DojoColors.orange,
                  size: 23,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        walk.displayId,
                        style:
                            const TextStyle(
                          color:
                              DojoColors
                                  .textPrimary,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        walk.displayTime,
                        style:
                            const TextStyle(
                          color:
                              DojoColors
                                  .textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${distance.toStringAsFixed(2)} km',
                  style:
                      const TextStyle(
                    color:
                        DojoColors.orange,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }
}

// ================================================================
// WEEK TILE
// ================================================================

class _WeekActionTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _WeekActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Opacity(
      opacity:
          enabled ? 1.0 : 0.45,
      child: Material(
        color:
            DojoColors.background,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          onTap:
              enabled ? onTap : null,
          borderRadius:
              BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color:
                        DojoColors
                            .orangeLight,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        DojoColors.orange,
                    size: 22,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              DojoColors
                                  .textPrimary,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          color:
                              DojoColors
                                  .textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      DojoColors
                          .iconSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
        color:
            DojoColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
          color:
              DojoColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.route_rounded,
            size: 42,
            color:
                DojoColors.iconSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No distance data found',
            style:
                TextStyle(
              color:
                  DojoColors.textPrimary,
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Distance records for the selected period will appear here.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  DojoColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ERROR STATE
// ================================================================

class _ErrorState
    extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Padding(
        padding:
            EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color:
                  DojoColors.textSecondary,
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              'Unable to load distance data.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    DojoColors.dark,
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

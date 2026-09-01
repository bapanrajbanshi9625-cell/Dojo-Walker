import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';
import '../models/past_walk_model.dart';
import '../widgets/past_walk_card.dart';

enum _PastWalkFilterType {
  week,
  date,
}

class PastWalksScreen extends StatefulWidget {
  const PastWalksScreen({
    super.key,
  });

  @override
  State<PastWalksScreen> createState() =>
      _PastWalksScreenState();
}

class _PastWalksScreenState
    extends State<PastWalksScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  _PastWalkFilterType _filterType =
      _PastWalkFilterType.week;

  DateTime _selectedDate = DateTime.now();

  // ============================================================
  // CURRENT WEEK START
  // ============================================================

  DateTime get _weekStart {
    final DateTime date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    return date.subtract(
      Duration(
        days: date.weekday - 1,
      ),
    );
  }

  // ============================================================
  // CURRENT WEEK END
  // ============================================================

  DateTime get _weekEnd {
    return _weekStart.add(
      const Duration(days: 7),
    );
  }

  // ============================================================
  // DATE END
  // ============================================================

  DateTime get _dateEnd {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day + 1,
    );
  }

  // ============================================================
  // FIRESTORE STREAM
  // ============================================================

  Stream<List<PastWalkModel>> _watchPastWalks() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        const <PastWalkModel>[],
      );
    }

    return _firestore
        .collection('walk_history')
        .where(
          'walkerUid',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final List<PastWalkModel> walks =
            snapshot.docs
                .map(
                  PastWalkModel.fromDocument,
                )
                .where(
                  (walk) => walk.isCompleted,
                )
                .where(
                  _matchesSelectedFilter,
                )
                .toList();

        walks.sort(
          (a, b) {
            final DateTime aDate =
                a.completedAt ??
                    a.startedAt ??
                    a.createdAt ??
                    DateTime.fromMillisecondsSinceEpoch(
                      0,
                    );

            final DateTime bDate =
                b.completedAt ??
                    b.startedAt ??
                    b.createdAt ??
                    DateTime.fromMillisecondsSinceEpoch(
                      0,
                    );

            return bDate.compareTo(aDate);
          },
        );

        return walks;
      },
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  bool _matchesSelectedFilter(
    PastWalkModel walk,
  ) {
    final DateTime? walkDate =
        walk.completedAt ??
            walk.startedAt ??
            walk.createdAt;

    if (walkDate == null) {
      return false;
    }

    if (_filterType ==
        _PastWalkFilterType.date) {
      return walkDate.isAfter(
            _selectedDate.subtract(
              const Duration(seconds: 1),
            ),
          ) &&
          walkDate.isBefore(_dateEnd);
    }

    return walkDate.isAfter(
          _weekStart.subtract(
            const Duration(seconds: 1),
          ),
        ) &&
        walkDate.isBefore(_weekEnd);
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (
        context,
        child,
      ) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context)
                    .colorScheme
                    .copyWith(
                      primary:
                          DojoColors.orange,
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
      _filterType =
          _PastWalkFilterType.date;
    });
  }

  // ============================================================
  // WEEK PICKER
  // ============================================================

  Future<void> _showWeekPicker() async {
    final _PastWalkFilterType? result =
        await showModalBottomSheet<
            _PastWalkFilterType>(
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
      builder: (context) {
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
                  'Past Walks',
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
                      context,
                      _PastWalkFilterType.week,
                    );

                    setState(() {
                      _selectedDate =
                          DateTime.now();
                      _filterType =
                          _PastWalkFilterType.week;
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
                      context,
                    );

                    setState(() {
                      _selectedDate =
                          _weekStart.subtract(
                        const Duration(
                          days: 7,
                        ),
                      );
                      _filterType =
                          _PastWalkFilterType.week;
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
                  onTap:
                      _canGoToNextWeek
                          ? () {
                              Navigator.pop(
                                context,
                              );

                              setState(() {
                                _selectedDate =
                                    _weekStart.add(
                                  const Duration(
                                    days: 7,
                                  ),
                                );

                                _filterType =
                                    _PastWalkFilterType
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
                      context,
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

    if (result == null) {
      return;
    }
  }

  // ============================================================
  // NEXT WEEK CHECK
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
  // START OF WEEK
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
  // DISPLAY FILTER
  // ============================================================

  String get _filterTitle {
    if (_filterType ==
        _PastWalkFilterType.date) {
      return 'Date';
    }

    return 'Week';
  }

  String get _filterValue {
    if (_filterType ==
        _PastWalkFilterType.date) {
      return _formatDate(
        _selectedDate,
      );
    }

    return _formatWeek(
      _weekStart,
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // FORMAT WEEK
  // ============================================================

  String _formatWeek(
    DateTime start,
  ) {
    final DateTime end =
        start.add(
      const Duration(days: 6),
    );

    return '${start.day} ${_monthName(start.month)}'
        ' - '
        '${end.day} ${_monthName(end.month)}';
  }

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
          const Color(0xFFF5F6F8),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            DojoColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Past Walks',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // THIN FILTER BAR
          // ======================================================

          Material(
            color: DojoColors.surface,
            child: InkWell(
              onTap: _showWeekPicker,
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
                              _PastWalkFilterType
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

                    Text(
                      _filterValue,
                      style:
                          const TextStyle(
                        color:
                            DojoColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    // CALENDAR
                    InkWell(
                      onTap: _pickDate,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(6),
                        child: Icon(
                          Icons
                              .calendar_month_rounded,
                          size: 20,
                          color:
                              DojoColors.orange,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // WEEK
                    InkWell(
                      onTap:
                          _showWeekPicker,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(6),
                        child: Row(
                          children: [
                            Text(
                              _filterTitle,
                              style:
                                  const TextStyle(
                                color:
                                    DojoColors
                                        .textSecondary,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              width: 2,
                            ),
                            const Icon(
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
          ),

          // ======================================================
          // WALK LIST
          // ======================================================

          Expanded(
            child: StreamBuilder<
                List<PastWalkModel>>(
              stream:
                  _watchPastWalks(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot
                    .connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message:
                        'Unable to load past walks.',
                  );
                }

                final List<
                        PastWalkModel>
                    walks =
                    snapshot.data ??
                        const <
                            PastWalkModel>[];

                if (walks.isEmpty) {
                  return _EmptyState(
                    filterValue:
                        _filterValue,
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    16,
                    16,
                    24,
                  ),
                  itemCount:
                      walks.length,
                  separatorBuilder:
                      (
                    context,
                    index,
                  ) =>
                          const SizedBox(
                    height: 8,
                  ),
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final PastWalkModel
                        walk =
                        walks[index];

                    return SizedBox(
                      height: 64,
                      child: PastWalkCard(
                        id: walk.displayId,
                        time:
                            walk.displayTime,
                        details:
                            walk.displayDetails,
                        onTap: () {
                          _showWalkDetails(
                            walk,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WALK DETAILS
  // ============================================================

  void _showWalkDetails(
    PastWalkModel walk,
  ) {
    showModalBottomSheet(
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
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  walk.displayId,
                  style:
                      const TextStyle(
                    color:
                        DojoColors.dark,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                _DetailRow(
                  label: 'Dog',
                  value:
                      walk.dogName.isEmpty
                          ? '—'
                          : walk.dogName,
                ),

                _DetailRow(
                  label: 'Owner',
                  value:
                      walk.ownerName
                              .isEmpty
                          ? '—'
                          : walk.ownerName,
                ),

                _DetailRow(
                  label: 'Time',
                  value:
                      walk.displayTime,
                ),

                _DetailRow(
                  label: 'Distance',
                  value:
                      walk.distanceKm >
                              0
                          ? '${walk.distanceKm.toStringAsFixed(1)} km'
                          : '—',
                ),

                _DetailRow(
                  label: 'Duration',
                  value:
                      walk.durationMinutes >
                              0
                          ? '${walk.durationMinutes.round()} min'
                          : '—',
                ),

                _DetailRow(
                  label: 'Rating',
                  value:
                      walk.rating > 0
                          ? '${walk.rating}/5'
                          : '—',
                ),

                if (walk.walkerNote
                    .isNotEmpty)
                  _DetailRow(
                    label: 'Note',
                    value:
                        walk.walkerNote,
                  ),

                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// WEEK ACTION TILE
// ================================================================

class _WeekActionTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _WeekActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: DojoColors.background,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
                      DojoColors.orangeLight,
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

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyState
    extends StatelessWidget {
  final String filterValue;

  const _EmptyState({
    required this.filterValue,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration:
                  BoxDecoration(
                color:
                    DojoColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                color:
                    DojoColors.orange,
                size: 34,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No Past Walks',
              style: TextStyle(
                color:
                    DojoColors.dark,
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'No completed walks found for\n$filterValue.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    DojoColors
                        .textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ERROR STATE
// ================================================================

class _ErrorState
    extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,
              color:
                  DojoColors
                      .textSecondary,
              size: 44,
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
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

// ================================================================
// DETAIL ROW
// ================================================================

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    DojoColors
                        .textSecondary,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color:
                    DojoColors.dark,
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/dojo_walker_colors.dart';
import '../../my_walks/models/past_walk_model.dart';
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
  // START OF WEEK
  // Monday = first day of week
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
  // SELECTED WEEK START
  // ============================================================

  DateTime get _weekStart {
    return _startOfWeek(
      _selectedDate,
    );
  }

  // ============================================================
  // SELECTED WEEK END
  // Exclusive
  // ============================================================

  DateTime get _weekEnd {
    return _weekStart.add(
      const Duration(days: 7),
    );
  }

  // ============================================================
  // SELECTED DATE START
  // ============================================================

  DateTime get _dateStart {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
  }

  // ============================================================
  // SELECTED DATE END
  // ============================================================

  DateTime get _dateEnd {
    return _dateStart.add(
      const Duration(days: 1),
    );
  }

  // ============================================================
  // FIRESTORE STREAM
  //
  // Collection:
  // walk_history
  //
  // Walker field:
  // walkerId
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
          'walkerId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<PastWalkModel> walks =
            snapshot.docs
                .map(
                  PastWalkModel.fromDocument,
                )
                .where(
                  (PastWalkModel walk) =>
                      walk.isCompleted,
                )
                .where(
                  _matchesSelectedFilter,
                )
                .toList();

        // Newest completed walk first.
        walks.sort(
          (
            PastWalkModel a,
            PastWalkModel b,
          ) {
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
  // FILTER MATCH
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

    // ----------------------------------------------------------
    // DATE
    // ----------------------------------------------------------

    if (_filterType ==
        _PastWalkFilterType.date) {
      return !walkDate.isBefore(
            _dateStart,
          ) &&
          walkDate.isBefore(
            _dateEnd,
          );
    }

    // ----------------------------------------------------------
    // WEEK
    // ----------------------------------------------------------

    return !walkDate.isBefore(
          _weekStart,
        ) &&
        walkDate.isBefore(
          _weekEnd,
        );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();

    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today)
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
          _PastWalkFilterType.date;
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
                // ------------------------------------------------
                // HANDLE
                // ------------------------------------------------

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

                // ------------------------------------------------
                // CURRENT WEEK
                // ------------------------------------------------

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
                          _PastWalkFilterType
                              .week;
                    });
                  },
                ),

                const SizedBox(height: 8),

                // ------------------------------------------------
                // PREVIOUS WEEK
                // ------------------------------------------------

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
                          _PastWalkFilterType
                              .week;
                    });
                  },
                ),

                const SizedBox(height: 8),

                // ------------------------------------------------
                // NEXT WEEK
                // ------------------------------------------------

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
                                    _PastWalkFilterType
                                        .week;
                              });
                            }
                          : null,
                ),

                const SizedBox(height: 8),

                // ------------------------------------------------
                // CALENDAR
                // ------------------------------------------------

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
  // FILTER TITLE
  // ============================================================

  String get _filterTitle {
    if (_filterType ==
        _PastWalkFilterType.date) {
      return 'Date';
    }

    return 'Week';
  }

  // ============================================================
  // FILTER VALUE
  // ============================================================

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
  // MONTH NAME
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

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            DojoColors.orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          'Past Walks',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: Column(
        children: [
          // ======================================================
          // THIN DATE / WEEK BAR
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
                  // ----------------------------------------------
                  // DATE / WEEK ICON
                  // ----------------------------------------------

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

                  // ----------------------------------------------
                  // CURRENT VALUE
                  // ----------------------------------------------

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

                  // ----------------------------------------------
                  // CALENDAR BUTTON
                  // ----------------------------------------------

                  InkWell(
                    onTap: _pickDate,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        6,
                      ),
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

                  // ----------------------------------------------
                  // WEEK BUTTON
                  // ----------------------------------------------

                  InkWell(
                    onTap:
                        _showWeekPicker,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 6,
                      ),
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

          // ======================================================
          // WALK LIST
          // ======================================================

          Expanded(
            child: StreamBuilder<
                List<PastWalkModel>>(
              stream:
                  _watchPastWalks(),
              builder: (
                BuildContext context,
                AsyncSnapshot<
                        List<PastWalkModel>>
                    snapshot,
              ) {
                // ----------------------------------------------
                // LOADING
                // ----------------------------------------------

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

                // ----------------------------------------------
                // ERROR
                // ----------------------------------------------

                if (snapshot.hasError) {
                  return _ErrorState(
                    message:
                        'Unable to load past walks.',
                  );
                }

                // ----------------------------------------------
                // DATA
                // ----------------------------------------------

                final List<PastWalkModel>
                    walks =
                    snapshot.data ??
                        const <
                            PastWalkModel>[];

                // ----------------------------------------------
                // EMPTY
                // ----------------------------------------------

                if (walks.isEmpty) {
                  return _EmptyState(
                    filterValue:
                        _filterValue,
                  );
                }

                // ----------------------------------------------
                // LIST
                // ----------------------------------------------

                return ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24,
                  ),
                  itemCount:
                      walks.length,
                  separatorBuilder:
                      (
                    BuildContext context,
                    int index,
                  ) {
                    return const SizedBox(
                      height: 8,
                    );
                  },
                  itemBuilder:
                      (
                    BuildContext context,
                    int index,
                  ) {
                    final PastWalkModel
                        walk =
                        walks[index];

                    return SizedBox(
                      height: 64,
                      child:
                          PastWalkCard(
                        id:
                            walk.displayId,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          DojoColors.surface,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (
        BuildContext context,
      ) {
        return SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Row(
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
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color:
                            DojoColors.orange,
                        size: 25,
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
                            walk.displayId,
                            style:
                                const TextStyle(
                              color:
                                  DojoColors
                                      .dark,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            walk.status
                                .isEmpty
                                ? 'Completed'
                                : walk.status,
                            style:
                                const TextStyle(
                              color:
                                  DojoColors
                                      .green,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                // ------------------------------------------------
                // DOG
                // ------------------------------------------------

                _DetailRow(
                  label: 'Dog',
                  value:
                      walk.dogName.isEmpty
                          ? '—'
                          : walk.dogName,
                ),

                // ------------------------------------------------
                // BREED
                // ------------------------------------------------

                if (walk.dogBreed.isNotEmpty)
                  _DetailRow(
                    label: 'Breed',
                    value:
                        walk.dogBreed,
                  ),

                // ------------------------------------------------
                // OWNER
                // ------------------------------------------------

                _DetailRow(
                  label: 'Owner',
                  value:
                      walk.ownerName.isEmpty
                          ? '—'
                          : walk.ownerName,
                ),

                // ------------------------------------------------
                // TIME
                // ------------------------------------------------

                _DetailRow(
                  label: 'Time',
                  value:
                      walk.displayTime,
                ),

                // ------------------------------------------------
                // DISTANCE
                // ------------------------------------------------

                _DetailRow(
                  label: 'Distance',
                  value:
                      walk.distanceKm > 0
                          ? '${walk.distanceKm.toStringAsFixed(2)} km'
                          : walk.routeDistanceKm >
                                  0
                              ? '${walk.routeDistanceKm.toStringAsFixed(2)} km'
                              : '—',
                ),

                // ------------------------------------------------
                // DURATION
                // ------------------------------------------------

                _DetailRow(
                  label: 'Duration',
                  value:
                      walk.durationMinutes >
                              0
                          ? '${walk.durationMinutes.round()} min'
                          : walk.routeDurationMinutes >
                                  0
                              ? '${walk.routeDurationMinutes.round()} min'
                              : '—',
                ),

                // ------------------------------------------------
                // PEE
                // ------------------------------------------------

                _DetailRow(
                  label: 'Pee',
                  value:
                      walk.peeCount.toString(),
                ),

                // ------------------------------------------------
                // POOP
                // ------------------------------------------------

                _DetailRow(
                  label: 'Poop',
                  value:
                      walk.poopCount.toString(),
                ),

                // ------------------------------------------------
                // RATING
                // ------------------------------------------------

                _DetailRow(
                  label: 'Rating',
                  value:
                      walk.rating > 0
                          ? '${walk.rating}/5'
                          : '—',
                ),

                // ------------------------------------------------
                // WALKER NOTE
                // ------------------------------------------------

                if (walk.walkerNote
                    .isNotEmpty)
                  _DetailRow(
                    label: 'Note',
                    value:
                        walk.walkerNote,
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
          onTap: enabled
              ? onTap
              : null,
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
                  const BoxDecoration(
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

            const SizedBox(
              height: 16,
            ),

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

            const SizedBox(
              height: 6,
            ),

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
              Icons.cloud_off_rounded,
              color:
                  DojoColors
                      .textSecondary,
              size: 44,
            ),

            const SizedBox(
              height: 12,
            ),

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

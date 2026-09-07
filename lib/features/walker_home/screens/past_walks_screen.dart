import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/dojo_walker.dart';
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

  DateTime get _weekStart {
    return _startOfWeek(
      _selectedDate,
    );
  }

  DateTime get _weekEnd {
    return _weekStart.add(
      const Duration(days: 7),
    );
  }

  DateTime get _dateStart {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
  }

  DateTime get _dateEnd {
    return _dateStart.add(
      const Duration(days: 1),
    );
  }

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
      return !walkDate.isBefore(
            _dateStart,
          ) &&
          walkDate.isBefore(
            _dateEnd,
          );
    }

    return !walkDate.isBefore(
          _weekStart,
        ) &&
        walkDate.isBefore(
          _weekEnd,
        );
  }

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
                  DojoWalkerColors.primary,
              surface:
                  DojoWalkerColors.card,
              onSurface:
                  DojoWalkerColors.textPrimary,
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

  Future<void> _showWeekPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          DojoWalkerColors.card,
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
                        DojoWalkerColors.border,
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
                        DojoWalkerColors.textPrimary,
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
                          _PastWalkFilterType
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
                          _PastWalkFilterType
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

  bool get _canGoToNextWeek {
    final DateTime currentWeek =
        _startOfWeek(
      DateTime.now(),
    );

    return _weekStart.isBefore(
      currentWeek,
    );
  }

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

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          DojoWalkerColors.background,
      appBar: AppBar(
        backgroundColor:
            DojoWalkerColors.primary,
        foregroundColor:
            DojoWalkerColors.white,
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
          Material(
            color:
                DojoWalkerColors.card,
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
                        DojoWalkerColors.border,
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
                        DojoWalkerColors.textPrimary,
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
                            DojoWalkerColors
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
                            DojoWalkerColors.primary,
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
                                  DojoWalkerColors
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
                                DojoWalkerColors
                                    .textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          DojoWalkerColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const _ErrorState(
                    message:
                        'Unable to load past walks.',
                  );
                }

                final List<PastWalkModel>
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

  void _showWalkDetails(
    PastWalkModel walk,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          DojoWalkerColors.card,
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color:
                            DojoWalkerColors.light,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color:
                            DojoWalkerColors.primary,
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
                                  DojoWalkerColors
                                      .textPrimary,
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
                                  DojoWalkerColors
                                      .success,
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
                _DetailRow(
                  label: 'Dog',
                  value:
                      walk.dogName.isEmpty
                          ? '—'
                          : walk.dogName,
                ),
                if (walk.dogBreed.isNotEmpty)
                  _DetailRow(
                    label: 'Breed',
                    value:
                        walk.dogBreed,
                  ),
                _DetailRow(
                  label: 'Owner',
                  value:
                      walk.ownerName.isEmpty
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
                      walk.distanceKm > 0
                          ? '${walk.distanceKm.toStringAsFixed(2)} km'
                          : walk.routeDistanceKm >
                                  0
                              ? '${walk.routeDistanceKm.toStringAsFixed(2)} km'
                              : '—',
                ),
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
                _DetailRow(
                  label: 'Pee',
                  value:
                      walk.peeCount.toString(),
                ),
                _DetailRow(
                  label: 'Poop',
                  value:
                      walk.poopCount.toString(),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

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
            DojoWalkerColors.background,
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
                        DojoWalkerColors.light,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color:
                        DojoWalkerColors.primary,
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
                              DojoWalkerColors
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
                              DojoWalkerColors
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
                      DojoWalkerColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                    DojoWalkerColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                color:
                    DojoWalkerColors.primary,
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
                    DojoWalkerColors.textPrimary,
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
                    DojoWalkerColors
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
                  DojoWalkerColors.textSecondary,
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
                    DojoWalkerColors.textPrimary,
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
                    DojoWalkerColors
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
                    DojoWalkerColors.textPrimary,
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

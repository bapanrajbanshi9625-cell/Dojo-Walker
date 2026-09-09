// File:
// lib/features/my_walks/screens/past_walks_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker.dart';
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
  // ============================================================
  // DEFAULT FILTER
  // ============================================================

  _PastWalkFilterType _filterType =
      _PastWalkFilterType.week;

  DateTime _selectedDate =
      DateTime.now();

  // ============================================================
  // WEEK HELPERS
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
        days: day.weekday - DateTime.monday,
      ),
    );
  }

  DateTime _endOfWeek(
    DateTime date,
  ) {
    return _startOfWeek(date).add(
      const Duration(days: 7),
    );
  }

  bool _isInSelectedWeek(
    DateTime date,
  ) {
    final DateTime start =
        _startOfWeek(_selectedDate);

    final DateTime end =
        _endOfWeek(_selectedDate);

    return !date.isBefore(start) &&
        date.isBefore(end);
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // FILTER MATCH
  // ============================================================

  bool _matchesSelectedFilter(
    PastWalkModel walk,
  ) {
    final DateTime? activityDate =
        walk.activityDate;

    if (activityDate == null) {
      return false;
    }

    if (_filterType ==
        _PastWalkFilterType.date) {
      return _isSameDate(
        activityDate,
        _selectedDate,
      );
    }

    return _isInSelectedWeek(
      activityDate,
    );
  }

  // ============================================================
  // FIRESTORE STREAM
  //
  // Supports:
  // walkerId
  // walkerUid
  // ============================================================

  Stream<List<PastWalkModel>>
      _watchPastWalks() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(
        <PastWalkModel>[],
      );
    }

    final String uid = user.uid;

    final Stream<QuerySnapshot<
        Map<String, dynamic>>> walkerIdStream =
        FirebaseFirestore.instance
            .collection('walk_history')
            .where(
              'walkerId',
              isEqualTo: uid,
            )
            .snapshots();

    final Stream<QuerySnapshot<
        Map<String, dynamic>>> walkerUidStream =
        FirebaseFirestore.instance
            .collection('walk_history')
            .where(
              'walkerUid',
              isEqualTo: uid,
            )
            .snapshots();

    return _mergeWalkStreams(
      walkerIdStream,
      walkerUidStream,
    );
  }

  // ============================================================
  // MERGE BOTH QUERIES
  // ============================================================

  Stream<List<PastWalkModel>> _mergeWalkStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>>
        walkerIdStream,
    Stream<QuerySnapshot<Map<String, dynamic>>>
        walkerUidStream,
  ) async* {
    List<QueryDocumentSnapshot<
        Map<String, dynamic>>> walkerIdDocs =
        <QueryDocumentSnapshot<
            Map<String, dynamic>>>[];

    List<QueryDocumentSnapshot<
        Map<String, dynamic>>> walkerUidDocs =
        <QueryDocumentSnapshot<
            Map<String, dynamic>>>[];

    await for (final dynamic event
        in _combineStreams(
      walkerIdStream,
      walkerUidStream,
    )) {
      walkerIdDocs = event.$1;
      walkerUidDocs = event.$2;

      final Map<String,
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>
          uniqueDocuments =
          <String,
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>{};

      for (final doc in walkerIdDocs) {
        uniqueDocuments[doc.id] = doc;
      }

      for (final doc in walkerUidDocs) {
        uniqueDocuments[doc.id] = doc;
      }

      final List<PastWalkModel> walks =
          uniqueDocuments.values
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
              a.activityDate ??
                  DateTime
                      .fromMillisecondsSinceEpoch(
                0,
              );

          final DateTime bDate =
              b.activityDate ??
                  DateTime
                      .fromMillisecondsSinceEpoch(
                0,
              );

          return bDate.compareTo(aDate);
        },
      );

      yield walks;
    }
  }

  // ============================================================
  // COMBINE STREAMS
  // ============================================================

  Stream<
      (
        List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>,
        List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
      )> _combineStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>>
        first,
    Stream<QuerySnapshot<Map<String, dynamic>>>
        second,
  ) async* {
    List<QueryDocumentSnapshot<
        Map<String, dynamic>>> firstDocs =
        <QueryDocumentSnapshot<
            Map<String, dynamic>>>[];

    List<QueryDocumentSnapshot<
        Map<String, dynamic>>> secondDocs =
        <QueryDocumentSnapshot<
            Map<String, dynamic>>>[];

    bool firstReady = false;
    bool secondReady = false;

    late final StreamSubscription<
        QuerySnapshot<Map<String, dynamic>>>
        firstSubscription;

    late final StreamSubscription<
        QuerySnapshot<Map<String, dynamic>>>
        secondSubscription;

    final StreamController<
        (
          List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>,
          List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>
        )> controller =
        StreamController<
            (
              List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>,
              List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>
            )>();

    firstSubscription = first.listen(
      (
        QuerySnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        firstDocs = snapshot.docs;
        firstReady = true;

        if (firstReady && secondReady) {
          controller.add(
            (
              firstDocs,
              secondDocs,
            ),
          );
        }
      },
      onError: controller.addError,
    );

    secondSubscription = second.listen(
      (
        QuerySnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        secondDocs = snapshot.docs;
        secondReady = true;

        if (firstReady && secondReady) {
          controller.add(
            (
              firstDocs,
              secondDocs,
            ),
          );
        }
      },
      onError: controller.addError,
    );

    try {
      await for (final value
          in controller.stream) {
        yield value;
      }
    } finally {
      await firstSubscription.cancel();
      await secondSubscription.cancel();
      await controller.close();
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickDate() async {
    final DateTime now =
        DateTime.now();

    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate:
          _selectedDate.isAfter(now)
              ? now
              : _selectedDate,
      firstDate: DateTime(
        2020,
        1,
        1,
      ),
      lastDate: now,
      helpText: 'Select walk date',
    );

    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _filterType =
          _PastWalkFilterType.date;

      _selectedDate = picked;
    });
  }

  // ============================================================
  // WEEK PICKER
  // ============================================================

  Future<void> _showWeekPicker() async {
    final String? result =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (
        BuildContext context,
      ) {
        return SafeArea(
          child: Container(
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: Colors.black26,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Text(
                  'Filter Past Walks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                _WeekActionTile(
                  icon:
                      Icons.calendar_view_week,
                  title:
                      'Current Week',
                  subtitle:
                      _weekRangeText(
                    DateTime.now(),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'current',
                    );
                  },
                ),
                _WeekActionTile(
                  icon:
                      Icons.history,
                  title:
                      'Previous Week',
                  subtitle:
                      _weekRangeText(
                    _startOfWeek(
                      DateTime.now(),
                    ).subtract(
                      const Duration(
                        days: 7,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'previous',
                    );
                  },
                ),
                if (_canGoToNextWeek())
                  _WeekActionTile(
                    icon:
                        Icons.arrow_forward,
                    title:
                        'Next Week',
                    subtitle:
                        _weekRangeText(
                      _startOfWeek(
                        DateTime.now(),
                      ).add(
                        const Duration(
                          days: 7,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        'next',
                      );
                    },
                  ),
                _WeekActionTile(
                  icon:
                      Icons.event,
                  title:
                      'Choose Date',
                  subtitle:
                      'View walks for a specific date',
                  onTap: () {
                    Navigator.pop(
                      context,
                      'date',
                    );
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        result == null) {
      return;
    }

    switch (result) {
      case 'current':
        setState(() {
          _filterType =
              _PastWalkFilterType.week;
          _selectedDate =
              DateTime.now();
        });
        break;

      case 'previous':
        setState(() {
          _filterType =
              _PastWalkFilterType.week;
          _selectedDate =
              _startOfWeek(
                DateTime.now(),
              ).subtract(
                const Duration(
                  days: 7,
                ),
              );
        });
        break;

      case 'next':
        setState(() {
          _filterType =
              _PastWalkFilterType.week;
          _selectedDate =
              _startOfWeek(
                DateTime.now(),
              ).add(
                const Duration(
                  days: 7,
                ),
              );
        });
        break;

      case 'date':
        await _pickDate();
        break;
    }
  }

  // ============================================================
  // NEXT WEEK LIMIT
  // ============================================================

  bool _canGoToNextWeek() {
    final DateTime selectedWeekStart =
        _startOfWeek(_selectedDate);

    final DateTime currentWeekStart =
        _startOfWeek(
      DateTime.now(),
    );

    return selectedWeekStart
        .isBefore(
      currentWeekStart,
    );
  }

  // ============================================================
  // WEEK TEXT
  // ============================================================

  String _weekRangeText(
    DateTime date,
  ) {
    final DateTime start =
        _startOfWeek(date);

    final DateTime end =
        start.add(
      const Duration(
        days: 6,
      ),
    );

    return '${_formatShortDate(start)} - '
        '${_formatShortDate(end)}';
  }

  String _formatShortDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

  String get _filterValue {
    if (_filterType ==
        _PastWalkFilterType.date) {
      return _formatShortDate(
        _selectedDate,
      );
    }

    return _weekRangeText(
      _selectedDate,
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
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (
        BuildContext context,
      ) {
        return SafeArea(
          child: Container(
            constraints:
                const BoxConstraints(
              maxHeight: 620,
            ),
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color: Colors.black26,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color:
                              DojoWalkerColors
                                  .primary
                                  .withOpacity(
                            0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          color:
                              DojoWalkerColors
                                  .primary,
                          size: 27,
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
                              walk.dogName
                                      .isNotEmpty
                                  ? walk.dogName
                                  : 'Dog Walk',
                              style:
                                  const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              walk.dogBreed
                                      .isNotEmpty
                                  ? walk.dogBreed
                                  : 'Completed Walk',
                              style:
                                  const TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.green
                                  .withOpacity(
                            0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: const Text(
                          'DONE',
                          style:
                              TextStyle(
                            color:
                                Colors.green,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  _DetailRow(
                    icon: Icons
                        .confirmation_number_outlined,
                    title: 'Walk ID',
                    value:
                        walk.displayId,
                  ),

                  _DetailRow(
                    icon:
                        Icons.person_outline,
                    title: 'Owner',
                    value:
                        walk.ownerName.isNotEmpty
                            ? walk.ownerName
                            : '—',
                  ),

                  _DetailRow(
                    icon:
                        Icons.access_time_rounded,
                    title: 'Time',
                    value:
                        walk.displayTime,
                  ),

                  _DetailRow(
                    icon:
                        Icons.route_rounded,
                    title: 'Distance',
                    value:
                        walk.effectiveDistanceKm >
                                0
                            ? '${walk.effectiveDistanceKm.toStringAsFixed(1)} km'
                            : '—',
                  ),

                  _DetailRow(
                    icon:
                        Icons.timer_outlined,
                    title: 'Duration',
                    value:
                        walk.effectiveDurationMinutes >
                                0
                            ? '${walk.effectiveDurationMinutes.round()} min'
                            : '—',
                  ),

                  _DetailRow(
                    icon:
                        Icons.water_drop_outlined,
                    title: 'Pee',
                    value:
                        '${walk.peeCount}',
                  ),

                  _DetailRow(
                    icon:
                        Icons.circle_outlined,
                    title: 'Poop',
                    value:
                        '${walk.poopCount}',
                  ),

                  if (walk.rating > 0)
                    _DetailRow(
                      icon: Icons
                          .star_outline_rounded,
                      title: 'Rating',
                      value:
                          '${walk.rating}/5',
                    ),

                  if (walk.walkerNote
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      'Walker Note',
                      style:
                          TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Container(
                      width:
                          double.infinity,
                      padding:
                          const EdgeInsets
                              .all(14),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Text(
                        walk.walkerNote,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
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
          Theme.of(context)
              .scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Past Walks',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _showWeekPicker,
            icon: const Icon(
              Icons.tune_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ======================================================
          // FILTER BAR
          // ======================================================

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              10,
            ),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(14),
              onTap: _showWeekPicker,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration:
                          BoxDecoration(
                        color:
                            DojoWalkerColors
                                .primary
                                .withOpacity(
                          0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Icon(
                        _filterType ==
                                _PastWalkFilterType
                                    .date
                            ? Icons.event
                            : Icons
                                .calendar_view_week,
                        color:
                            DojoWalkerColors
                                .primary,
                        size: 21,
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
                            _filterTitle,
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.black54,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            _filterValue,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color:
                          Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // WALKS
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
                if (snapshot
                            .connectionState ==
                        ConnectionState
                            .waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message:
                        'Unable to load past walks.',
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final List<
                        PastWalkModel>
                    walks =
                    snapshot.data ??
                        <PastWalkModel>[];

                if (walks.isEmpty) {
                  return _EmptyState(
                    filterValue:
                        _filterValue,
                    onChangeFilter:
                        _showWeekPicker,
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    4,
                    16,
                    32,
                  ),
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      walks.length,
                  separatorBuilder:
                      (
                    BuildContext context,
                    int index,
                  ) {
                    return const SizedBox(
                      height: 10,
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
                      child: PastWalkCard(
                        id: walk.displayId,
                        time:
                            walk.displayTime,
                        details:
                            walk.displayDetails,
                        onTap: () =>
                            _showWalkDetails(
                          walk,
                        ),
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
}

// ============================================================
// WEEK ACTION TILE
// ============================================================

class _WeekActionTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 3,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration:
            BoxDecoration(
          color:
              DojoWalkerColors
                  .primary
                  .withOpacity(
            0.10,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color:
              DojoWalkerColors.primary,
        ),
      ),
      title: Text(
        title,
        style:
            const TextStyle(
          fontWeight:
              FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style:
            const TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      trailing:
          const Icon(
        Icons.chevron_right_rounded,
      ),
      onTap: onTap,
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState
    extends StatelessWidget {
  final String filterValue;
  final VoidCallback onChangeFilter;

  const _EmptyState({
    required this.filterValue,
    required this.onChangeFilter,
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
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color:
                    DojoWalkerColors
                        .primary
                        .withOpacity(
                  0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .directions_walk_rounded,
                color:
                    DojoWalkerColors
                        .primary,
                size: 38,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No Past Walks',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'No completed walks found for\n'
              '$filterValue.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            OutlinedButton.icon(
              onPressed:
                  onChangeFilter,
              icon: const Icon(
                Icons
                    .filter_alt_outlined,
              ),
              label:
                  const Text(
                'Change Filter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ErrorState
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
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
                  .error_outline_rounded,
              size: 52,
              color:
                  Colors.redAccent,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Colors.black54,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton(
              onPressed: onRetry,
              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color:
                Colors.black54,
          ),

          const SizedBox(
            width: 12,
          ),

          SizedBox(
            width: 82,
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Colors.black54,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
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

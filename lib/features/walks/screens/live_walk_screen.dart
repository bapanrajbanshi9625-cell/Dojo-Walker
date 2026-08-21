import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/live_walk_map.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_sos_sheet.dart';
import '../services/walk_request_service.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    required this.dogName,
    this.dogBreed = '',
    this.ownerPhone,
    this.sessionId,
  });

  final String ownerUid;
  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;
  final String? sessionId;

  @override
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  static const Color orange = Color(0xFFFF6600);
  static const Color dark = Color(0xFF263746);
  static const Color red = Color(0xFFE53935);

  final WalkRequestService _service =
      WalkRequestService.instance;

  bool _ending = false;

  String get sessionId {
    final value = widget.sessionId?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return widget.walkId;
  }

  DocumentReference<Map<String, dynamic>> get _sessionRef {
    return FirebaseFirestore.instance
        .collection('liveWalkSessions')
        .doc(sessionId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _sessionStream {
    return _sessionRef.snapshots();
  }

  Future<void> _endWalk() async {
    if (_ending) return;

    setState(() {
      _ending = true;
    });

    try {
      await _service.endLiveWalk(
        widget.walkId,
        sessionId: sessionId,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _ending = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
            ),
          ),
        );
    }
  }

  void _confirmEndWalk() {
    if (_ending) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'End Walk?',
            style: TextStyle(
              color: dark,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
            style: TextStyle(
              color: Color(0xFF7A8289),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Keep Walking',
                style: TextStyle(
                  color: dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _endWalk();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'End Walk',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openSupport() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE0),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(
                  Icons.support_agent_rounded,
                  color: orange,
                  size: 38,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Walk Support',
                  style: TextStyle(
                    color: dark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Need help during this walk?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7A8289),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.support_agent_rounded,
                    ),
                    label: const Text(
                      'Contact Support',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSos() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return const LiveWalkSosSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (context, snapshot) {
        final data =
            snapshot.data?.data() ??
                <String, dynamic>{};

        final String status =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                'live';

        if (status == 'completed' ||
            status == 'ended') {
          return _completedScreen(data);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,

          appBar: AppBar(
            backgroundColor: orange,
            surfaceTintColor: orange,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'LIVE WALK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'SOS',
                onPressed: _openSos,
                icon: const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Support',
                onPressed: _openSupport,
                icon: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          body: Stack(
            children: [
              Positioned.fill(
                child: LiveWalkMap(
                  sessionData: data,
                ),
              ),

              Positioned(
                top: MediaQuery.of(context)
                        .padding
                        .top +
                    62,
                left: 16,
                child: _liveBadge(),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: LiveWalkBottomSheet(
                  ownerName: widget.ownerName,
                  dogName: widget.dogName,
                  dogBreed: widget.dogBreed,
                  ownerPhone: widget.ownerPhone,
                  sessionData: data,
                  ending: _ending,
                  onEndWalk: _confirmEndWalk,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: Color(0xFF16A34A),
            size: 9,
          ),
          SizedBox(width: 7),
          Text(
            'LIVE',
            style: TextStyle(
              color: dark,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedScreen(
    Map<String, dynamic> data,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 80,
              ),
              const SizedBox(height: 18),
              const Text(
                'Walk Completed',
                style: TextStyle(
                  color: dark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Walker Home',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

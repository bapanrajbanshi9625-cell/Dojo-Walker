// File: lib/screens/walks_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/insta_walk/widgets/insta_walk_search_panel.dart';
import '../services/walker_availability_service.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({
    super.key,
  });

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen>
    with WidgetsBindingObserver {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // WALKER
  // ============================================================

  String? _walkerUid;
  String? _walkerId;

  // ============================================================
  // SEARCH
  // ============================================================

  bool _searching = false;
  bool _loading = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _walkerUid = _auth.currentUser?.uid;

    unawaited(_loadWalkerState());
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.detached &&
        _searching) {
      unawaited(_stopSearchState());
    }
  }

  // ============================================================
  // LOAD WALKER STATE
  // ============================================================

  Future<void> _loadWalkerState() async {
    final String? uid = _walkerUid;

    if (uid == null || uid.trim().isEmpty) {
      return;
    }

    try {
      // --------------------------------------------------------
      // WALKER ID
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>>
          account =
          await _firestore
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      final Map<String, dynamic>? accountData =
          account.data();

      final String savedWalkerId =
          accountData?['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (savedWalkerId.isNotEmpty) {
        _walkerId = savedWalkerId;
      }

      // --------------------------------------------------------
      // SEARCH STATE
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>>
          userDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .get();

      final Map<String, dynamic>? userData =
          userDoc.data();

      final bool searching =
          userData?['instaWalkSearching'] == true;

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = searching;
      });
    } catch (e) {
      debugPrint(
        'Walker state error: $e',
      );
    }
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    final String cached =
        _walkerId?.trim() ?? '';

    if (cached.isNotEmpty) {
      return cached;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(user.uid)
              .get();

      final String id =
          snapshot.data()?['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (id.isEmpty) {
        return null;
      }

      _walkerId = id;

      return id;
    } catch (e) {
      debugPrint(
        'Walker ID error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // START SEARCH
  //
  // This only enables the Walker's search state.
  //
  // Incoming request detection is handled globally by app.dart.
  // ============================================================

  Future<void> _startSearch() async {
    if (_loading) {
      return;
    }

    // ----------------------------------------------------------
    // GLOBAL AVAILABILITY GUARD
    // ----------------------------------------------------------

    final WalkerAvailabilityService availability =
        WalkerAvailabilityService.instance;

    if (!availability.isOnline) {
      _showMessage(
        'You are Offline. Go Online to search for Insta Walk requests.',
      );
      return;
    }

    if (!availability.canPerformWalkAction()) {
      _showMessage(
        availability.unavailableMessage,
      );
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.isEmpty) {
      _showMessage(
        'Walker ID is not available. '
        'Please complete your Walker profile.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // CHECK AGAIN AFTER ASYNC WALKER ID LOAD
    // ----------------------------------------------------------

    if (!availability.isOnline) {
      _showMessage(
        'You are Offline. Go Online to search for Insta Walk requests.',
      );
      return;
    }

    if (!availability.canPerformWalkAction()) {
      _showMessage(
        availability.unavailableMessage,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // --------------------------------------------------------
      // FINAL ONLINE CHECK BEFORE FIRESTORE WRITE
      // --------------------------------------------------------

      if (!availability.isOnline) {
        if (mounted) {
          setState(() {
            _loading = false;
          });

          _showMessage(
            'You are Offline. Go Online to search for Insta Walk requests.',
          );
        }
        return;
      }

      if (!availability.canPerformWalkAction()) {
        if (mounted) {
          setState(() {
            _loading = false;
          });

          _showMessage(
            availability.unavailableMessage,
          );
        }
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'walkerId': walkerId,
          'instaWalkSearching': true,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _walkerUid = user.uid;
        _walkerId = walkerId;
        _searching = true;
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Start Insta Walk error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to start Insta Walk search.',
      );
    }
  }

  // ============================================================
  // STOP SEARCH STATE
  // ============================================================

  Future<void> _stopSearchState({
    bool clearRequests = true,
  }) async {
    final String? uid =
        _walkerUid ??
            _auth.currentUser?.uid;

    if (uid == null ||
        uid.trim().isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(
        <String, dynamic>{
          'instaWalkSearching': false,
          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searching = false;
      });
    } catch (e) {
      debugPrint(
        'Stop search error: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // SEARCH BUTTON
  // ============================================================

  void _searchButtonPressed() {
    if (_searching) {
      _showStopDialog();
    } else {
      _startSearch();
    }
  }

  // ============================================================
  // STOP DIALOG
  // ============================================================

  Future<void> _showStopDialog() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Stop Searching?',
          ),
          content: const Text(
            'You will stop receiving nearby '
            'Insta Walk requests.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Confirm',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true ||
        !mounted) {
      return;
    }

    try {
      await _stopSearchState();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to stop searching.',
        );
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    super.dispose();
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
      body: ListView(
        padding: const EdgeInsets.only(
          bottom: 30,
        ),
        children: <Widget>[
          InstaWalkSearchPanel(
            searching: _searching,
          ),
        ],
      ),
    );
  }
}

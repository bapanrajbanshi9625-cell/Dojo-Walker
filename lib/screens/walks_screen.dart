// File: lib/screens/walks_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/insta_walk/widgets/insta_walk_search_panel.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({
    super.key,
  });

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String? _walkerUid;
  bool _searching = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _walkerUid = _auth.currentUser?.uid;

    unawaited(_loadWalkerState());
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.detached &&
        _searching) {
      unawaited(_stopSearchState());
    }
  }

  Future<void> _loadWalkerState() async {
    final String? uid = _walkerUid;

    if (uid == null || uid.trim().isEmpty) {
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
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

  Future<void> _stopSearchState() async {
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
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

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

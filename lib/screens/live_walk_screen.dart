// File location: lib/screens/live_walk_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    this.ownerPhone,
  });

  final String ownerUid;
  final String ownerName;
  final String walkId;
  final String? ownerPhone;

  @override
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  bool _isEndingWalk = false;

  DocumentReference<Map<String, dynamic>> get _walkRef =>
      FirebaseFirestore.instance
          .collection('active_walks')
          .doc(widget.walkId);

  // ======================================================
  // END WALK → FIREBASE
  // ======================================================

  Future<void> _endWalk() async {
    if (_isEndingWalk) return;

    setState(() {
      _isEndingWalk = true;
    });

    try {
      await _walkRef.update({
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isEndingWalk = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not end walk: $e'),
        ),
      );
    }
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _walkRef.snapshots(),
      builder: (context, snapshot) {
        String status = 'active';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();

          if (data != null) {
            status =
                data['status']?.toString() ?? 'active';
          }
        }

        // Firebase se walk completed ho gayi
        if (status != 'active') {
          return _completedScreen();
        }

        return _activeWalkScreen();
      },
    );
  }

  // ======================================================
  // ACTIVE WALK SCREEN
  // ======================================================

  Widget _activeWalkScreen() {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Live Walk',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // ACTIVE STATUS
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              color: Colors.blue.shade700,
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    'Walk Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.directions_walk,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ==========================================
                    // OWNER INFORMATION
                    // ==========================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withAlpha(15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.blue.shade700,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Owner',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  widget.ownerName.isEmpty
                                      ? 'Owner'
                                      : widget.ownerName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'UID: ${widget.ownerUid}',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),

                                if (widget.ownerPhone != null &&
                                    widget.ownerPhone!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.ownerPhone!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color:
                                    Colors.green.shade700,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==========================================
                    // LIVE MAP
                    // ==========================================

                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 55,
                                  color: Colors.black38,
                                ),

                                SizedBox(height: 10),

                                Text(
                                  'Live Map',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  'Walker location will appear here',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            left: 15,
                            top: 15,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withAlpha(20),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 17,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Live Location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==========================================
                    // WALK STATS
                    // ==========================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.timer_outlined,
                            title: 'Duration',
                            value: '00:00:00',
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            icon: Icons.route,
                            title: 'Distance',
                            value: '0.0 km',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.directions_walk,
                            title: 'Steps',
                            value: '0',
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _statCard(
                            icon: Icons.speed,
                            title: 'Status',
                            value: 'Active',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // END WALK
                    // ==========================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isEndingWalk
                            ? null
                            : _showEndWalkDialog,
                        icon: _isEndingWalk
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.stop_circle_outlined,
                              ),
                        label: Text(
                          _isEndingWalk
                              ? 'Ending Walk...'
                              : 'End Walk',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // STAT CARD
  // ======================================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.blue.shade700,
            size: 27,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // END WALK CONFIRMATION
  // ======================================================

  void _showEndWalkDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'End Walk?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to end this walk?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _endWalk();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('End Walk'),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // WALK COMPLETED SCREEN
  // ======================================================

  Widget _completedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        title: const Text(
          'Live Walk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
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
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade600,
              ),

              const SizedBox(height: 20),

              const Text(
                'Walk Completed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'This walk is no longer active.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Walker Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

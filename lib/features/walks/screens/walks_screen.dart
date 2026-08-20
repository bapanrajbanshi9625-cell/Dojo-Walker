import 'package:flutter/material.dart';

import '../models/walk_request.dart';
import '../services/walk_request_service.dart';
import '../widgets/insta_walk_container.dart';
import '../widgets/walk_request_card.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  static const Color orange = Color(0xFFFF6600);
  static const Color dark = Color(0xFF263746);
  static const Color background = Color(0xFFF5F6F8);

  // ============================================================
  // SERVICE
  // ============================================================

  static final WalkRequestService _service =
      WalkRequestService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 18,
        title: const Text(
          'Walks',
          style: TextStyle(
            color: dark,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: orange,
            ),
          ),
        ],
      ),

      // ========================================================
      // WALK REQUESTS
      // ========================================================

      body: StreamBuilder<List<WalkRequest>>(
        stream: _service.pendingRequestsStream(),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 30,
            ),
            children: [
              // ==================================================
              // INSTA WALK
              // ==================================================

              const InstaWalkContainer(),

              const SizedBox(height: 18),

              // ==================================================
              // LOADING
              // ==================================================

              if (snapshot.connectionState ==
                  ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(25),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: orange,
                    ),
                  ),
                ),

              // ==================================================
              // ERROR
              // ==================================================

              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: orange,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to load walk requests.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: dark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // ==================================================
              // EMPTY
              // ==================================================

              if (!snapshot.hasError &&
                  snapshot.connectionState !=
                      ConnectionState.waiting &&
                  requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    10,
                  ),
                  child: Center(
                    child: Text(
                      'No new walk requests right now.',
                      style: TextStyle(
                        color: Color(0xFF7A8289),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // ==================================================
              // REQUEST CARDS
              // ==================================================

              ...requests.map(
                (request) => WalkRequestCard(
                  request: request,
                  onAccept: () => _acceptWalk(
                    context,
                    request,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<void> _acceptWalk(
    BuildContext context,
    WalkRequest request,
  ) async {
    try {
      await _service.acceptWalk(request.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Walk accepted successfully.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

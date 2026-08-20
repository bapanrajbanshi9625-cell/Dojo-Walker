import 'package:flutter/material.dart';

import '../models/walk_request.dart';
import '../services/walk_request_service.dart';
import '../widgets/insta_walk_container.dart';
import '../widgets/walk_request_card.dart';
import '../services/walk_request_sound_service.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({
    super.key,
  });

  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFFF6600);

  static const Color dark =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFF5F6F8);

  static const Color softOrange =
      Color(0xFFFFF1EA);

  static const Color mutedText =
      Color(0xFF7A8289);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
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
            margin: const EdgeInsets.only(
              right: 16,
            ),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: softOrange,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: orange,
              size: 22,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: StreamBuilder<List<WalkRequest>>(
        stream: WalkRequestService
            .instance
            .pendingRequestsStream(),

        builder: (
          BuildContext context,
          AsyncSnapshot<List<WalkRequest>> snapshot,
        ) {
          final List<WalkRequest> requests =
              snapshot.data ??
                  <WalkRequest>[];

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

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // LOADING
              // ==================================================

              if (snapshot.connectionState ==
                  ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(25),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color: orange,
                    ),
                  ),
                ),

              // ==================================================
              // ERROR
              // ==================================================

              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Unable to load walk requests.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // ==================================================
              // WALK REQUESTS
              // ==================================================

              if (!snapshot.hasError)
                ...requests.map(
                  (
                    WalkRequest request,
                  ) {
                    return WalkRequestCard(
                      request: request,

                      onAccept: () {
                        _acceptWalk(
                          context,
                          request,
                        );
                      },
                    );
                  },
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
      await WalkRequestService
          .instance
          .acceptWalk(
        request.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walk accepted successfully.',
            ),
          ),
        );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message,
            ),
          ),
        );
    }
  }
}

import 'package:flutter/material.dart';

import '../../my_walks/models/past_walk_model.dart';
import '../services/walker_home_service.dart';
import '../widgets/past_walk_card.dart';
import '../widgets/section_title.dart';

class PastWalksContainer extends StatelessWidget {
  final void Function({
    required String title,
    required String description,
    required IconData icon,
  }) onDetails;

  PastWalksContainer({
    super.key,
    required this.onDetails,
  });

  final WalkerHomeService _service = WalkerHomeService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: 'Past Walks',
        ),

        const SizedBox(height: 8),

        StreamBuilder<List<PastWalkModel>>(
          stream: _service.watchPastWalks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return const _ErrorState(
                message: 'Unable to load past walks.',
              );
            }

            final List<PastWalkModel> walks =
                snapshot.data ?? const <PastWalkModel>[];

            if (walks.isEmpty) {
              return const _EmptyState();
            }

            return Column(
              children: walks.map((walk) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: SizedBox(
                    height: 64,
                    child: PastWalkCard(
                      id: walk.displayId,
                      time: walk.displayTime,
                      details: walk.displayDetails,
                      onTap: () {
                        onDetails(
                          title: 'Walk ${walk.displayId}',
                          icon: Icons.pets_rounded,
                          description: _buildDetails(walk),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _buildDetails(PastWalkModel walk) {
    final List<String> details = <String>[
      if (walk.dogName.isNotEmpty)
        'Dog: ${walk.dogName}',
      if (walk.ownerName.isNotEmpty)
        'Owner: ${walk.ownerName}',
      if (walk.dogBreed.isNotEmpty)
        'Breed: ${walk.dogBreed}',
      'Time: ${walk.displayTime}',
      if (walk.status.isNotEmpty)
        'Status: ${walk.status}',
      if (walk.effectiveDistanceKm > 0)
        'Distance: '
            '${walk.effectiveDistanceKm.toStringAsFixed(1)} km',
      if (walk.effectiveDurationMinutes > 0)
        'Duration: '
            '${walk.effectiveDurationMinutes.round()} min',
      if (walk.peeCount > 0)
        'Pee: ${walk.peeCount}',
      if (walk.poopCount > 0)
        'Poop: ${walk.poopCount}',
      if (walk.rating > 0)
        'Rating: ${walk.rating}/5',
      if (walk.walkerNote.isNotEmpty)
        'Note: ${walk.walkerNote}',
    ];

    return details.join('\n');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.pets_rounded,
            size: 30,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No past walks yet',
            style: TextStyle(
              color: Color(0xFF27394A),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your completed walks will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A8491),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A8491),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

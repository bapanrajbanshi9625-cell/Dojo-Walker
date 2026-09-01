import 'package:flutter/material.dart';

import '../models/past_walk_model.dart';
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Unable to load past walks.',
              );
            }

            final walks = snapshot.data ?? const <PastWalkModel>[];

            if (walks.isEmpty) {
              return const _EmptyState();
            }

            return Column(
              children: walks.map((walk) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 64,
                    child: PastWalkCard(
                      id: walk.id,
                      time: walk.time,
                      details: walk.details,
                      onTap: () {
                        onDetails(
                          title: 'Walk ${walk.id}',
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
    final details = <String>[
      'Dog: ${walk.dogName}',
      'Owner: ${walk.ownerName}',
      if (walk.time != 'Completed') 'Time: ${walk.time}',
      if (walk.status.isNotEmpty) 'Status: ${walk.status}',
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

import 'package:flutter/material.dart';

import '../walker_home_features.dart';
import '../widgets/section_title.dart';
import '../widgets/past_walk_card.dart';

class PastWalksContainer extends StatelessWidget {
  final void Function({
    required String title,
    required String description,
    required IconData icon,
  }) onDetails;

  const PastWalksContainer({
    super.key,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: 'Past Walks',
        ),

        const SizedBox(height: 8),

        ...WalkerHomeFeatures.pastWalks.map(
          (walk) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 64,
                child: PastWalkCard(
                  id: walk['id']!,
                  time: walk['time']!,
                  details: walk['details']!,
                  onTap: () {
                    onDetails(
                      title: 'Walk ${walk['id']}',
                      icon: Icons.pets_rounded,
                      description:
                          WalkerHomeFeatures.pastWalkDetails(walk),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

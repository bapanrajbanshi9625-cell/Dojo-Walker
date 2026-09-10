import 'package:flutter/material.dart';

import '../../contacts/screens/chat_screen.dart';
import 'live_walk_complete_slider.dart';

class LiveWalkBottomSheet extends StatelessWidget {
  const LiveWalkBottomSheet({
    super.key,
    required this.scrollController,
    required this.ending,
    required this.ownerUid,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.distanceKm,
    required this.steps,
    required this.duration,
    required this.peeCount,
    required this.poopCount,
    required this.onCallOwner,
    required this.onActivityConfirmed,
    required this.onComplete,
    this.ownerPhotoUrl,
    this.onVoiceInteraction,
  });

  final ScrollController scrollController;
  final bool ending;

  final String ownerUid;
  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhotoUrl;

  final double distanceKm;
  final int steps;
  final String duration;

  final int peeCount;
  final int poopCount;

  final VoidCallback onCallOwner;
  final Future<void> Function(String type) onActivityConfirmed;
  final VoidCallback onComplete;
  final VoidCallback? onVoiceInteraction;

  static const Color _orange = Color(0xFFFF6B35);
  static const Color _green = Color(0xFF22A06B);
  static const Color _red = Color(0xFFE45151);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, -5),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          28,
        ),
        children: <Widget>[
          _buildDragHandle(),
          const SizedBox(height: 14),
          _buildOwnerDogHeader(),
          const SizedBox(height: 18),
          if (!ending) ...<Widget>[
            _buildLiveStatus(),
            const SizedBox(height: 14),
            _buildLiveStats(),
            const SizedBox(height: 16),
            _buildActivities(),
            const SizedBox(height: 18),
            _buildCommunicationButtons(context),
            const SizedBox(height: 12),
            _buildVoiceInteractionButton(),
            const SizedBox(height: 18),
            _buildCompleteSection(),
          ] else
            _buildEndingSection(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildOwnerDogHeader() {
    final bool hasPhoto =
        ownerPhotoUrl != null && ownerPhotoUrl!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            image: hasPhoto
                ? DecorationImage(
                    image: NetworkImage(ownerPhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasPhoto
              ? const Icon(
                  Icons.person_rounded,
                  color: _orange,
                  size: 28,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ownerName.trim().isEmpty ? 'Owner' : ownerName.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dogBreed.trim().isEmpty
                    ? dogName
                    : '$dogName • $dogBreed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.verified_rounded,
                size: 15,
                color: _green,
              ),
              SizedBox(width: 4),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _orange.withValues(alpha: 0.16),
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.directions_walk_rounded,
            color: _orange,
            size: 21,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'WALKING • LIVE',
              style: TextStyle(
                color: _orange,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Icon(
            Icons.circle,
            size: 9,
            color: _green,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStats() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            label: 'MINUTES',
            value: duration,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.route_rounded,
            label: 'KM',
            value: distanceKm.toStringAsFixed(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_walk_rounded,
            label: 'STEPS',
            value: steps.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEDEDED),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: _orange,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202124),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'DOG ACTIVITIES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF555555),
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildActivityButton(
                icon: Icons.water_drop_rounded,
                title: 'PEE',
                count: peeCount,
                iconColor: _green,
                onTap: () => onActivityConfirmed('Pee'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActivityButton(
                icon: Icons.circle_rounded,
                title: 'POOP',
                count: poopCount,
                iconColor: _red,
                onTap: () => onActivityConfirmed('Poop'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityButton({
    required IconData icon,
    required String title,
    required int count,
    required Color iconColor,
    required Future<void> Function() onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            await onTap();
          } catch (_) {
            // Parent controller handles the error.
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE6E6E6),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF292929),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 28,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunicationButtons(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onCallOwner,
              icon: const Icon(
                Icons.phone_rounded,
                size: 19,
              ),
              label: const Text(
                'CALL OWNER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,
                side: const BorderSide(
                  color: _orange,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                final String name = ownerName.trim().isEmpty
                    ? 'Owner'
                    : ownerName.trim();

                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(
                      otherUid: ownerUid,
                      contactName: name,
                      contactPhotoUrl: ownerPhotoUrl,
                      currentUserIsWalker: true,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 19,
              ),
              label: const Text(
                'CHAT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,
                side: const BorderSide(
                  color: _orange,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInteractionButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onVoiceInteraction,
        icon: const Icon(
          Icons.mic_rounded,
          size: 21,
        ),
        label: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'VOICE INTERACTION',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Talk with the owner',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _orange,
          side: BorderSide(
            color: _orange.withValues(alpha: 0.65),
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteSection() {
    return LiveWalkCompleteSlider(
      enabled: !ending,
      onCompleted: onComplete,
    );
  }

  Widget _buildEndingSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: <Widget>[
          SizedBox(height: 4),
          Icon(
            Icons.check_circle_rounded,
            color: _orange,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Completing Walk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202124),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Please wait while the walk is being completed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

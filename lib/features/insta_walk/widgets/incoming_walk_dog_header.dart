import 'package:flutter/material.dart';

class IncomingWalkDogHeader extends StatelessWidget {
  const IncomingWalkDogHeader({
    super.key,
    required this.dogName,
    required this.dogBreed,
    required this.ownerName,
  });

  final String dogName;
  final String dogBreed;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final String safeDogName =
        dogName.trim().isEmpty ? 'Your Pet' : dogName.trim();

    final String safeOwnerName =
        ownerName.trim().isEmpty ? 'Owner' : ownerName.trim();

    final String safeBreed = dogBreed.trim();

    return Row(
      children: <Widget>[
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE7DE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: Color(0xFFF4511E),
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                safeDogName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17202A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                safeBreed.isEmpty
                    ? safeOwnerName
                    : '$safeBreed • $safeOwnerName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

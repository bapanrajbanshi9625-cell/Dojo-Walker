import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerInfoCard extends StatelessWidget {
  final String walkId;

  const CustomerInfoCard({
    super.key,
    required this.walkId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('active_walks')
          .doc(walkId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingCard();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _EmptyCard();
        }

        final Map<String, dynamic> data =
            snapshot.data!.data() ??
                <String, dynamic>{};

        final String ownerName =
            (data['ownerName'] ?? 'Owner')
                .toString()
                .trim();

        final String ownerPhone =
            (data['ownerPhone'] ?? '')
                .toString()
                .trim();

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // ==================================================
              // OWNER
              // ==================================================

              Expanded(
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        ownerName.isEmpty
                            ? 'Owner'
                            : ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // CALL
              // ==================================================

              IconButton(
                onPressed: ownerPhone.isEmpty
                    ? null
                    : () {
                        _showConfirmation(
                          context,
                          title: 'Call Owner?',
                          message:
                              'Call $ownerName?',
                          onConfirm: () {
                            _callOwner(ownerPhone);
                          },
                        );
                      },
                icon: const Icon(
                  Icons.call,
                  color: Colors.green,
                  size: 26,
                ),
              ),

              // ==================================================
              // SMS
              // ==================================================

              IconButton(
                onPressed: ownerPhone.isEmpty
                    ? null
                    : () {
                        _showConfirmation(
                          context,
                          title: 'Send SMS?',
                          message:
                              'Send a message to $ownerName?',
                          onConfirm: () {
                            _messageOwner(ownerPhone);
                          },
                        );
                      },
                icon: const Icon(
                  Icons.message,
                  color: Colors.blue,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  void _showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _callOwner(String phone) async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ============================================================
  // SMS
  // ============================================================

  Future<void> _messageOwner(String phone) async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// ================================================================
// LOADING
// ================================================================

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ================================================================
// EMPTY
// ================================================================

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.person_outline,
            color: Colors.grey,
          ),
          SizedBox(width: 10),
          Text(
            'Owner information unavailable',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

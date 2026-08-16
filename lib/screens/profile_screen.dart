import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Login session not found.'),
        ),
      );
    }

    final String walkerUid = user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('walkers')
            .doc(walkerUid)
            .snapshots(),
        builder: (context, snapshot) {
          // =====================================================
          // LOADING
          // =====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // =====================================================
          // ERROR
          // =====================================================

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load profile.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // =====================================================
          // PROFILE NOT FOUND
          // =====================================================

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Profile information not found.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // =====================================================
          // PROFILE DATA
          // =====================================================

          final Map<String, dynamic> data =
              snapshot.data!.data() ??
                  <String, dynamic>{};

          final String name =
              (data['name'] ?? 'Not available').toString();

          final String phone =
              (data['phone'] ??
                      user.phoneNumber ??
                      'Not available')
                  .toString();

          final String uid =
              (data['uid'] ?? walkerUid).toString();

          final String dateOfBirth =
              (data['dateOfBirth'] ?? 'Not available')
                  .toString();

          final String address =
              (data['address'] ?? 'Not available').toString();

          final String pinCode =
              (data['pinCode'] ?? 'Not available').toString();

          // =====================================================
          // PROFILE UI
          // =====================================================

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // PROFILE HEADER
                // =================================================

                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        AppColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Center(
                  child: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // =================================================
                // PROFILE INFORMATION
                // =================================================

                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                _ProfileInfoCard(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: name,
                ),

                _ProfileInfoCard(
                  icon: Icons.phone_outlined,
                  label: 'Mobile Number',
                  value: phone,
                ),

                _ProfileInfoCard(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: dateOfBirth,
                ),

                _ProfileInfoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: address,
                ),

                _ProfileInfoCard(
                  icon: Icons.pin_drop_outlined,
                  label: 'PIN Code',
                  value: pinCode,
                ),

                const SizedBox(height: 10),

                // =================================================
                // WALKER UID
                // =================================================

                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 14),

                _ProfileInfoCard(
                  icon: Icons.verified_user_outlined,
                  label: 'Walker UID',
                  value: uid,
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Your profile is securely linked to your Walker UID.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// PROFILE INFO CARD
// =============================================================

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E4E8),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// File:
// lib/features/insta_walk/widgets/insta_walk_search_button.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class InstaWalkSearchButton extends StatelessWidget {
  const InstaWalkSearchButton({
    super.key,
    required this.loading,
    required this.searching,
    required this.onPressed,
  });

  final bool loading;
  final bool searching;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor:
              AppColors.buttonPrimaryPressed,
          disabledForegroundColor:
              AppColors.buttonText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 180,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const SizedBox(
        key: ValueKey<String>('loading'),
        width: 21,
        height: 21,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor:
              AlwaysStoppedAnimation<Color>(
            AppColors.buttonText,
          ),
        ),
      );
    }

    if (searching) {
      return Row(
        key: const ValueKey<String>('searching'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                AppColors.buttonText,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Searching Insta Walk 🔍',
            style: TextStyle(
              color: AppColors.buttonText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Row(
      key: const ValueKey<String>('normal'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.search_rounded,
          color: AppColors.buttonText,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          'Insta Walk Search',
          style: TextStyle(
            color: AppColors.buttonText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

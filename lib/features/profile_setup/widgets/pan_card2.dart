import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'document_card2.dart';

class PanCard2 extends StatelessWidget {
  const PanCard2({
    super.key,
    required this.url,
    required this.onTap,
    required this.enabled,
  });

  final String? url;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DocumentCard2(
      title: 'PAN Card',
      subtitle: 'Testing के लिए Image URL',
      url: url,
      onTap: enabled ? onTap : null,
      accentColor: AppColors.orange,
      icon: Icons.credit_card_rounded,
    );
  }
}

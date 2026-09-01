import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/dojo_walker_colors.dart';

class WalkerHelpSupportScreen extends StatelessWidget {
  const WalkerHelpSupportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoColors.background,
      appBar: AppBar(
        backgroundColor: DojoColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          children: [
            // =====================================================
            // HEADER CARD
            // =====================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DojoColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DojoColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: DojoColors.orangeLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: DojoColors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            color: DojoColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get help with your walks, account, '
                          'verification and other issues.',
                          style: TextStyle(
                            color: DojoColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =====================================================
            // RAISE TICKET
            // =====================================================

            const _SectionTitle(
              title: 'Support Ticket',
            ),

            const SizedBox(height: 8),

            _RaiseTicketTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // WALK SUPPORT
            // =====================================================

            const _SectionTitle(
              title: 'Walk Support',
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.directions_walk_rounded,
              title: 'Walk Issue',
              subtitle:
                  'Problems with an active or completed walk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(
                      initialCategory: 'Walk Issue',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'QR Walk Help',
              subtitle:
                  'Help with QR connection or starting a walk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(
                      initialCategory: 'QR Walk',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.location_on_outlined,
              title: 'Reach / Arrival Issue',
              subtitle:
                  'Problems while reaching the owner',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(
                      initialCategory: 'Reach / Arrival',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // ACCOUNT SUPPORT
            // =====================================================

            const _SectionTitle(
              title: 'Account',
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.verified_user_outlined,
              title: 'Verification Help',
              subtitle:
                  'Questions about Walker verification',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(
                      initialCategory: 'Verification',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.person_outline_rounded,
              title: 'Profile Help',
              subtitle:
                  'Problems with your Walker profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(
                      initialCategory: 'Profile',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // GENERAL
            // =====================================================

            const _SectionTitle(
              title: 'General',
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.help_outline_rounded,
              title: 'Frequently Asked Questions',
              subtitle:
                  'Common questions about Dojo Walker',
              onTap: () {
                _showFaq(context);
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.support_agent_rounded,
              title: 'Contact Support',
              subtitle:
                  'Create a support ticket for assistance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RaiseSupportTicketScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Dojo Walker',
                style: TextStyle(
                  color: DojoColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: const [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: DojoColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                _FaqItem(
                  question: 'How do I start a walk?',
                  answer:
                      'Complete the required connection or arrival '
                      'step first. Once the walk is ready, the Start '
                      'Walk control will become available.',
                ),
                _FaqItem(
                  question: 'How do I complete a walk?',
                  answer:
                      'Use the Slide to Complete Walk control '
                      'available at the bottom of the active walk screen.',
                ),
                _FaqItem(
                  question: 'What should I do if something goes wrong?',
                  answer:
                      'Create a support ticket from Help & Support '
                      'and describe the problem clearly.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// RAISE TICKET SCREEN
// ================================================================

class RaiseSupportTicketScreen extends StatefulWidget {
  const RaiseSupportTicketScreen({
    super.key,
    this.initialCategory,
  });

  final String? initialCategory;

  @override
  State<RaiseSupportTicketScreen> createState() =>
      _RaiseSupportTicketScreenState();
}

class _RaiseSupportTicketScreenState
    extends State<RaiseSupportTicketScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _walkIdController =
      TextEditingController();

  String _category = 'General';
  String _priority = 'normal';
  bool _submitting = false;

  final List<String> _categories = const [
    'General',
    'Walk Issue',
    'QR Walk',
    'Insta Walk',
    'Reach / Arrival',
    'Verification',
    'Profile',
    'Payment',
    'Other',
  ];

  final List<String> _priorities = const [
    'normal',
    'high',
    'urgent',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialCategory != null &&
        _categories.contains(widget.initialCategory)) {
      _category = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _walkIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoColors.background,
      appBar: AppBar(
        backgroundColor: DojoColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Raise Support Ticket',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              30,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DojoColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DojoColors.orange
                        .withValues(alpha: .25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: DojoColors.orange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Describe your problem clearly. '
                        'Our support team can review and reply '
                        'to your ticket.',
                        style: TextStyle(
                          color: DojoColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const _FormLabel(
                text: 'Problem Category',
              ),

              const SizedBox(height: 7),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration(
                  'Select category',
                  Icons.category_outlined,
                ),
                items: _categories
                    .map(
                      (String category) =>
                          DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (String? value) {
                        if (value == null) return;

                        setState(() {
                          _category = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              const _FormLabel(
                text: 'Priority',
              ),

              const SizedBox(height: 7),

              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: _inputDecoration(
                  'Select priority',
                  Icons.flag_outlined,
                ),
                items: _priorities
                    .map(
                      (String priority) =>
                          DropdownMenuItem<String>(
                        value: priority,
                        child: Text(
                          priority.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (String? value) {
                        if (value == null) return;

                        setState(() {
                          _priority = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              const _FormLabel(
                text: 'Subject',
              ),

              const SizedBox(height: 7),

              TextFormField(
                controller: _subjectController,
                enabled: !_submitting,
                textInputAction:
                    TextInputAction.next,
                maxLength: 100,
                decoration: _inputDecoration(
                  'Example: QR scan is not working',
                  Icons.subject_rounded,
                ),
                validator: (String? value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }

                  if (value.trim().length < 4) {
                    return 'Subject is too short';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              const _FormLabel(
                text: 'Problem Description',
              ),

              const SizedBox(height: 7),

              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                minLines: 5,
                maxLines: 8,
                maxLength: 1000,
                decoration: _inputDecoration(
                  'Explain what happened...',
                  Icons.description_outlined,
                ),
                validator: (String? value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please describe your problem';
                  }

                  if (value.trim().length < 10) {
                    return 'Please provide more details';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              const _FormLabel(
                text: 'Walk ID (Optional)',
              ),

              const SizedBox(height: 7),

              TextFormField(
                controller: _walkIdController,
                enabled: !_submitting,
                textInputAction:
                    TextInputAction.done,
                decoration: _inputDecoration(
                  'Enter Walk ID if related to a walk',
                  Icons.directions_walk_outlined,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      _submitting ? null : _submitTicket,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                        ),
                  label: Text(
                    _submitting
                        ? 'Submitting...'
                        : 'Submit Support Ticket',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        DojoColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        DojoColors.orange
                            .withValues(alpha: .55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your ticket will be assigned a unique Ticket ID.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DojoColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: DojoColors.iconSecondary,
      ),
      filled: true,
      fillColor: DojoColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoColors.orange,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoColors.error,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(
        'Please login again before creating a ticket.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final CollectionReference<
          Map<String, dynamic>> tickets =
          FirebaseFirestore.instance
              .collection('support_tickets');

      final DocumentReference<
          Map<String, dynamic>> ticketRef =
          tickets.doc();

      final String ticketId = ticketRef.id;

      final String walkerPhone =
          (user.phoneNumber ?? '').trim();

      final String walkId =
          _walkIdController.text.trim();

      final Timestamp now =
          Timestamp.now();

      await ticketRef.set({
        'ticketId': ticketId,
        'walkerId': user.uid,
        'walkerPhone': walkerPhone,
        'category': _category,
        'subject':
            _subjectController.text.trim(),
        'description':
            _descriptionController.text.trim(),
        'priority': _priority,
        'status': 'open',
        'adminReply': '',
        'walkId': walkId,
        'createdAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: DojoColors.success,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ticket Submitted',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your support ticket has been created successfully.',
                  style: TextStyle(
                    color:
                        DojoColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        DojoColors.background,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ticket ID\n$ticketId',
                    style: const TextStyle(
                      color:
                          DojoColors.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: DojoColors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showError(
        e.code == 'permission-denied'
            ? 'You do not have permission to create a support ticket.'
            : 'Could not create ticket. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;

      _showError(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              DojoColors.error,
        ),
      );
  }
}

// ================================================================
// RAISE TICKET TILE
// ================================================================

class _RaiseTicketTile extends StatelessWidget {
  final VoidCallback onTap;

  const _RaiseTicketTile({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoColors.orange,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(17),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.add_comment_rounded,
                color: Colors.white,
                size: 27,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raise a Support Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tell us about your problem and get help from Dojo Support.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FORM LABEL
// ================================================================

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: DojoColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ================================================================
// SECTION TITLE
// ================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: DojoColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ================================================================
// SUPPORT TILE
// ================================================================

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoColors.surface,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: DojoColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      DojoColors.orangeLight,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: DojoColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                            DojoColors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            DojoColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color:
                    DojoColors.iconSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FAQ ITEM
// ================================================================

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: DojoColors.background,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          14,
          0,
          14,
          14,
        ),
        iconColor: DojoColors.orange,
        collapsedIconColor:
            DojoColors.iconSecondary,
        title: Text(
          question,
          style: const TextStyle(
            color:
                DojoColors.textPrimary,
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color:
                    DojoColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

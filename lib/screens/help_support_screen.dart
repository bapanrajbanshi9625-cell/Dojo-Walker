import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/dojo_walker_colors.dart';

class WalkerHelpSupportScreen extends StatefulWidget {
  const WalkerHelpSupportScreen({
    super.key,
  });

  @override
  State<WalkerHelpSupportScreen> createState() =>
      _WalkerHelpSupportScreenState();
}

class _WalkerHelpSupportScreenState
    extends State<WalkerHelpSupportScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _walkIdController =
      TextEditingController();

  String _selectedCategory = 'Walk Issue';
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'Walk Issue',
    'QR Walk',
    'Insta Walk',
    'Reach / Arrival',
    'Payment',
    'Profile / Verification',
    'Technical Issue',
    'Other',
  ];

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
            _buildHeaderCard(),
            const SizedBox(height: 18),
            _buildRaiseTicketCard(),
            const SizedBox(height: 22),
            _buildMyTicketsSection(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // HEADER
  // =============================================================

  Widget _buildHeaderCard() {
    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Raise a support ticket and our team '
                  'can review your problem.',
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
    );
  }

  // =============================================================
  // RAISE TICKET
  // =============================================================

  Widget _buildRaiseTicketCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DojoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Raise a Support Ticket',
            style: TextStyle(
              color: DojoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tell us what went wrong and provide as much '
            'detail as possible.',
            style: TextStyle(
              color: DojoColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Problem Category',
            style: TextStyle(
              color: DojoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),

          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
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
            onChanged: _isSubmitting
                ? null
                : (String? value) {
                    if (value == null) return;

                    setState(() {
                      _selectedCategory = value;
                    });
                  },
          ),

          const SizedBox(height: 14),

          const Text(
            'Subject',
            style: TextStyle(
              color: DojoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),

          TextField(
            controller: _subjectController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            decoration: _inputDecoration(
              'Example: QR scan is not connecting',
              Icons.title_rounded,
            ).copyWith(
              counterText: '',
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Describe Your Problem',
            style: TextStyle(
              color: DojoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),

          TextField(
            controller: _descriptionController,
            enabled: !_isSubmitting,
            minLines: 5,
            maxLines: 8,
            maxLength: 1000,
            textInputAction: TextInputAction.newline,
            decoration: _inputDecoration(
              'Explain what happened...',
              Icons.description_outlined,
            ).copyWith(
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Walk ID (Optional)',
            style: TextStyle(
              color: DojoColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),

          TextField(
            controller: _walkIdController,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              'Enter Walk ID if related to a walk',
              Icons.directions_walk_rounded,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: DojoColors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    DojoColors.disabled,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      size: 19,
                    ),
              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : 'Raise Support Ticket',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MY TICKETS
  // =============================================================

  Widget _buildMyTicketsSection() {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Tickets',
          style: TextStyle(
            color: DojoColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),

        StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('support_tickets')
              .where(
                'walkerId',
                isEqualTo: user.uid,
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder: (
            BuildContext context,
            AsyncSnapshot<
                    QuerySnapshot<Map<String, dynamic>>>
                snapshot,
          ) {
            if (snapshot.hasError) {
              return _buildMessageCard(
                icon: Icons.info_outline_rounded,
                title: 'Tickets unavailable',
                message:
                    'Your tickets could not be loaded right now.',
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: DojoColors.orange,
                  ),
                ),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>> docs =
                snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _buildMessageCard(
                icon: Icons.inbox_outlined,
                title: 'No tickets yet',
                message:
                    'Your support tickets will appear here.',
              );
            }

            return Column(
              children: docs
                  .map(
                    (
                      QueryDocumentSnapshot<
                              Map<String, dynamic>>
                          doc,
                    ) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _buildTicketCard(
                          doc,
                        ),
                      );
                    },
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // =============================================================
  // TICKET CARD
  // =============================================================

  Widget _buildTicketCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();

    final String subject =
        (data['subject'] ?? 'Support Request').toString();

    final String category =
        (data['category'] ?? 'Other').toString();

    final String status =
        (data['status'] ?? 'open').toString();

    final String description =
        (data['description'] ?? '').toString();

    final String ticketId = doc.id;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DojoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showTicketDetails(
            ticketId: ticketId,
            subject: subject,
            category: category,
            status: status,
            description: description,
          );
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DojoColors.orangeLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
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
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DojoColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • #${_shortTicketId(ticketId)}',
                    style: const TextStyle(
                      color: DojoColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _StatusChip(
                    status: status,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: DojoColors.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SUBMIT TICKET
  // =============================================================

  Future<void> _submitTicket() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar(
        'Please login again to raise a ticket.',
        isError: true,
      );
      return;
    }

    final String subject =
        _subjectController.text.trim();

    final String description =
        _descriptionController.text.trim();

    final String walkId =
        _walkIdController.text.trim();

    if (subject.isEmpty) {
      _showSnackBar(
        'Please enter a subject.',
        isError: true,
      );
      return;
    }

    if (subject.length < 4) {
      _showSnackBar(
        'Subject is too short.',
        isError: true,
      );
      return;
    }

    if (description.isEmpty) {
      _showSnackBar(
        'Please describe your problem.',
        isError: true,
      );
      return;
    }

    if (description.length < 10) {
      _showSnackBar(
        'Please provide more details about the problem.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final DocumentReference<
              Map<String, dynamic>> ticketRef =
          _firestore.collection('support_tickets').doc();

      await ticketRef.set({
        'ticketId': ticketRef.id,
        'walkerId': user.uid,
        'walkerPhone': user.phoneNumber ?? '',
        'category': _selectedCategory,
        'subject': subject,
        'description': description,
        'walkId': walkId,
        'status': 'open',
        'priority': 'normal',
        'adminReply': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _subjectController.clear();
      _descriptionController.clear();
      _walkIdController.clear();

      setState(() {
        _selectedCategory = 'Walk Issue';
        _isSubmitting = false;
      });

      await _showTicketCreatedDialog(
        ticketId: ticketRef.id,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (e.code == 'permission-denied') {
        _showSnackBar(
          'Permission denied. Please check Firestore rules.',
          isError: true,
        );
      } else {
        _showSnackBar(
          'Could not create ticket. Please try again.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showSnackBar(
        'Something went wrong. Please try again.',
        isError: true,
      );
    }
  }

  // =============================================================
  // CREATED DIALOG
  // =============================================================

  Future<void> _showTicketCreatedDialog({
    required String ticketId,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: DojoColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: DojoColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: DojoColors.success,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ticket Raised',
                style: TextStyle(
                  color: DojoColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your support request has been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DojoColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DojoColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ticket #${_shortTicketId(ticketId)}',
                  style: const TextStyle(
                    color: DojoColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DojoColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // TICKET DETAILS
  // =============================================================

  void _showTicketDetails({
    required String ticketId,
    required String subject,
    required String category,
    required String status,
    required String description,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DojoColors.surface,
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
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: DojoColors.orangeLight,
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        color: DojoColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subject,
                        style: const TextStyle(
                          color: DojoColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Ticket #$ticketId',
                  style: const TextStyle(
                    color: DojoColors.textMuted,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _InfoChip(
                      label: category,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      status: status,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Problem',
                  style: TextStyle(
                    color: DojoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DojoColors.background,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: DojoColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          DojoColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // HELPERS
  // =============================================================

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: DojoColors.textMuted,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: DojoColors.iconSecondary,
        size: 20,
      ),
      filled: true,
      fillColor: DojoColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: DojoColors.inputBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: DojoColors.inputBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: DojoColors.orange,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DojoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: DojoColors.iconSecondary,
            size: 25,
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
                    color: DojoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
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
    );
  }

  String _shortTicketId(String id) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id
        .substring(id.length - 8)
        .toUpperCase();
  }

  void _showSnackBar(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? DojoColors.error
              : DojoColors.success,
        ),
      );
  }
}

// ================================================================
// STATUS CHIP
// ================================================================

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String normalized =
        status.toLowerCase().trim();

    Color background;
    Color foreground;
    String label;

    switch (normalized) {
      case 'resolved':
      case 'closed':
        background = DojoColors.successSoft;
        foreground = DojoColors.successDark;
        label = normalized == 'closed'
            ? 'Closed'
            : 'Resolved';
        break;

      case 'in_progress':
      case 'in progress':
        background = DojoColors.infoSoft;
        foreground = DojoColors.infoDark;
        label = 'In Progress';
        break;

      case 'pending':
        background = DojoColors.warningSoft;
        foreground = DojoColors.warningDark;
        label = 'Pending';
        break;

      default:
        background = DojoColors.orangeLight;
        foreground = DojoColors.orangeDark;
        label = 'Open';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ================================================================
// INFO CHIP
// ================================================================

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: DojoColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DojoColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

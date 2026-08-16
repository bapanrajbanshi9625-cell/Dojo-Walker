import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

// =============================================================
// COMMON BOTTOM SHEET BASE
// =============================================================

class ProfileBottomSheetBase
    extends StatelessWidget {
  final Widget child;

  const ProfileBottomSheetBase({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom:
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    14,
          ),
          child: child,
        ),
      ),
    );
  }
}

// =============================================================
// SHEET HANDLE
// =============================================================

class ProfileSheetHandle
    extends StatelessWidget {
  const ProfileSheetHandle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// =============================================================
// PRIMARY BUTTON
// =============================================================

class ProfilePrimaryButton
    extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  const ProfilePrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed:
            loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                size: 19,
              ),
        label: Text(
          loading
              ? 'Please wait...'
              : text,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// UPLOAD DOCUMENT BOTTOM SHEET
// =============================================================

class ProfileDocumentUploadSheet
    extends StatelessWidget {
  final String documentName;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const ProfileDocumentUploadSheet({
    super.key,
    required this.documentName,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBottomSheetBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProfileSheetHandle(),

          const SizedBox(height: 16),

          Text(
            'Upload $documentName',
            style:
                const TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Choose an option',
            style:
                TextStyle(
              fontSize: 12,
              color:
                  AppColors.textGrey,
            ),
          ),

          const SizedBox(height: 16),

          ProfileUploadOption(
            icon:
                Icons.photo_library_outlined,
            color:
                const Color(0xFF2563EB),
            title:
                'Upload from Gallery',
            subtitle:
                'Choose an existing photo',
            onTap: onGallery,
          ),

          const SizedBox(height: 10),

          ProfileUploadOption(
            icon:
                Icons.camera_alt_outlined,
            color:
                AppColors.secondary,
            title:
                'Take Photo with Camera',
            subtitle:
                'Capture a new document photo',
            onTap: onCamera,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// UPLOAD OPTION
// =============================================================

class ProfileUploadOption
    extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileUploadOption({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          AppColors.scaffoldBackground,
      borderRadius:
          BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color:
                  AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(
                    0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors
                                .textDark,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            AppColors
                                .textGrey,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// CURRENT PHONE BOTTOM SHEET
// =============================================================

class CurrentPhoneBottomSheet
    extends StatelessWidget {
  final String currentPhone;
  final VoidCallback onSendOtp;

  const CurrentPhoneBottomSheet({
    super.key,
    required this.currentPhone,
    required this.onSendOtp,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileBottomSheetBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const ProfileSheetHandle(),

          const SizedBox(height: 16),

          const Text(
            'Verify Current Number',
            style:
                TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'An OTP will be sent to your current mobile number.',
            style:
                TextStyle(
              fontSize: 13,
              color:
                  AppColors.textGrey,
            ),
          ),

          const SizedBox(height: 15),

          ProfilePhoneDisplay(
            phone: currentPhone,
          ),

          const SizedBox(height: 15),

          ProfilePrimaryButton(
            text: 'Send OTP',
            icon: Icons.sms_outlined,
            onTap: onSendOtp,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PHONE DISPLAY
// =============================================================

class ProfilePhoneDisplay
    extends StatelessWidget {
  final String phone;

  const ProfilePhoneDisplay({
    super.key,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            AppColors.scaffoldBackground,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_outlined,
            color:
                AppColors.secondary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              phone,
              style:
                  const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// OTP BOTTOM SHEET
// =============================================================

class OtpBottomSheet
    extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final Future<void> Function(
    String otp,
  ) onVerify;

  const OtpBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onVerify,
  });

  @override
  State<OtpBottomSheet> createState() =>
      _OtpBottomSheetState();
}

class _OtpBottomSheetState
    extends State<OtpBottomSheet> {
  final TextEditingController
      controller =
      TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final String otp =
        controller.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid 6-digit OTP.',
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await widget.onVerify(otp);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileBottomSheetBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProfileSheetHandle(),

          const SizedBox(height: 16),

          Text(
            widget.title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            widget.subtitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  AppColors.textGrey,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: controller,
            keyboardType:
                TextInputType.number,
            maxLength: 6,
            textAlign:
                TextAlign.center,
            autofocus: true,
            decoration:
                InputDecoration(
              counterText: '',
              hintText: '000000',
              filled: true,
              fillColor:
                  AppColors
                      .scaffoldBackground,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      AppColors.border,
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          ProfilePrimaryButton(
            text:
                widget.buttonText,
            icon:
                Icons.verified_outlined,
            loading: loading,
            onTap: _verify,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// NEW PHONE BOTTOM SHEET
// =============================================================

class NewPhoneBottomSheet
    extends StatefulWidget {
  final ValueChanged<String>
      onContinue;

  const NewPhoneBottomSheet({
    super.key,
    required this.onContinue,
  });

  @override
  State<NewPhoneBottomSheet>
      createState() =>
          _NewPhoneBottomSheetState();
}

class _NewPhoneBottomSheetState
    extends State<NewPhoneBottomSheet> {
  final TextEditingController
      newController =
      TextEditingController();

  final TextEditingController
      confirmController =
      TextEditingController();

  @override
  void dispose() {
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final String newPhone =
        newController.text.trim();

    final String confirmPhone =
        confirmController.text.trim();

    if (newPhone.isEmpty ||
        confirmPhone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter both mobile numbers.',
          ),
        ),
      );

      return;
    }

    if (newPhone != confirmPhone) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Mobile numbers do not match.',
          ),
        ),
      );

      return;
    }

   

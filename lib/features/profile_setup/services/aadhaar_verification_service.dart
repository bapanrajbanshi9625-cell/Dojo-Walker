import 'dart:io';

class AadhaarVerificationResult {
  final bool verified;
  final bool nameMatched;
  final bool dobMatched;
  final String? verifiedName;
  final String? message;

  const AadhaarVerificationResult({
    required this.verified,
    required this.nameMatched,
    required this.dobMatched,
    this.verifiedName,
    this.message,
  });
}

class AadhaarVerificationService {
  AadhaarVerificationService._();

  static Future<AadhaarVerificationResult> verify({
    required String authUid,
    required String name,
    required DateTime dateOfBirth,
    required String aadhaarNumber,
    File? frontFile,
    File? backFile,
    String? frontUrl,
    String? backUrl,
  }) async {
    /*
     * ==========================================================
     * AADHAAR VERIFICATION
     * ==========================================================
     *
     * IMPORTANT:
     *
     * यह method अभी वास्तविक Aadhaar verification नहीं करता।
     *
     * Backend / Admin verification API तैयार होने के बाद
     * इसी method के अंदर API call लगाई जाएगी।
     *
     * अभी verification false रखा गया है ताकि बिना वास्तविक
     * verification के profile को verified न माना जाए।
     *
     * authUid:
     * Firebase Authentication का current user's UID.
     *
     * frontFile / backFile:
     * Local Aadhaar images.
     *
     * frontUrl / backUrl:
     * अगर image URL से दी गई है तो उसका URL.
     */

    // Prevent unused-parameter warnings/errors in future implementations.
    // These values will be used by the backend verification API.
    final String uid = authUid;
    final String fullName = name.trim();
    final String aadhaar = aadhaarNumber.trim();

    final File? aadhaarFront = frontFile;
    final File? aadhaarBack = backFile;

    final String? aadhaarFrontUrl =
        frontUrl?.trim().isEmpty == true
            ? null
            : frontUrl?.trim();

    final String? aadhaarBackUrl =
        backUrl?.trim().isEmpty == true
            ? null
            : backUrl?.trim();

    // Keep references ready for the future backend implementation.
    // ignore: unnecessary_statements
    (
      uid,
      fullName,
      dateOfBirth,
      aadhaar,
      aadhaarFront,
      aadhaarBack,
      aadhaarFrontUrl,
      aadhaarBackUrl,
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    return const AadhaarVerificationResult(
      verified: false,
      nameMatched: false,
      dobMatched: false,
      verifiedName: null,
      message:
          'Aadhaar verification is not connected yet. Please complete verification from the admin/backend system.',
    );
  }
}

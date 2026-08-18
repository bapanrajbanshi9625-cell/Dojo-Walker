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
    required String name,
    required DateTime dateOfBirth,
    required String aadhaarNumber,
    String? frontUrl,
    String? backUrl,
  }) async {
    /*
     * IMPORTANT:
     *
     * यह अभी वास्तविक Aadhaar verification नहीं करता।
     *
     * जब आपका admin/backend verification तैयार होगा,
     * इसी method को backend/API से connect किया जाएगा।
     *
     * जब तक backend true नहीं देता:
     * profile save नहीं होगा
     * और user Home पर नहीं जाएगा।
     */

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

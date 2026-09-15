import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  static const String cloudName = 'kdkwevh4';
  static const String uploadPreset = 'dojo_walker';

  // ============================================================
  // IMAGE
  // ============================================================

  static Future<String> uploadImage({
    required File file,
    String? folder,
  }) async {
    return _upload(
      file: file,
      resourceType: 'image',
      folder: folder,
      errorLabel: 'image',
    );
  }

  // ============================================================
  // VOICE
  //
  // Cloudinary uses the video resource type for audio files.
  // ============================================================

  static Future<String> uploadVoice({
    required File file,
    String? folder,
  }) async {
    return _upload(
      file: file,
      resourceType: 'video',
      folder: folder,
      errorLabel: 'voice',
    );
  }

  // ============================================================
  // VIDEO
  // ============================================================

  static Future<String> uploadVideo({
    required File file,
    String? folder,
  }) async {
    return _upload(
      file: file,
      resourceType: 'video',
      folder: folder,
      errorLabel: 'video',
    );
  }

  // ============================================================
  // COMMON CLOUDINARY UPLOAD
  // ============================================================

  static Future<String> _upload({
    required File file,
    required String resourceType,
    String? folder,
    required String errorLabel,
  }) async {
    if (!await file.exists()) {
      throw Exception(
        'Selected $errorLabel file was not found.',
      );
    }

    if (cloudName.trim().isEmpty) {
      throw Exception(
        'Cloudinary Cloud Name is not configured.',
      );
    }

    if (uploadPreset.trim().isEmpty) {
      throw Exception(
        'Cloudinary Upload Preset is not configured.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$cloudName/$resourceType/upload',
    );

    final http.MultipartRequest request =
        http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] =
        uploadPreset;

    if (folder != null &&
        folder.trim().isNotEmpty) {
      request.fields['folder'] =
          folder.trim();
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final http.StreamedResponse
        streamedResponse =
        await request.send();

    final http.Response response =
        await http.Response.fromStream(
      streamedResponse,
    );

    // ==========================================================
    // CLOUDINARY ERROR
    // ==========================================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Cloudinary $errorLabel upload failed.';

      try {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded
            is Map<String, dynamic>) {
          final dynamic error =
              decoded['error'];

          if (error
              is Map<String, dynamic>) {
            final String?
                cloudinaryMessage =
                error['message']
                    ?.toString();

            if (cloudinaryMessage != null &&
                cloudinaryMessage
                    .trim()
                    .isNotEmpty) {
              message =
                  cloudinaryMessage.trim();
            }
          }
        }
      } catch (_) {
        // Keep the default error message.
      }

      throw Exception(
        '$message (HTTP ${response.statusCode})',
      );
    }

    // ==========================================================
    // RESPONSE
    // ==========================================================

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded
        is! Map<String, dynamic>) {
      throw Exception(
        'Invalid response received from Cloudinary.',
      );
    }

    final String? secureUrl =
        decoded['secure_url']?.toString();

    if (secureUrl == null ||
        secureUrl.trim().isEmpty) {
      throw Exception(
        'Cloudinary did not return a secure URL.',
      );
    }

    return secureUrl.trim();
  }
}

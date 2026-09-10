import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  // ============================================================
  // CLOUDINARY CONFIG
  // ============================================================

  static const String cloudName = 'kdkwevh4';

  static const String uploadPreset = 'dojo_walker';

  // ============================================================
  // UPLOAD IMAGE
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
  // UPLOAD VOICE
  //
  // Cloudinary handles audio through the video resource type.
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
  // COMMON UPLOAD
  // ============================================================

  static Future<String> _upload({
    required File file,
    required String resourceType,
    String? folder,
    required String errorLabel,
  }) async {
    // ----------------------------------------------------------
    // FILE CHECK
    // ----------------------------------------------------------

    if (!await file.exists()) {
      throw Exception(
        'Selected $errorLabel file was not found.',
      );
    }

    // ----------------------------------------------------------
    // CLOUD NAME CHECK
    // ----------------------------------------------------------

    if (cloudName.trim().isEmpty) {
      throw Exception(
        'Cloudinary Cloud Name is not configured.',
      );
    }

    // ----------------------------------------------------------
    // UPLOAD PRESET CHECK
    // ----------------------------------------------------------

    if (uploadPreset.trim().isEmpty) {
      throw Exception(
        'Cloudinary Upload Preset is not configured.',
      );
    }

    // ----------------------------------------------------------
    // UPLOAD URL
    // ----------------------------------------------------------

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$cloudName/$resourceType/upload',
    );

    // ----------------------------------------------------------
    // MULTIPART REQUEST
    // ----------------------------------------------------------

    final http.MultipartRequest request =
        http.MultipartRequest(
      'POST',
      uri,
    );

    // ----------------------------------------------------------
    // UNSIGNED UPLOAD PRESET
    // ----------------------------------------------------------

    request.fields['upload_preset'] = uploadPreset;

    // ----------------------------------------------------------
    // OPTIONAL FOLDER
    // ----------------------------------------------------------

    if (folder != null &&
        folder.trim().isNotEmpty) {
      request.fields['folder'] = folder.trim();
    }

    // ----------------------------------------------------------
    // FILE
    // ----------------------------------------------------------

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    // ----------------------------------------------------------
    // SEND
    // ----------------------------------------------------------

    final http.StreamedResponse streamedResponse =
        await request.send();

    final http.Response response =
        await http.Response.fromStream(
      streamedResponse,
    );

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Cloudinary $errorLabel upload failed.';

      try {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final dynamic error = decoded['error'];

          if (error is Map<String, dynamic>) {
            final String? cloudinaryMessage =
                error['message']?.toString();

            if (cloudinaryMessage != null &&
                cloudinaryMessage.trim().isNotEmpty) {
              message = cloudinaryMessage.trim();
            }
          }
        }
      } catch (_) {
        // Keep default error message.
      }

      throw Exception(
        '$message (HTTP ${response.statusCode})',
      );
    }

    // ----------------------------------------------------------
    // RESPONSE
    // ----------------------------------------------------------

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid response received from Cloudinary.',
      );
    }

    // ----------------------------------------------------------
    // SECURE URL
    // ----------------------------------------------------------

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

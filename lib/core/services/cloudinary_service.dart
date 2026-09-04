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
    // ----------------------------------------------------------
    // FILE CHECK
    // ----------------------------------------------------------

    if (!await file.exists()) {
      throw Exception(
        'Selected image file was not found.',
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
    // UPLOAD URL
    // ----------------------------------------------------------

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$cloudName/image/upload',
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

    if (folder != null && folder.trim().isNotEmpty) {
      request.fields['folder'] = folder.trim();
    }

    // ----------------------------------------------------------
    // IMAGE FILE
    // ----------------------------------------------------------

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    // ----------------------------------------------------------
    // SEND REQUEST
    // ----------------------------------------------------------

    final http.StreamedResponse streamedResponse =
        await request.send();

    final http.Response response =
        await http.Response.fromStream(
      streamedResponse,
    );

    // ----------------------------------------------------------
    // ERROR HANDLING
    // ----------------------------------------------------------

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Cloudinary image upload failed.';

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
              message = cloudinaryMessage;
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
    // RESPONSE JSON
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
        'Cloudinary did not return an image URL.',
      );
    }

    return secureUrl.trim();
  }
}

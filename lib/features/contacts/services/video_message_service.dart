import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/cloudinary_service.dart';

class VideoMessageResult {
  const VideoMessageResult({
    required this.file,
    required this.url,
    required this.durationSeconds,
  });

  final File file;
  final String url;
  final int durationSeconds;
}

class VideoMessageService {
  VideoMessageService._();

  static final VideoMessageService instance =
      VideoMessageService._();

  final ImagePicker _picker =
      ImagePicker();

  // ============================================================
  // PICK VIDEO
  // ============================================================

  Future<File?> pickVideo({
    required ImageSource source,
  }) async {
    final XFile? pickedFile =
        await _picker.pickVideo(
      source: source,
      maxDuration:
          const Duration(minutes: 5),
    );

    if (pickedFile == null) {
      return null;
    }

    final File file =
        File(pickedFile.path);

    if (!await file.exists()) {
      throw Exception(
        'Selected video file was not found.',
      );
    }

    return file;
  }

  // ============================================================
  // PICK + UPLOAD VIDEO
  // ============================================================

  Future<VideoMessageResult?> pickAndUploadVideo({
    required ImageSource source,
    String folder = 'chat/video',
  }) async {
    final File? file =
        await pickVideo(
      source: source,
    );

    if (file == null) {
      return null;
    }

    return uploadVideo(
      file: file,
      folder: folder,
    );
  }

  // ============================================================
  // UPLOAD VIDEO
  // ============================================================

  Future<VideoMessageResult> uploadVideo({
    required File file,
    String folder = 'chat/video',
  }) async {
    if (!await file.exists()) {
      throw Exception(
        'Video file was not found.',
      );
    }

    final int durationSeconds =
        await _getDurationSeconds(
      file,
    );

    final String url =
        await CloudinaryService.uploadVideo(
      file: file,
      folder: folder,
    );

    return VideoMessageResult(
      file: file,
      url: url,
      durationSeconds:
          durationSeconds,
    );
  }

  // ============================================================
  // GET VIDEO DURATION
  // ============================================================

  Future<int> _getDurationSeconds(
    File file,
  ) async {
    final VideoPlayerController controller =
        VideoPlayerController.file(
      file,
    );

    try {
      await controller.initialize();

      final Duration duration =
          controller.value.duration;

      int seconds =
          duration.inSeconds;

      if (seconds < 1 &&
          duration > Duration.zero) {
        seconds = 1;
      }

      return seconds;
    } catch (_) {
      return 0;
    } finally {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<VideoMessageResult?> recordAndUploadVideo({
    String folder = 'chat/video',
  }) async {
    return pickAndUploadVideo(
      source: ImageSource.camera,
      folder: folder,
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Future<VideoMessageResult?> pickFromGalleryAndUpload({
    String folder = 'chat/video',
  }) async {
    return pickAndUploadVideo(
      source: ImageSource.gallery,
      folder: folder,
    );
  }
}

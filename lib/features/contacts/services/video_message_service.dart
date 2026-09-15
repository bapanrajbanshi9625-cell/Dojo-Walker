import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/cloudinary_service.dart';

class VideoSelectionResult {
  const VideoSelectionResult({
    required this.file,
    required this.durationSeconds,
  });

  final File file;
  final int durationSeconds;
}

class VideoUploadResult {
  const VideoUploadResult({
    required this.url,
    required this.durationSeconds,
  });

  final String url;
  final int durationSeconds;
}

class VideoMessageService {
  VideoMessageService._();

  static final VideoMessageService instance =
      VideoMessageService._();

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // PICK / RECORD VIDEO
  // ============================================================

  Future<VideoSelectionResult?> pickVideo({
    required ImageSource source,
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
  }) async {
    final XFile? pickedFile =
        await _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );

    if (pickedFile == null) {
      return null;
    }

    final File file =
        File(pickedFile.path);

    if (!await file.exists()) {
      throw Exception(
        'Selected video was not found.',
      );
    }

    final int durationSeconds =
        await _getDurationSeconds(file);

    return VideoSelectionResult(
      file: file,
      durationSeconds: durationSeconds,
    );
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<VideoSelectionResult?> recordVideo({
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
  }) {
    return pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Future<VideoSelectionResult?> pickFromGallery({
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
  }) {
    return pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
  }

  // ============================================================
  // UPLOAD VIDEO
  // ============================================================

  Future<VideoUploadResult> uploadVideo({
    required File file,
    int? durationSeconds,
    String folder = 'chat/video',
  }) async {
    if (!await file.exists()) {
      throw Exception(
        'Video file was not found.',
      );
    }

    final int duration =
        durationSeconds ??
            await _getDurationSeconds(file);

    final String url =
        await CloudinaryService.uploadVideo(
      file: file,
      folder: folder,
    );

    return VideoUploadResult(
      url: url,
      durationSeconds: duration,
    );
  }

  // ============================================================
  // RECORD + UPLOAD
  // ============================================================

  Future<VideoUploadResult?>
      recordAndUpload({
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
    String folder = 'chat/video',
  }) async {
    final VideoSelectionResult?
        selection =
        await recordVideo(
      maxDuration: maxDuration,
    );

    if (selection == null) {
      return null;
    }

    return uploadVideo(
      file: selection.file,
      durationSeconds:
          selection.durationSeconds,
      folder: folder,
    );
  }

  // ============================================================
  // GALLERY + UPLOAD
  // ============================================================

  Future<VideoUploadResult?>
      pickAndUpload({
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
    String folder = 'chat/video',
  }) async {
    final VideoSelectionResult?
        selection =
        await pickFromGallery(
      maxDuration: maxDuration,
    );

    if (selection == null) {
      return null;
    }

    return uploadVideo(
      file: selection.file,
      durationSeconds:
          selection.durationSeconds,
      folder: folder,
    );
  }

  // ============================================================
  // VIDEO DURATION
  // ============================================================

  Future<int> _getDurationSeconds(
    File file,
  ) async {
    final VideoPlayerController
        controller =
        VideoPlayerController.file(
      file,
    );

    try {
      await controller.initialize();

      final Duration duration =
          controller.value.duration;

      if (duration <= Duration.zero) {
        return 0;
      }

      return duration.inSeconds;
    } finally {
      await controller.dispose();
    }
  }
}

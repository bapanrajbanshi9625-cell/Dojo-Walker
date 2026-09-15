import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/cloudinary_service.dart';

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

  bool _isBusy = false;

  bool get isBusy => _isBusy;

  Future<VideoUploadResult?> recordAndUpload({
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
    String? folder,
  }) async {
    if (_isBusy) {
      return null;
    }

    _isBusy = true;

    try {
      final XFile? pickedFile =
          await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
      );

      if (pickedFile == null) {
        return null;
      }

      final File file =
          File(pickedFile.path);

      return await _upload(
        file: file,
        folder: folder,
      );
    } finally {
      _isBusy = false;
    }
  }

  Future<VideoUploadResult?> pickAndUpload({
    Duration maxDuration = const Duration(
      minutes: 2,
    ),
    String? folder,
  }) async {
    if (_isBusy) {
      return null;
    }

    _isBusy = true;

    try {
      final XFile? pickedFile =
          await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );

      if (pickedFile == null) {
        return null;
      }

      final File file =
          File(pickedFile.path);

      return await _upload(
        file: file,
        folder: folder,
      );
    } finally {
      _isBusy = false;
    }
  }

  Future<VideoUploadResult> _upload({
    required File file,
    String? folder,
  }) async {
    if (!await file.exists()) {
      throw Exception(
        'Selected video file was not found.',
      );
    }

    int durationSeconds = 0;

    final VideoPlayerController controller =
        VideoPlayerController.file(file);

    try {
      await controller.initialize();

      final Duration duration =
          controller.value.duration;

      if (duration.inSeconds > 0) {
        durationSeconds =
            duration.inSeconds;
      }
    } catch (_) {
      durationSeconds = 0;
    } finally {
      await controller.dispose();
    }

    final String url =
        await CloudinaryService.uploadVideo(
      file: file,
      folder: folder,
    );

    return VideoUploadResult(
      url: url,
      durationSeconds: durationSeconds,
    );
  }
}

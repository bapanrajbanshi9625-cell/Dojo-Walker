import 'dart:io';

import 'package:record/record.dart';

import '../../../core/services/cloudinary_service.dart';

class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.file,
    required this.durationSeconds,
  });

  final File file;
  final int durationSeconds;
}

class VoiceMessageService {
  VoiceMessageService._();

  static final VoiceMessageService instance =
      VoiceMessageService._();

  final AudioRecorder _recorder = AudioRecorder();

  String? _currentPath;
  DateTime? _startedAt;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  // ============================================================
  // PERMISSION
  // ============================================================

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  // ============================================================
  // START RECORDING
  // ============================================================

  Future<void> startRecording() async {
    if (_isRecording) {
      return;
    }

    final bool permissionGranted =
        await _recorder.hasPermission();

    if (!permissionGranted) {
      throw Exception(
        'Microphone permission is required.',
      );
    }

    final Directory tempDirectory =
        Directory.systemTemp;

    final String filePath =
        '${tempDirectory.path}/'
        'dojo_voice_'
        '${DateTime.now().microsecondsSinceEpoch}'
        '.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: filePath,
    );

    _currentPath = filePath;
    _startedAt = DateTime.now();
    _isRecording = true;
  }

  // ============================================================
  // STOP RECORDING
  // ============================================================

  Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    final DateTime startedAt =
        _startedAt ?? DateTime.now();

    final String? recordedPath =
        await _recorder.stop();

    _isRecording = false;
    _startedAt = null;
    _currentPath = null;

    if (recordedPath == null ||
        recordedPath.trim().isEmpty) {
      return null;
    }

    final File file = File(
      recordedPath,
    );

    if (!await file.exists()) {
      throw Exception(
        'Voice recording file was not created.',
      );
    }

    final Duration duration =
        DateTime.now().difference(startedAt);

    int durationSeconds =
        duration.inSeconds;

    if (durationSeconds < 1) {
      durationSeconds = 1;
    }

    return VoiceRecordingResult(
      file: file,
      durationSeconds: durationSeconds,
    );
  }

  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> cancelRecording() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {
        // Ignore recorder stop errors during cancellation.
      }
    }

    _isRecording = false;
    _startedAt = null;

    final String? path = _currentPath;

    _currentPath = null;

    if (path != null &&
        path.trim().isNotEmpty) {
      final File file = File(path);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Ignore temporary file cleanup errors.
        }
      }
    }
  }

  // ============================================================
  // RECORD + CLOUDINARY UPLOAD
  // ============================================================

  Future<VoiceUploadResult> recordAndUpload({
    String folder = 'chat/voice',
  }) async {
    await startRecording();

    try {
      final VoiceRecordingResult? recording =
          await stopRecording();

      if (recording == null) {
        throw Exception(
          'Voice recording was not created.',
        );
      }

      final String url =
          await CloudinaryService.uploadVoice(
        file: recording.file,
        folder: folder,
      );

      try {
        if (await recording.file.exists()) {
          await recording.file.delete();
        }
      } catch (_) {
        // Ignore temporary file cleanup errors.
      }

      return VoiceUploadResult(
        url: url,
        durationSeconds:
            recording.durationSeconds,
      );
    } catch (_) {
      await cancelRecording();
      rethrow;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await cancelRecording();
    _recorder.dispose();
  }
}

class VoiceUploadResult {
  const VoiceUploadResult({
    required this.url,
    required this.durationSeconds,
  });

  final String url;
  final int durationSeconds;
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

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

  final AudioRecorder _recorder =
      AudioRecorder();

  String? _currentPath;
  DateTime? _startedAt;
  bool _isRecording = false;

  // ============================================================
  // PLAYBACK
  // ============================================================

  final Map<String, VideoPlayerController>
      _players =
      <String, VideoPlayerController>{};

  final Map<String, VoidCallback>
      _playerListeners =
      <String, VoidCallback>{};

  String? _playingMessageId;

  final StreamController<String?>
      _playingMessageController =
      StreamController<String?>.broadcast();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isRecording =>
      _isRecording;

  String? get playingMessageId =>
      _playingMessageId;

  Stream<String?>
      get playingMessageIdStream =>
          _playingMessageController.stream;

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
        numChannels: 1,
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

    String? recordedPath;

    try {
      recordedPath =
          await _recorder.stop();
    } finally {
      _isRecording = false;
      _startedAt = null;
    }

    final String? fallbackPath =
        _currentPath;

    _currentPath = null;

    final String? path =
        recordedPath ?? fallbackPath;

    if (path == null ||
        path.trim().isEmpty) {
      return null;
    }

    final File file =
        File(path);

    if (!await file.exists()) {
      throw Exception(
        'Voice recording file was not created.',
      );
    }

    final Duration duration =
        DateTime.now().difference(
      startedAt,
    );

    int durationSeconds =
        duration.inSeconds;

    if (durationSeconds < 1) {
      durationSeconds = 1;
    }

    return VoiceRecordingResult(
      file: file,
      durationSeconds:
          durationSeconds,
    );
  }

  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> cancelRecording() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }

    _isRecording = false;
    _startedAt = null;

    final String? path =
        _currentPath;

    _currentPath = null;

    if (path == null ||
        path.trim().isEmpty) {
      return;
    }

    final File file =
        File(path);

    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
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
      } catch (_) {}

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
  // TOGGLE PLAYBACK
  // ============================================================

  Future<void> togglePlayback({
    required String messageId,
    required String audioUrl,
  }) async {
    final String id =
        messageId.trim();

    final String url =
        audioUrl.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Message ID is required.',
      );
    }

    if (url.isEmpty) {
      throw ArgumentError(
        'Voice URL is required.',
      );
    }

    // ----------------------------------------------------------
    // Another voice is playing.
    // ----------------------------------------------------------

    if (_playingMessageId != null &&
        _playingMessageId != id) {
      await stopPlayback();
    }

    final VideoPlayerController?
        existingPlayer =
        _players[id];

    // ----------------------------------------------------------
    // Existing player.
    // ----------------------------------------------------------

    if (existingPlayer != null) {
      if (existingPlayer.value.isPlaying) {
        await existingPlayer.pause();

        _setPlayingMessageId(null);

        return;
      }

      if (existingPlayer.value.isInitialized) {
        await existingPlayer.play();

        _setPlayingMessageId(id);

        return;
      }

      await _disposePlayer(id);
    }

    // ----------------------------------------------------------
    // New player.
    // ----------------------------------------------------------

    final VideoPlayerController player =
        VideoPlayerController.networkUrl(
      Uri.parse(url),
    );

    _players[id] = player;

    try {
      await player.initialize();

      await player.setLooping(false);

      final VoidCallback listener = () {
        final VideoPlayerValue value =
            player.value;

        if (!value.isInitialized) {
          return;
        }

        if (value.hasError) {
          if (_playingMessageId == id) {
            _setPlayingMessageId(null);
          }

          return;
        }

        if (!value.isPlaying &&
            value.duration > Duration.zero &&
            value.position >= value.duration) {
          unawaited(
            _handlePlaybackCompleted(id),
          );
        }
      };

      _playerListeners[id] =
          listener;

      player.addListener(listener);

      await player.play();

      _setPlayingMessageId(id);
    } catch (_) {
      await _disposePlayer(id);
      _setPlayingMessageId(null);
      rethrow;
    }
  }

  // ============================================================
  // STOP PLAYBACK
  // ============================================================

  Future<void> stopPlayback() async {
    final String? id =
        _playingMessageId;

    if (id == null) {
      return;
    }

    final VideoPlayerController?
        player =
        _players[id];

    if (player != null) {
      try {
        await player.pause();

        await player.seekTo(
          Duration.zero,
        );
      } catch (_) {}
    }

    _setPlayingMessageId(null);
  }

  // ============================================================
  // PLAYBACK COMPLETED
  // ============================================================

  Future<void> _handlePlaybackCompleted(
    String messageId,
  ) async {
    if (_playingMessageId !=
        messageId) {
      return;
    }

    final VideoPlayerController?
        player =
        _players[messageId];

    if (player != null) {
      try {
        await player.pause();

        await player.seekTo(
          Duration.zero,
        );
      } catch (_) {}
    }

    _setPlayingMessageId(null);
  }

  // ============================================================
  // SET PLAYING MESSAGE
  // ============================================================

  void _setPlayingMessageId(
    String? messageId,
  ) {
    _playingMessageId =
        messageId;

    if (!_playingMessageController
        .isClosed) {
      _playingMessageController.add(
        messageId,
      );
    }
  }

  // ============================================================
  // DISPOSE PLAYER
  // ============================================================

  Future<void> _disposePlayer(
    String messageId,
  ) async {
    final VideoPlayerController?
        player =
        _players.remove(messageId);

    final VoidCallback?
        listener =
        _playerListeners.remove(
      messageId,
    );

    if (player != null) {
      if (listener != null) {
        player.removeListener(
          listener,
        );
      }

      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await cancelRecording();

    final List<String> ids =
        List<String>.from(
      _players.keys,
    );

    for (final String id in ids) {
      await _disposePlayer(id);
    }

    _setPlayingMessageId(null);

    await _playingMessageController
        .close();

    _recorder.dispose();
  }
}

// ================================================================
// CLOUDINARY VOICE UPLOAD RESULT
// ================================================================

class VoiceUploadResult {
  const VoiceUploadResult({
    required this.url,
    required this.durationSeconds,
  });

  final String url;
  final int durationSeconds;
}

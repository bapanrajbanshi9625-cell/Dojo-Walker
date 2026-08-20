import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class WalkRequestSoundService {
  WalkRequestSoundService._();

  static final WalkRequestSoundService instance =
      WalkRequestSoundService._();

  final AudioPlayer _player = AudioPlayer();

  Timer? _stopTimer;

  final Set<String> _playingRequestIds = <String>{};

  // ============================================================
  // START REQUEST SOUND
  // ============================================================

  Future<void> playForRequest(
    String requestId,
  ) async {
    if (requestId.trim().isEmpty) {
      return;
    }

    // Same request already playing.
    if (_playingRequestIds.contains(requestId)) {
      return;
    }

    _playingRequestIds.add(requestId);

    _stopTimer?.cancel();

    try {
      await _player.stop();

      await _player.setReleaseMode(
        ReleaseMode.loop,
      );

      await _player.play(
        AssetSource(
          'audio/Dojo_Walker_Walk_Request.mp3',
        ),
      );

      // Maximum 60 seconds.
      _stopTimer = Timer(
        const Duration(seconds: 60),
        () async {
          await stopRequest(requestId);
        },
      );
    } catch (e) {
      _playingRequestIds.remove(requestId);
    }
  }

  // ============================================================
  // STOP REQUEST SOUND
  // ============================================================

  Future<void> stopRequest(
    String requestId,
  ) async {
    _playingRequestIds.remove(requestId);

    if (_playingRequestIds.isEmpty) {
      _stopTimer?.cancel();
      _stopTimer = null;

      await _player.stop();
    }
  }

  // ============================================================
  // STOP ALL
  // ============================================================

  Future<void> stopAll() async {
    _playingRequestIds.clear();

    _stopTimer?.cancel();
    _stopTimer = null;

    await _player.stop();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    _stopTimer?.cancel();
    _stopTimer = null;

    await _player.dispose();
  }
}

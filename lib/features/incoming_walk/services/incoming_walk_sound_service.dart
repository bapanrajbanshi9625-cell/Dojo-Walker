import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class IncomingWalkSoundService {
  IncomingWalkSoundService._();

  static final IncomingWalkSoundService instance =
      IncomingWalkSoundService._();

  final AudioPlayer _player = AudioPlayer();

  Timer? _stopTimer;

  final Set<String> _playingRequestIds = <String>{};

  // ============================================================
  // START INCOMING WALK SOUND
  // ============================================================

  Future<void> playForRequest(
    String requestId,
  ) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    if (_playingRequestIds.contains(id)) {
      return;
    }

    _playingRequestIds.add(id);

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
          await stopRequest(id);
        },
      );
    } catch (e) {
      _playingRequestIds.remove(id);
    }
  }

  // ============================================================
  // STOP INCOMING WALK SOUND
  // ============================================================

  Future<void> stopRequest(
    String requestId,
  ) async {
    final String id = requestId.trim();

    _playingRequestIds.remove(id);

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

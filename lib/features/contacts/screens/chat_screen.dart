// File:
// lib/features/contacts/screens/chat_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/cloudinary_service.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/video_message_service.dart';
import '../services/voice_message_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.contactName,
    required this.requestId,
    required this.sessionId,
    this.contactPhotoUrl,
    this.currentUserIsWalker = true,
  });

  final String otherUid;
  final String contactName;
  final String requestId;
  final String sessionId;
  final String? contactPhotoUrl;
  final bool currentUserIsWalker;

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _orange =
      Color(0xFFFF6B35);

  static const Color _lightBackground =
      Color(0xFFF7F7F7);

  final ChatService _chatService =
      ChatService();

  final VoiceMessageService _voiceService =
      VoiceMessageService.instance;

  final VideoMessageService _videoService =
      VideoMessageService.instance;

  final ImagePicker _imagePicker =
      ImagePicker();

  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  StreamSubscription<String?>?
      _voicePlaybackSubscription;

  bool _sendingMessage = false;
  bool _uploadingPhoto = false;
  bool _uploadingVideo = false;
  bool _recordingVoice = false;

  String? _playingVoiceMessageId;

  @override
  void initState() {
    super.initState();

    _voicePlaybackSubscription =
        _voiceService.playingMessageIdStream
            .listen(
      (String? messageId) {
        if (!mounted) {
          return;
        }

        setState(() {
          _playingVoiceMessageId =
              messageId;
        });
      },
    );
  }

  @override
  void dispose() {
    _voicePlaybackSubscription
        ?.cancel();

    _messageController.dispose();
    _scrollController.dispose();

    unawaited(
      _voiceService.stopPlayback(),
    );

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
        Theme.of(context);

    return Scaffold(
      backgroundColor:
          _lightBackground,
      appBar:
          _buildAppBar(theme),
      body: Column(
        children: <Widget>[
          Expanded(
            child:
                _buildMessages(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String get _displayName {
    final String name =
        widget.contactName.trim();

    if (name.isEmpty) {
      return widget.currentUserIsWalker
          ? 'Owner'
          : 'Walker';
    }

    return name;
  }

  String get _requestId {
    return widget.requestId.trim();
  }

  String get _sessionId {
    return widget.sessionId.trim();
  }

  bool get _hasValidWalkScope {
    return RegExp(
          r'^DW\d{6}$',
        ).hasMatch(_requestId) &&
        _requestId == _sessionId;
  }

  // ============================================================
  // TEXT
  // ============================================================

  Future<void> _sendTextMessage() async {
    final String text =
        _messageController.text.trim();

    if (text.isEmpty ||
        _sendingMessage ||
        widget.otherUid.trim().isEmpty ||
        !_hasValidWalkScope) {
      return;
    }

    setState(() {
      _sendingMessage = true;
    });

    try {
      await _chatService.sendTextMessage(
        receiverUid:
            widget.otherUid,
        requestId:
            _requestId,
        sessionId:
            _sessionId,
        text: text,
      );

      _messageController.clear();

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to send message.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingMessage = false;
        });
      }
    }
  }

  // ============================================================
  // PHOTO OPTIONS
  // ============================================================

  Future<void> _showPhotoOptions() async {
    if (_uploadingPhoto ||
        _uploadingVideo ||
        _recordingVoice) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder:
          (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Send Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                _PhotoOptionTile(
                  icon: Icons
                      .camera_alt_rounded,
                  title: 'Camera',
                  subtitle:
                      'Take a new photo',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    unawaited(
                      _pickAndSendPhoto(
                        ImageSource.camera,
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 8,
                ),
                _PhotoOptionTile(
                  icon: Icons
                      .photo_library_rounded,
                  title: 'Gallery',
                  subtitle:
                      'Choose from your photos',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    unawaited(
                      _pickAndSendPhoto(
                        ImageSource.gallery,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Future<void> _pickAndSendPhoto(
    ImageSource source,
  ) async {
    if (_uploadingPhoto ||
        _uploadingVideo ||
        !_hasValidWalkScope) {
      return;
    }

    try {
      final XFile? selected =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (selected == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _uploadingPhoto = true;
      });

      final File file =
          File(selected.path);

      final String imageUrl =
          await CloudinaryService
              .uploadImage(
        file: file,
        folder: 'chat/photos',
      );

      await _chatService
          .sendPhotoMessage(
        receiverUid:
            widget.otherUid,
        requestId:
            _requestId,
        sessionId:
            _sessionId,
        mediaUrl: imageUrl,
      );

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to send photo.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  // ============================================================
  // VIDEO OPTIONS
  // ============================================================

  Future<void> _showVideoOptions() async {
    if (_uploadingPhoto ||
        _uploadingVideo ||
        _recordingVoice) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder:
          (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Send Video',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                _PhotoOptionTile(
                  icon: Icons
                      .videocam_rounded,
                  title: 'Camera',
                  subtitle:
                      'Record a new video',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    unawaited(
                      _recordAndSendVideo(),
                    );
                  },
                ),
                const SizedBox(
                  height: 8,
                ),
                _PhotoOptionTile(
                  icon: Icons
                      .video_library_rounded,
                  title: 'Gallery',
                  subtitle:
                      'Choose a video',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    unawaited(
                      _pickAndSendVideo(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // RECORD VIDEO
  // ============================================================

  Future<void> _recordAndSendVideo() async {
    if (_uploadingVideo ||
        _uploadingPhoto ||
        !_hasValidWalkScope) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _uploadingVideo = true;
    });

    try {
      final VideoUploadResult?
          result =
          await _videoService
              .recordAndUpload(
        maxDuration:
            const Duration(
          minutes: 2,
        ),
        folder: 'chat/video',
      );

      if (result == null) {
        return;
      }

      await _chatService
          .sendVideoMessage(
        receiverUid:
            widget.otherUid,
        requestId:
            _requestId,
        sessionId:
            _sessionId,
        mediaUrl:
            result.url,
        durationSeconds:
            result.durationSeconds,
      );

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to send video.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingVideo = false;
        });
      }
    }
  }

  // ============================================================
  // GALLERY VIDEO
  // ============================================================

  Future<void> _pickAndSendVideo() async {
    if (_uploadingVideo ||
        _uploadingPhoto ||
        !_hasValidWalkScope) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _uploadingVideo = true;
    });

    try {
      final VideoUploadResult?
          result =
          await _videoService
              .pickAndUpload(
        maxDuration:
            const Duration(
          minutes: 2,
        ),
        folder: 'chat/video',
      );

      if (result == null) {
        return;
      }

      await _chatService
          .sendVideoMessage(
        receiverUid:
            widget.otherUid,
        requestId:
            _requestId,
        sessionId:
            _sessionId,
        mediaUrl:
            result.url,
        durationSeconds:
            result.durationSeconds,
      );

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to send video.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingVideo = false;
        });
      }
    }
  }

  // ============================================================
  // VOICE RECORDING
  // ============================================================

  Future<void> _toggleVoiceRecording() async {
    if (_uploadingPhoto ||
        _uploadingVideo) {
      return;
    }

    if (_recordingVoice) {
      await _stopVoiceRecording();
      return;
    }

    if (!_hasValidWalkScope) {
      return;
    }

    try {
      final bool permission =
          await _voiceService
              .hasPermission();

      if (!permission) {
        if (!mounted) {
          return;
        }

        _showSimpleMessage(
          'Microphone permission is required.',
        );

        return;
      }

      await _voiceService
          .startRecording();

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingVoice = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to start voice recording.',
        error,
      );
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_recordingVoice) {
      return;
    }

    if (mounted) {
      setState(() {
        _recordingVoice = false;
        _uploadingPhoto = true;
      });
    }

    try {
      final VoiceRecordingResult?
          recording =
          await _voiceService
              .stopRecording();

      if (recording == null) {
        return;
      }

      final String voiceUrl =
          await CloudinaryService
              .uploadVoice(
        file: recording.file,
        folder: 'chat/voice',
      );

      await _chatService
          .sendVoiceMessage(
        receiverUid:
            widget.otherUid,
        requestId:
            _requestId,
        sessionId:
            _sessionId,
        mediaUrl: voiceUrl,
        durationSeconds:
            recording.durationSeconds,
      );

      try {
        if (await recording.file
            .exists()) {
          await recording.file
              .delete();
        }
      } catch (_) {}

      _scrollToBottom();
    } catch (error) {
      try {
        await _voiceService
            .cancelRecording();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      _showError(
        'Unable to send voice message.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _recordingVoice = false;
          _uploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_recordingVoice) {
      return;
    }

    try {
      await _voiceService
          .cancelRecording();
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      _recordingVoice = false;
    });
  }

  // ============================================================
  // VOICE PLAYBACK
  // ============================================================

  Future<void> _toggleVoicePlayback(
    ChatMessage message,
  ) async {
    final String url =
        message.mediaUrl?.trim() ?? '';

    if (url.isEmpty) {
      _showSimpleMessage(
        'Voice message is unavailable.',
      );

      return;
    }

    try {
      await _voiceService
          .togglePlayback(
        messageId:
            message.id,
        audioUrl: url,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to play voice message.',
        error,
      );
    }
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 250,
          ),
          curve:
              Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessages() {
    if (widget.otherUid.trim().isEmpty ||
        !_hasValidWalkScope) {
      return const Center(
        child: Text(
          'Chat is unavailable.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      );
    }

    return StreamBuilder<
        List<ChatMessage>>(
      stream:
          _chatService.messagesStream(
        requestId:
            _requestId,
        sessionId:
            _sessionId,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<
                List<ChatMessage>>
            snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: _orange,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons
                        .chat_bubble_outline_rounded,
                    size: 44,
                    color: Colors.black26,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Text(
                    'Unable to load messages.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    '${snapshot.error}',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<ChatMessage>
            messages =
            snapshot.data ??
                <ChatMessage>[];

        if (messages.isEmpty) {
          return _buildEmptyChat();
        }

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            _scrollToBottom();
          },
        );

        return ListView.builder(
          controller:
              _scrollController,
          padding:
              const EdgeInsets.fromLTRB(
            14,
            18,
            14,
            18,
          ),
          itemCount:
              messages.length,
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            return _buildMessageBubble(
              messages[index],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration:
                  BoxDecoration(
                color:
                    _orange.withValues(
                  alpha: 0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .chat_bubble_rounded,
                size: 32,
                color: _orange,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Start a conversation',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Send a message to $_displayName.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(
    ChatMessage message,
  ) {
    final bool isMine =
        message.isMine(
      _chatService.currentUid,
    );

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(
                    context,
                  ).width *
                  0.78,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        child:
            _buildMessageContent(
          message,
          isMine,
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    ChatMessage message,
    bool isMine,
  ) {
    switch (message.type) {
      case ChatMessageType.text:
        return _buildTextBubble(
          message,
          isMine,
        );

      case ChatMessageType.photo:
        return _buildPhotoBubble(
          message,
          isMine,
        );

      case ChatMessageType.voice:
        return _buildVoiceBubble(
          message,
          isMine,
        );

      case ChatMessageType.video:
        return _buildVideoBubble(
          message,
          isMine,
        );
    }
  }

  // ============================================================
  // TEXT BUBBLE
  // ============================================================

  Widget _buildTextBubble(
    ChatMessage message,
    bool isMine,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            isMine
                ? _orange
                : Colors.white,
        borderRadius:
            BorderRadius.only(
          topLeft:
              const Radius.circular(
            18,
          ),
          topRight:
              const Radius.circular(
            18,
          ),
          bottomLeft:
              Radius.circular(
            isMine ? 18 : 4,
          ),
          bottomRight:
              Radius.circular(
            isMine ? 4 : 18,
          ),
        ),
        boxShadow: isMine
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color:
                      Color(0x0D000000),
                  blurRadius: 5,
                  offset:
                      Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: <Widget>[
          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: isMine
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          if (message.createdAt !=
              null) ...[
            const SizedBox(
              height: 4,
            ),
            Text(
              _formatTime(
                message.createdAt!,
              ),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white70
                    : Colors.black45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO BUBBLE
  // ============================================================

  Widget _buildPhotoBubble(
    ChatMessage message,
    bool isMine,
  ) {
    final String url =
        message.mediaUrl?.trim() ??
            '';

    if (url.isEmpty) {
      return _buildUnavailableMedia(
        'Photo unavailable',
        isMine,
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(5),
      decoration:
          BoxDecoration(
        color:
            isMine
                ? _orange
                : Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child: Image.network(
          url,
          width: 230,
          height: 230,
          fit: BoxFit.cover,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent?
                progress,
          ) {
            if (progress == null) {
              return child;
            }

            return const SizedBox(
              width: 230,
              height: 230,
              child: Center(
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _orange,
                ),
              ),
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace?
                stackTrace,
          ) {
            return const SizedBox(
              width: 230,
              height: 230,
              child: Center(
                child: Icon(
                  Icons
                      .broken_image_outlined,
                  size: 40,
                  color:
                      Colors.black26,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // VOICE BUBBLE
  // ============================================================

  Widget _buildVoiceBubble(
    ChatMessage message,
    bool isMine,
  ) {
    final int duration =
        message.durationSeconds ??
            0;

    final bool isPlaying =
        _playingVoiceMessageId ==
            message.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(
            _toggleVoicePlayback(
              message,
            ),
          );
        },
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration:
              BoxDecoration(
            color:
                isMine
                    ? _orange
                    : Colors.white,
            borderRadius:
                BorderRadius.only(
              topLeft:
                  const Radius.circular(
                18,
              ),
              topRight:
                  const Radius.circular(
                18,
              ),
              bottomLeft:
                  Radius.circular(
                isMine ? 18 : 4,
              ),
              bottomRight:
                  Radius.circular(
                isMine ? 4 : 18,
              ),
            ),
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color: isMine
                      ? Colors.white24
                      : _orange.withValues(
                          alpha: 0.10,
                        ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  isPlaying
                      ? Icons
                          .pause_rounded
                      : Icons
                          .play_arrow_rounded,
                  color: isMine
                      ? Colors.white
                      : _orange,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Icon(
                Icons
                    .graphic_eq_rounded,
                size: 28,
                color: isMine
                    ? Colors.white70
                    : _orange,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                _formatDuration(
                  duration,
                ),
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  color: isMine
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO BUBBLE
  // ============================================================

  Widget _buildVideoBubble(
    ChatMessage message,
    bool isMine,
  ) {
    final String url =
        message.mediaUrl?.trim() ??
            '';

    if (url.isEmpty) {
      return _buildUnavailableMedia(
        'Video unavailable',
        isMine,
      );
    }

    return _VideoMessageBubble(
      key: ValueKey<String>(
        message.id,
      ),
      url: url,
      durationSeconds:
          message.durationSeconds ??
              0,
      isMine: isMine,
    );
  }

  // ============================================================
  // UNAVAILABLE MEDIA
  // ============================================================

  Widget _buildUnavailableMedia(
    String text,
    bool isMine,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color:
            isMine
                ? _orange
                : Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons
                .error_outline_rounded,
            color: isMine
                ? Colors.white
                : Colors.black45,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            text,
            style: TextStyle(
              color: isMine
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT BAR
  // ============================================================

  Widget _buildInputBar() {
    final bool busy =
        _uploadingPhoto ||
            _uploadingVideo;

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.fromLTRB(
          4,
          8,
          4,
          8,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: <Widget>[
            if (!_recordingVoice)
              IconButton(
                onPressed: busy
                    ? null
                    : _showMediaOptions,
                tooltip: 'Media',
                icon: Icon(
                  Icons
                      .add_circle_outline_rounded,
                  color: busy
                      ? Colors.black26
                      : Colors.black54,
                ),
              )
            else
              IconButton(
                onPressed:
                    _cancelVoiceRecording,
                tooltip:
                    'Cancel recording',
                icon: const Icon(
                  Icons.close_rounded,
                  color:
                      Colors.redAccent,
                ),
              ),
            Expanded(
              child: _recordingVoice
                  ? _buildRecordingIndicator()
                  : TextField(
                      controller:
                          _messageController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction:
                          TextInputAction
                              .newline,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Type a message...',
                        filled: true,
                        fillColor:
                            const Color(
                          0xFFF4F4F4,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                    ),
            ),
            const SizedBox(
              width: 4,
            ),
            if (!_recordingVoice)
              IconButton(
                onPressed:
                    _sendingMessage ||
                            busy
                        ? null
                        : _sendTextMessage,
                tooltip: 'Send',
                icon: Icon(
                  Icons.send_rounded,
                  color:
                      _sendingMessage
                          ? Colors.black26
                          : _orange,
                ),
              )
            else
              IconButton(
                onPressed:
                    _stopVoiceRecording,
                tooltip:
                    'Stop and send voice',
                icon: const Icon(
                  Icons.send_rounded,
                  color: _orange,
                ),
              ),
            if (!_recordingVoice)
              IconButton(
                onPressed:
                    busy
                        ? null
                        : _toggleVoiceRecording,
                tooltip:
                    'Voice message',
                icon: const Icon(
                  Icons.mic_none_rounded,
                  color:
                      Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEDIA OPTIONS
  // ============================================================

  Future<void> _showMediaOptions() async {
    if (_uploadingPhoto ||
        _uploadingVideo ||
        _recordingVoice) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder:
          (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black12,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Send Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                _PhotoOptionTile(
                  icon: Icons
                      .camera_alt_rounded,
                  title: 'Photo',
                  subtitle:
                      'Take a photo',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    unawaited(
                      _showPhotoOptions(),
                    );
                  },
                ),
                const SizedBox(
                  height: 8,
                ),
                _PhotoOptionTile(
                  icon: Icons
                      .videocam_rounded,
                  title: 'Video',
                  subtitle:
                      'Record or choose a video',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    unawaited(
                      _showVideoOptions(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // RECORDING INDICATOR
  // ============================================================

  Widget _buildRecordingIndicator() {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF1EC),
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons
                .fiber_manual_record_rounded,
            size: 12,
            color:
                Colors.redAccent,
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'Recording voice message...',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.black87,
              ),
            ),
          ),
          Text(
            'Tap send',
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
  ) {
    return AppBar(
      backgroundColor:
          Colors.white,
      foregroundColor:
          Colors.black87,
      elevation: 0,
      surfaceTintColor:
          Colors.white,
      leading:
          IconButton(
        onPressed: () {
          Navigator.of(
            context,
          ).pop();
        },
        icon:
            const Icon(
          Icons
              .arrow_back_rounded,
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          _buildAvatar(
            radius: 20,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                const Text(
                  'Chat',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions:
          <Widget>[
        IconButton(
          tooltip: 'More',
          onPressed: () {},
          icon:
              const Icon(
            Icons
                .more_vert_rounded,
          ),
        ),
      ],
      bottom:
          const PreferredSize(
        preferredSize:
            Size.fromHeight(
          1,
        ),
        child:
            Divider(
          height: 1,
          thickness: 1,
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar({
    required double radius,
  }) {
    final String photo =
        widget.contactPhotoUrl
                ?.trim() ??
            '';

    if (photo.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor:
            _orange.withValues(
          alpha: 0.10,
        ),
        child: Icon(
          Icons.person_rounded,
          size: radius,
          color: _orange,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          _orange.withValues(
        alpha: 0.10,
      ),
      backgroundImage:
          NetworkImage(photo),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _showSimpleMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  void _showError(
    String message,
    Object error,
  ) {
    debugPrint(
      'ChatScreen error: $error',
    );

    _showSimpleMessage(
      message,
    );
  }

  String _formatTime(
    DateTime time,
  ) {
    final int hour =
        time.hour == 0
            ? 12
            : time.hour > 12
                ? time.hour - 12
                : time.hour;

    final String minute =
        time.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String period =
        time.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDuration(
    int seconds,
  ) {
    if (seconds <= 0) {
      return '0:01';
    }

    final int minutes =
        seconds ~/ 60;

    final int remaining =
        seconds % 60;

    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}

// ================================================================
// VIDEO MESSAGE BUBBLE
// ================================================================

class _VideoMessageBubble
    extends StatefulWidget {
  const _VideoMessageBubble({
    super.key,
    required this.url,
    required this.durationSeconds,
    required this.isMine,
  });

  final String url;
  final int durationSeconds;
  final bool isMine;

  @override
  State<_VideoMessageBubble>
      createState() =>
          _VideoMessageBubbleState();
}

class _VideoMessageBubbleState
    extends State<_VideoMessageBubble> {
  VideoPlayerController?
      _controller;

  bool _initializing = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  void didUpdateWidget(
    covariant _VideoMessageBubble oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.url !=
        widget.url) {
      unawaited(
        _replaceController(),
      );
    }
  }

  Future<void> _replaceController() async {
    await _disposeController();

    if (!mounted) {
      return;
    }

    await _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _initializing = true;
      _hasError = false;
    });

    final VideoPlayerController
        controller =
        VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );

    _controller = controller;

    try {
      await controller.initialize();

      await controller.setLooping(
        false,
      );

      if (!mounted ||
          _controller != controller) {
        await controller.dispose();
        return;
      }

      setState(() {
        _initializing = false;
      });
    } catch (_) {
      await controller.dispose();

      if (!mounted) {
        return;
      }

      if (_controller ==
          controller) {
        _controller = null;
      }

      setState(() {
        _initializing = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final VideoPlayerController?
        controller =
        _controller;

    if (controller == null ||
        !controller
            .value
            .isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.position >=
          controller.value.duration) {
        await controller.seekTo(
          Duration.zero,
        );
      }

      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _disposeController() async {
    final VideoPlayerController?
        controller =
        _controller;

    _controller = null;

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    final VideoPlayerController?
        controller =
        _controller;

    _controller = null;

    if (controller != null) {
      unawaited(
        controller.dispose(),
      );
    }

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isPlaying =
        _controller
                ?.value
                .isPlaying ??
            false;

    return Container(
      width: 250,
      decoration:
          BoxDecoration(
        color: widget.isMine
            ? _ChatScreenState
                ._orange
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap:
                _togglePlayback,
            child: AspectRatio(
              aspectRatio:
                  _controller
                          ?.value
                          .isInitialized ==
                      true
                  ? _controller!
                      .value
                      .aspectRatio
                  : 16 / 9,
              child: Stack(
                alignment:
                    Alignment.center,
                children: <Widget>[
                  if (_controller !=
                          null &&
                      _controller!
                          .value
                          .isInitialized)
                    VideoPlayer(
                      _controller!,
                    )
                  else
                    Container(
                      color: Colors.black12,
                    ),
                  if (_initializing)
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            _ChatScreenState
                                ._orange,
                      ),
                    ),
                  if (_hasError)
                    const Icon(
                      Icons
                          .broken_image_outlined,
                      size: 42,
                      color:
                          Colors.black38,
                    ),
                  if (!_initializing &&
                      !_hasError)
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                          const BoxDecoration(
                        color:
                            Colors.black45,
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons
                                .pause_rounded
                            : Icons
                                .play_arrow_rounded,
                        size: 32,
                        color:
                            Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              10,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons
                      .videocam_rounded,
                  size: 18,
                  color:
                      widget.isMine
                          ? Colors.white70
                          : _ChatScreenState
                              ._orange,
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  _formatDuration(
                    widget
                        .durationSeconds,
                  ),
                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        widget.isMine
                            ? Colors.white70
                            : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(
    int seconds,
  ) {
    if (seconds <= 0) {
      return '0:01';
    }

    final int minutes =
        seconds ~/ 60;

    final int remaining =
        seconds % 60;

    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}

// ================================================================
// MEDIA OPTION TILE
// ================================================================

class _PhotoOptionTile
    extends StatelessWidget {
  const _PhotoOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _orange =
      Color(0xFFFF6B35);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          const Color(0xFFF8F8F8),
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(
            14,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color:
                      _orange.withValues(
                    alpha: 0.10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _orange,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

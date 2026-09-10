// File:
// lib/features/contacts/screens/chat_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/voice_message_service.dart';
import '../../profile_setup/services/cloudinary_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.contactName,
    this.contactPhotoUrl,
    this.currentUserIsWalker = true,
  });

  final String otherUid;
  final String contactName;
  final String? contactPhotoUrl;
  final bool currentUserIsWalker;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _orange = Color(0xFFFF6B35);
  static const Color _lightBackground = Color(0xFFF7F7F7);

  final ChatService _chatService = ChatService();
  final VoiceMessageService _voiceService =
      VoiceMessageService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  bool _sendingMessage = false;
  bool _uploadingPhoto = false;
  bool _recordingVoice = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _displayName {
    final String name = widget.contactName.trim();

    if (name.isEmpty) {
      return widget.currentUserIsWalker ? 'Owner' : 'Walker';
    }

    return name;
  }

  Future<void> _sendTextMessage() async {
    final String text =
        _messageController.text.trim();

    if (text.isEmpty ||
        _sendingMessage ||
        widget.otherUid.trim().isEmpty) {
      return;
    }

    setState(() {
      _sendingMessage = true;
    });

    try {
      await _chatService.sendTextMessage(
        receiverUid: widget.otherUid,
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

  Future<void> _showPhotoOptions() async {
    if (_uploadingPhoto) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Send Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PhotoOptionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Camera',
                  subtitle: 'Take a new photo',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAndSendPhoto(
                      ImageSource.camera,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _PhotoOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Gallery',
                  subtitle: 'Choose from your photos',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAndSendPhoto(
                      ImageSource.gallery,
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

  Future<void> _pickAndSendPhoto(
    ImageSource source,
  ) async {
    if (_uploadingPhoto) {
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

      setState(() {
        _uploadingPhoto = true;
      });

      final File file = File(selected.path);

      final String imageUrl =
          await CloudinaryService.uploadImage(
        file: file,
        folder: 'chat/photos',
      );

      await _chatService.sendPhotoMessage(
        receiverUid: widget.otherUid,
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

  Future<void> _toggleVoiceRecording() async {
    if (_uploadingPhoto) {
      return;
    }

    if (_recordingVoice) {
      await _stopVoiceRecording();
      return;
    }

    try {
      final bool permission =
          await _voiceService.hasPermission();

      if (!permission) {
        if (!mounted) {
          return;
        }

        _showSimpleMessage(
          'Microphone permission is required.',
        );
        return;
      }

      await _voiceService.startRecording();

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

    setState(() {
      _recordingVoice = false;
      _uploadingPhoto = true;
    });

    try {
      final VoiceRecordingResult? recording =
          await _voiceService.stopRecording();

      if (recording == null) {
        return;
      }

      final String voiceUrl =
          await CloudinaryService.uploadVoice(
        file: recording.file,
        folder: 'chat/voice',
      );

      await _chatService.sendVoiceMessage(
        receiverUid: widget.otherUid,
        mediaUrl: voiceUrl,
        durationSeconds:
            recording.durationSeconds,
      );

      try {
        if (await recording.file.exists()) {
          await recording.file.delete();
        }
      } catch (_) {
        // Ignore temporary file cleanup errors.
      }

      _scrollToBottom();
    } catch (error) {
      try {
        await _voiceService.cancelRecording();
      } catch (_) {
        // Ignore cleanup errors.
      }

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
      await _voiceService.cancelRecording();
    } catch (_) {
      // Ignore cancellation errors.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _recordingVoice = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 250,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSimpleMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
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

    _showSimpleMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
        Theme.of(context);

    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: _buildAppBar(theme),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _buildMessages(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          _buildAvatar(
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'More',
          onPressed: () {},
          icon: const Icon(
            Icons.more_vert_rounded,
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (widget.otherUid.trim().isEmpty) {
      return const Center(
        child: Text(
          'Chat is unavailable.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      );
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.messagesStream(
        otherUid: widget.otherUid,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<ChatMessage>> snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: _orange,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 44,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<ChatMessage> messages =
            snapshot.data ??
                <ChatMessage>[];

        if (messages.isEmpty) {
          return _buildEmptyChat();
        }

        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            _scrollToBottom();
          },
        );

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            14,
            18,
            14,
            18,
          ),
          itemCount: messages.length,
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final ChatMessage message =
                messages[index];

            return _buildMessageBubble(
              message,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _orange.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                size: 32,
                color: _orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a message to $_displayName.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(context).width *
                  0.78,
        ),
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        child: _buildMessageContent(
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
    }
  }

  Widget _buildTextBubble(
    ChatMessage message,
    bool isMine,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? _orange
            : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(
            isMine ? 18 : 4,
          ),
          bottomRight: Radius.circular(
            isMine ? 4 : 18,
          ),
        ),
        boxShadow: isMine
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
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
          if (message.createdAt != null) ...[
            const SizedBox(height: 4),
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

  Widget _buildPhotoBubble(
    ChatMessage message,
    bool isMine,
  ) {
    final String url =
        message.mediaUrl?.trim() ?? '';

    if (url.isEmpty) {
      return _buildUnavailableMedia(
        'Photo unavailable',
        isMine,
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isMine
            ? _orange
            : Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 230,
          height: 230,
          fit: BoxFit.cover,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? progress,
          ) {
            if (progress == null) {
              return child;
            }

            return const SizedBox(
              width: 230,
              height: 230,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _orange,
                ),
              ),
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const SizedBox(
              width: 230,
              height: 230,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: Colors.black26,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(
    ChatMessage message,
    bool isMine,
  ) {
    final int duration =
        message.durationSeconds ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? _orange
            : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(
            isMine ? 18 : 4,
          ),
          bottomRight: Radius.circular(
            isMine ? 4 : 18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isMine
                  ? Colors.white24
                  : _orange.withValues(
                      alpha: 0.10,
                    ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isMine
                  ? Colors.white
                  : _orange,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.graphic_eq_rounded,
            size: 28,
            color: isMine
                ? Colors.white70
                : _orange,
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(
              duration,
            ),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isMine
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableMedia(
    String text,
    bool isMine,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMine
            ? _orange
            : Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: isMine
                ? Colors.white
                : Colors.black45,
          ),
          const SizedBox(width: 8),
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

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(
          8,
          8,
          8,
          8,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: <Widget>[
            if (!_recordingVoice)
              IconButton(
                onPressed:
                    _uploadingPhoto
                        ? null
                        : _showPhotoOptions,
                tooltip: 'Photo',
                icon: Icon(
                  Icons.add_a_photo_outlined,
                  color: _uploadingPhoto
                      ? Colors.black26
                      : Colors.black54,
                ),
              )
            else
              IconButton(
                onPressed:
                    _cancelVoiceRecording,
                tooltip: 'Cancel recording',
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
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
                          TextInputAction.newline,
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
                              BorderRadius.circular(
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
            const SizedBox(width: 6),
            if (!_recordingVoice)
              IconButton(
                onPressed:
                    _sendingMessage
                        ? null
                        : _sendTextMessage,
                tooltip: 'Send',
                icon: const Icon(
                  Icons.send_rounded,
                  color: _orange,
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
                    _toggleVoiceRecording,
                tooltip: 'Voice message',
                icon: const Icon(
                  Icons.mic_none_rounded,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      height: 48,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.fiber_manual_record_rounded,
            size: 12,
            color: Colors.redAccent,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recording voice message...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            'Tap send',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatTime(DateTime time) {
    final int hour =
        time.hour == 0
            ? 12
            : time.hour > 12
                ? time.hour - 12
                : time.hour;

    final String minute =
        time.minute
            .toString()
            .padLeft(2, '0');

    final String period =
        time.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDuration(int seconds) {
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
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      _orange.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: _orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                    const SizedBox(height: 3),
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
                Icons.chevron_right_rounded,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

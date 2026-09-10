import 'package:flutter/material.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    this.timestamp,
    this.voiceUrl,
    this.photoUrl,
  });

  final String text;
  final bool isMine;
  final DateTime? timestamp;
  final String? voiceUrl;
  final String? photoUrl;
}

class ChatSheet extends StatefulWidget {
  const ChatSheet({
    super.key,
    required this.contactName,
    this.contactPhotoUrl,
    this.initialMessages = const <ChatMessage>[],
    this.currentUserIsWalker = true,
  });

  final String contactName;
  final String? contactPhotoUrl;
  final List<ChatMessage> initialMessages;
  final bool currentUserIsWalker;

  static Future<void> show(
    BuildContext context, {
    required String contactName,
    String? contactPhotoUrl,
    List<ChatMessage> initialMessages = const <ChatMessage>[],
    bool currentUserIsWalker = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChatSheet(
          contactName: contactName,
          contactPhotoUrl: contactPhotoUrl,
          initialMessages: initialMessages,
          currentUserIsWalker: currentUserIsWalker,
        );
      },
    );
  }

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  late final TextEditingController _messageController;
  late final ScrollController _scrollController;
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();

    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messages = List<ChatMessage>.from(widget.initialMessages);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMine: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  CircleAvatar(
                    radius: 21,
                    backgroundImage: widget.contactPhotoUrl != null &&
                            widget.contactPhotoUrl!.trim().isNotEmpty
                        ? NetworkImage(widget.contactPhotoUrl!)
                        : null,
                    child: widget.contactPhotoUrl == null ||
                            widget.contactPhotoUrl!.trim().isEmpty
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.contactName.trim().isEmpty
                          ? 'Owner'
                          : widget.contactName.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ChatMessage message = _messages[index];

                        return Align(
                          alignment: message.isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: message.isMine
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: message.isMine
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () {},
                      tooltip: 'Voice message',
                      icon: const Icon(Icons.mic_none_rounded),
                    ),
                    IconButton(
                      onPressed: () {},
                      tooltip: 'Camera',
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _sendMessage,
                      tooltip: 'Send',
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

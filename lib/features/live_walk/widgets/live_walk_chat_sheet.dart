import 'package:flutter/material.dart';

class LiveWalkChatSheet extends StatefulWidget {
  const LiveWalkChatSheet({
    super.key,
    required this.ownerName,
    this.ownerPhotoUrl,
    this.initialMessages = const [],
  });

  final String ownerName;
  final String? ownerPhotoUrl;
  final List<LiveWalkChatMessage> initialMessages;

  static Future<void> show(
    BuildContext context, {
    required String ownerName,
    String? ownerPhotoUrl,
    List<LiveWalkChatMessage> initialMessages = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return LiveWalkChatSheet(
          ownerName: ownerName,
          ownerPhotoUrl: ownerPhotoUrl,
          initialMessages: initialMessages,
        );
      },
    );
  }

  @override
  State<LiveWalkChatSheet> createState() => _LiveWalkChatSheetState();
}

class _LiveWalkChatSheetState extends State<LiveWalkChatSheet> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  late List<LiveWalkChatMessage> _messages;

  @override
  void initState() {
    super.initState();

    _messages = List<LiveWalkChatMessage>.from(widget.initialMessages);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        LiveWalkChatMessage(
          text: text,
          sender: LiveWalkChatSender.walker,
          time: DateTime.now(),
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

    // TODO:
    // Firestore real-time message sending can be connected here.
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(
                height: 1,
                thickness: 1,
              ),
              Expanded(
                child: _buildMessages(),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF1E8),
              image: widget.ownerPhotoUrl != null &&
                      widget.ownerPhotoUrl!.trim().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.ownerPhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.ownerPhotoUrl == null ||
                    widget.ownerPhotoUrl!.trim().isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFD95F00),
                    size: 22,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.close_rounded,
                size: 21,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFFD95F00),
                  size: 31,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start a conversation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF252525),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Send a message to keep the owner updated about the walk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF858585),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return _ChatBubble(
          message: message,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
                onSubmitted: (_) {
                  _sendMessage();
                },
              ),
            ),
          ),
          const SizedBox(width: 9),
          Material(
            color: const Color(0xFFD95F00),
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(17),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
  });

  final LiveWalkChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isWalker =
        message.sender == LiveWalkChatSender.walker;

    final time = _formatTime(message.time);

    return Align(
      alignment:
          isWalker ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isWalker ? 48 : 0,
          right: isWalker ? 0 : 48,
          bottom: 10,
        ),
        child: Column(
          crossAxisAlignment: isWalker
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isWalker
                    ? const Color(0xFFD95F00)
                    : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17),
                  topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(
                    isWalker ? 17 : 4,
                  ),
                  bottomRight: Radius.circular(
                    isWalker ? 4 : 17,
                  ),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: isWalker
                      ? Colors.white
                      : const Color(0xFF303030),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

enum LiveWalkChatSender {
  owner,
  walker,
}

class LiveWalkChatMessage {
  const LiveWalkChatMessage({
    required this.text,
    required this.sender,
    required this.time,
  });

  final String text;
  final LiveWalkChatSender sender;
  final DateTime time;
}

// lib/widgets/chat/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat_message.dart';

class MessageBubble extends StatefulWidget {

  const MessageBubble({
    super.key,
    required this.message,
    required this.onFeedback,
    this.onSuggestionTap,
  });
  final ChatMessage message;
  final Function(bool isHelpful, String? note) onFeedback;
  final Function(String suggestion)? onSuggestionTap;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Validasi content null
    if (widget.message.content.isEmpty) {
      return const SizedBox.shrink(); // Jangan tampilkan pesan kosong
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: widget.message.isUser ? 50 : 0,
        right: widget.message.isUser ? 0 : 50,
      ),
      child: Column(
        crossAxisAlignment: widget.message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Message row
          Row(
            mainAxisAlignment: widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.message.isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.message.isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: widget.message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: widget.message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: MarkdownBody(
                    data: widget.message.content,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      if (href != null) launchUrl(Uri.parse(href));
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: widget.message.isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      listBullet: TextStyle(
                        color: widget.message.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.message.isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ],
          ),

          // Suggestions chips - handle null suggestions
          if (widget.message.isBot && 
              widget.message.suggestions != null && 
              widget.message.suggestions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 40,
                top: 8,
                bottom: 4,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.message.suggestions!.map((suggestion) {
                  if (suggestion.isEmpty) return const SizedBox.shrink();
                  
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      if (widget.onSuggestionTap != null) {
                        widget.onSuggestionTap!(suggestion);
                      }
                    },
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              left: widget.message.isUser ? 0 : 40,
              right: widget.message.isUser ? 40 : 0,
              top: 4,
            ),
            child: Text(
              widget.message.displayTime, // Gunakan getter yang aman
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
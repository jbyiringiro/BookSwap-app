// lib/widgets/chat_bubble.dart (ensure it's correctly implemented)

import 'package:flutter/material.dart';

/// Widget to display a single chat message bubble.
/// Differentiates between messages sent by the current user and received messages.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isCurrentUser; // Determines alignment and styling
  final DateTime timestamp; // Add the timestamp parameter

  const ChatBubble({
    super.key,
    required this.text,
    required this.isCurrentUser,
    required this.timestamp, // Require the timestamp
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) // Show a simple avatar or placeholder for the sender
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue[200] : Colors.grey[300], // Changed from yellow (Colors.yellow[200]) to blue
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatTime(this.timestamp), // Use the provided timestamp
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isCurrentUser) // Show a simple avatar or placeholder for the current user
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  /// Helper function to format the timestamp (e.g., "10:30 AM", "Yesterday").
  String _formatTime(DateTime time) {
    // Example: HH:MM format
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/bottom_nav_bar.dart';

/// Main screen displaying a list of active chats for the user.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final currentUser = authProvider.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Text(
                'Please sign in to access messages.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Stream the user's chat rooms
          return StreamBuilder<List<ChatRoom>>(
            stream: ChatService().getUserChatRooms(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading chats: ${snapshot.error}'));
              }

              List<ChatRoom> chatRooms = snapshot.data ?? [];

              if (chatRooms.isEmpty) {
                return const Center(
                  child: Text(
                    'No active chats yet.\n\nStart a conversation after initiating a swap!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = chatRooms[index];
                  return ChatRoomCard(chatRoom: chatRoom, currentUserId: currentUser.uid);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 2), // Assuming index 2 is for Chat
    );
  }
}

/// Widget representing a single chat room in the list.
class ChatRoomCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const ChatRoomCard({super.key, required this.chatRoom, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Determine the other user's ID based on the current user's ID
    String otherUserId = (chatRoom.participants[0] == currentUserId)
        ? chatRoom.participants[1]
        : chatRoom.participants[0];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.grey),
        ),
        title: Text(
          chatRoom.otherUserName ?? otherUserId,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          chatRoom.lastMessageText ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: chatRoom.lastMessageTimestamp != null
            ? Text(
                _formatLastMessageTime(chatRoom.lastMessageTimestamp!),
                style: const TextStyle(color: Colors.grey),
              )
            : null,
        onTap: () {
          // Navigate to the detailed chat screen for this room
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatRoomId: chatRoom.id, currentUserId: currentUserId),
            ),
          );
        },
      ),
    );
  }

  /// Helper to format the time of the last message.
  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Detailed chat screen for a specific chat room.
class ChatDetailScreen extends StatelessWidget {
  final String chatRoomId;
  final String currentUserId; // Pass the current user's ID

  const ChatDetailScreen({super.key, required this.chatRoomId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService().getChatMessages(chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages: ${snapshot.error}'));
                }

                List<ChatMessage> messages = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUserId; // Check against passed ID
                    // Use the imported ChatBubble widget here, passing the timestamp
                    return ChatBubble(
                      text: message.text,
                      isCurrentUser: isCurrentUser,
                      timestamp: message.timestamp,
                    );
                  },
                );
              },
            ),
          ),
          // Message Input
          _buildMessageInput(context, currentUserId), // Pass currentUserId to input builder
        ],
      ),
    );
  }

  /// Builds the message input field and send button.
  Widget _buildMessageInput(BuildContext context, String currentUserId) {
    final _controller = TextEditingController();

    void _sendMessage() {
      String text = _controller.text.trim();
      if (text.isNotEmpty) {
        ChatService().sendMessage(chatRoomId, currentUserId, text);
        _controller.clear();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(), // Send on press Enter/Done
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: Colors.blue, // Changed from yellow (Color(0xFFE6B84D)) to blue
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
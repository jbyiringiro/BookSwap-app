// lib/models/chat_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between two users involved in a swap.
class ChatRoom {
  /// Unique ID for the chat room (typically derived from participant UIDs).
  final String id;

  /// List of user UIDs participating in this chat.
  final List<String> participants;

  /// UID of the current user (for UI convenience).
  final String currentUserId;

  /// UID of the other user in the chat.
  final String otherUserId;

  /// Timestamp of the last message in this room.
  final DateTime? lastMessageTimestamp;

  /// Text content of the last message.
  final String? lastMessageText;

  /// UID of the sender of the last message.
  final String? lastMessageSenderId;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.currentUserId,
    required this.otherUserId,
    this.lastMessageTimestamp,
    this.lastMessageText,
    this.lastMessageSenderId,
  });

  /// Factory method to create a ChatRoom from a Firestore document snapshot.
  factory ChatRoom.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;

    String userId1 = data['participants'][0];
    String userId2 = data['participants'][1];

    // Determine the other user's ID based on the current user's ID
    String otherUserId = (userId1 == currentUserId) ? userId2 : userId1;

    Map<String, dynamic>? lastMessageData = data['lastMessage'] as Map<String, dynamic>?;

    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants']),
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      lastMessageTimestamp: (lastMessageData?['timestamp'] as Timestamp?)?.toDate(),
      lastMessageText: lastMessageData?['text'],
      lastMessageSenderId: lastMessageData?['senderId'],
    );
  }
}

/// Represents a single chat message.
class ChatMessage {
  /// Unique ID for the message document.
  final String id;

  /// Content of the message.
  final String text;

  /// UID of the user who sent the message.
  final String senderId;

  /// Timestamp when the message was sent.
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  /// Factory method to create a ChatMessage from a Firestore document snapshot.
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the message object to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
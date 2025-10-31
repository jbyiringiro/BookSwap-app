// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

/// Service class for handling chat operations with Firebase Firestore.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a unique, deterministic chat room ID for two users.
  /// This ensures both users get the same room ID regardless of who initiates.
  String _generateChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Sort to ensure consistency (e.g., "A_B" vs "B_A")
    return ids.join('_');
  }

  /// Creates or retrieves a chat room ID for two users.
  /// This method ensures the chat room document exists in Firestore.
  Future<String> getOrCreateChatRoomId(String userId1, String userId2) async {
    String chatRoomId = _generateChatRoomId(userId1, userId2);

    // Check if the chat room already exists
    DocumentSnapshot roomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();

    if (!roomDoc.exists) {
      // Create the chat room document if it doesn't exist
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'participants': [userId1, userId2], // Store both UIDs
        'createdAt': Timestamp.now(),
        'lastMessage': null, // Initialize with no last message
      });
    }

    return chatRoomId;
  }

  /// Sends a message to a specific chat room.
  /// Updates the message list in the subcollection and the 'lastMessage' field in the main room document.
  Future<void> sendMessage(String chatRoomId, String senderId, String text) async {
    if (text.trim().isEmpty) return; // Don't send empty messages

    try {
      // Create a new message document in the 'messages' subcollection
      DocumentReference newMessageRef = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': text.trim(),
        'senderId': senderId,
        'timestamp': Timestamp.now(),
      });

      // Update the 'lastMessage' field in the main chat room document
      // This allows quick fetching of the latest message for chat lists
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': {
          'id': newMessageRef.id,
          'text': text.trim(),
          'senderId': senderId,
          'timestamp': Timestamp.now(),
        },
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow; // Re-throw to be handled by the caller if needed
    }
  }

  /// Retrieves a stream of all chat rooms for the current user.
  /// Filters rooms where the current user is listed as a participant.
  Stream<List<ChatRoom>> getUserChatRooms(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId) // Query for rooms containing the user
        .orderBy('lastMessage.timestamp', descending: true) // Order by last message time
        .snapshots()
        .map((snapshot) {
      List<ChatRoom> chatRooms = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        // Use the factory method to create ChatRoom objects
        chatRooms.add(ChatRoom.fromFirestore(doc, currentUserId));
      }
      return chatRooms;
    });
  }

  /// Retrieves a stream of messages for a specific chat room.
  /// Orders messages by timestamp in ascending order (oldest first).
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Oldest first for chat display
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }
}
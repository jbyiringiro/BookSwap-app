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

  /// Creates or retrieves a chat room ID for two users involved in a swap.
  /// This method ensures the chat room document exists in Firestore.
  /// It should be called when a swap is initiated or accepted.
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
      print('Created new chat room: $chatRoomId'); // Debug log
    } else {
      print('Found existing chat room: $chatRoomId'); // Debug log
    }

    return chatRoomId;
  }

  /// Gets a stream of chat rooms for the current user.
  /// Filters rooms where the user's ID is in the 'participants' array.
  Stream<List<ChatRoom>> getUserChatRooms(String currentUserId) {
    print('DEBUG: Fetching chat rooms for user: $currentUserId'); // Debug log
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessage.timestamp', descending: true) // Order by last message time
        .snapshots()
        .map((snapshot) {
      List<ChatRoom> rooms = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        // Use the factory method to create ChatRoom objects
        rooms.add(ChatRoom.fromFirestore(doc, currentUserId));
      }
      print('DEBUG: Retrieved ${rooms.length} chat rooms'); // Debug log
      return rooms;
    });
  }

  /// Gets a stream of messages for a specific chat room.
  /// Orders messages by timestamp in ascending order (oldest first).
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    print('DEBUG: Fetching messages for chat room: $chatRoomId'); // Debug log
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages') // Subcollection for messages
        .orderBy('timestamp', descending: false) // Oldest first for chat display
        .snapshots()
        .map((snapshot) {
      List<ChatMessage> messages = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        // Use the factory method to create ChatMessage objects
        messages.add(ChatMessage.fromFirestore(doc));
      }
      print('DEBUG: Retrieved ${messages.length} messages'); // Debug log
      return messages;
    });
  }

  /// Sends a message to a specific chat room.
  /// Updates the message list in the subcollection and the 'lastMessage' field in the main room document.
  Future<void> sendMessage(String chatRoomId, String senderId, String text) async {
    if (text.trim().isEmpty) {
      print('DEBUG: Cannot send empty message'); // Debug log
      return; // Don't send empty messages
    }

    try {
      print('DEBUG: Sending message to room: $chatRoomId, sender: $senderId, text: $text'); // Debug log

      // Add the new message to the 'messages' subcollection
      DocumentReference newMessageRef = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages') // Subcollection for messages
          .add({
        'text': text.trim(),
        'senderId': senderId,
        'timestamp': Timestamp.now(),
      });

      // Update the main 'chat_rooms' document with the details of the new message
      // This allows quick fetching of the latest message for chat lists
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': {
          'id': newMessageRef.id, // Store the message ID
          'text': text.trim(),
          'senderId': senderId,
          'timestamp': Timestamp.now(), // Use Firestore timestamp
        },
      });

      print('DEBUG: Message sent successfully'); // Debug log
    } catch (e) {
      print('ERROR sending message: $e'); // Error log
      rethrow; // Re-throw to be handled by the UI if needed
    }
  }
}
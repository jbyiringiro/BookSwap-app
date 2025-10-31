import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat room
  Future<String> createChatRoom(String userId1, String userId2) async {
    try {
      // Ensure consistent room ID regardless of user order
      List<String> sortedUsers = [userId1, userId2]..sort();
      String roomId = sortedUsers.join('_');
      
      // Check if chat room already exists
      DocumentSnapshot roomDoc = await _firestore.collection('chat_rooms').doc(roomId).get();
      
      if (!roomDoc.exists) {
        // Create new chat room
        await _firestore.collection('chat_rooms').doc(roomId).set({
          'participants': [userId1, userId2],
          'createdAt': Timestamp.now(),
          'lastMessage': null,
        });
      }
      
      return roomId;
    } catch (e) {
      print('Error creating chat room: $e');
      throw e;
    }
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      List<ChatRoom> chatRooms = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> participants = List<String>.from(data['participants']);
        String otherUser = participants.firstWhere((p) => p != userId);
        
        ChatMessage? lastMessage;
        if (data['lastMessage'] != null) {
          Map<String, dynamic> lastMsgData = data['lastMessage'] as Map<String, dynamic>;
          lastMessage = ChatMessage(
            id: lastMsgData['id'] ?? '',
            text: lastMsgData['text'] ?? '',
            senderId: lastMsgData['senderId'] ?? '',
            timestamp: (lastMsgData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }
        
        chatRooms.add(ChatRoom(
          id: doc.id,
          participants: participants,
          currentUserId: userId,
          otherUserId: otherUser,
          lastMessage: lastMessage,
        ));
      }
      return chatRooms;
    });
  }

  // Get chat messages
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ChatMessage(
          id: doc.id,
          text: data['text'] ?? '',
          senderId: data['senderId'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String chatRoomId, String senderId, String text) async {
    try {
      // Add message to chat room
      DocumentReference messageRef = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': senderId,
        'timestamp': Timestamp.now(),
      });

      // Update last message in chat room
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': {
          'id': messageRef.id,
          'text': text,
          'senderId': senderId,
          'timestamp': Timestamp.now(),
        },
      });
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }
}
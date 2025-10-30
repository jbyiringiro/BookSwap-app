import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'chatId': chatId,
          'senderId': senderId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });

    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [senderId],
    }, SetOptions(merge: true));
  }
}

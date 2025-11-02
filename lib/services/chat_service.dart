Future<List<Map<String, dynamic>>> loadUserChats(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => {
      ...doc.data(),
      'id': doc.id,
    }).toList();
  } catch (e) {
    throw Exception('Error loading chats: $e');
  }
}

Future<String> createChatRoom(String userId1, String userId2, String swapId) async {
  try {
    final chatRef = FirebaseFirestore.instance.collection('chat_rooms').doc();
    
    await chatRef.set({
      'participants': [userId1, userId2],
      'createdAt': FieldValue.serverTimestamp(),
      'swapId': swapId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    return chatRef.id;
  } catch (e) {
    throw Exception('Error creating chat room: $e');
  }
}

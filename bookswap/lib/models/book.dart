import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final String status; // available, pending, swapped
  final String? swapWithUserId;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.status = 'available',
    this.swapWithUserId,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? 'Used',
      imageUrl: data['imageUrl'],
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'available',
      swapWithUserId: data['swapWithUserId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'swapWithUserId': swapWithUserId,
    };
  }
}

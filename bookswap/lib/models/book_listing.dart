import 'package:cloud_firestore/cloud_firestore.dart';

class BookListing {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String condition;
  final String swapFor;
  final DateTime createdAt;
  final String? imageUrl;
  bool isAvailable;
  final String? isbn;
  final String? description;

  BookListing({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapFor,
    required this.createdAt,
    this.imageUrl,
    this.isAvailable = true,
    this.isbn,
    this.description,
  });

  factory BookListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookListing(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? '',
      swapFor: data['swapFor'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      isbn: data['isbn'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isbn': isbn,
      'description': description,
      'updatedAt': Timestamp.now(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

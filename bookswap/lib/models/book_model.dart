import 'package:cloud_firestore/cloud_firestore.dart';

class BookListing {
  final String id;
  final String title;
  final String author;
  final String condition; // 'New', 'Like New', 'Good', 'Used'
  final String ownerId;
  final String ownerName;
  final String? imageUrl;
  final DateTime createdAt;
  final String? swapFor; // What the user wants in exchange
  final String swapStatus; // 'Available', 'Pending', 'Completed'
  final String? requestedBy; // UID of user who requested swap
  final String? requestedByName; // Name of user who requested swap

  BookListing({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.ownerId,
    required this.ownerName,
    this.imageUrl,
    required this.createdAt,
    this.swapFor,
    required this.swapStatus,
    this.requestedBy,
    this.requestedByName,
  });

  /// Create from Firestore document
  factory BookListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookListing(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? 'Used',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      swapFor: data['swapFor'],
      swapStatus: data['swapStatus'] ?? 'Available',
      requestedBy: data['requestedBy'],
      requestedByName: data['requestedByName'],
    );
  }

  /// Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'swapFor': swapFor,
      'swapStatus': swapStatus,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
    };
  }
}
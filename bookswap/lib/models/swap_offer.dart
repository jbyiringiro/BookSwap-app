import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapStatus { pending, accepted, rejected, completed }

class SwapOffer {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String bookListingId;
  final String offeredBookId;
  final SwapStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? message;

  SwapOffer({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.bookListingId,
    required this.offeredBookId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.message,
  });

  factory SwapOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwapOffer(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      bookListingId: data['bookListingId'] ?? '',
      offeredBookId: data['offeredBookId'] ?? '',
      status: SwapStatus.values[data['status'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      message: data['message'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'bookListingId': bookListingId,
      'offeredBookId': offeredBookId,
      'status': status.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'message': message,
    };
  }
}

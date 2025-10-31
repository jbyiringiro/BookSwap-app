import 'package:cloud_firestore/cloud_firestore.dart';

class BookSwapUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isEmailVerified;

  BookSwapUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.isEmailVerified,
  });

  /// Convert from Firestore data
  factory BookSwapUser.fromFirebaseUser(
      Map<String, dynamic> userData, String uid) {
    return BookSwapUser(
      uid: uid,
      email: userData['email'] ?? '',
      displayName: userData['displayName'] ?? 'User',
      photoUrl: userData['photoUrl'],
      createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEmailVerified: userData['isEmailVerified'] ?? false,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEmailVerified': isEmailVerified,
    };
  }
}
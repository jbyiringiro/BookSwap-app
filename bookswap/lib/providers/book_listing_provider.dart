import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/book_listing.dart';

class BookListingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<BookListing> _listings = [];
  bool _isLoading = false;
  String? _error;

  List<BookListing> get listings => _listings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<BookListing> get availableListings =>
      _listings.where((listing) => listing.isAvailable).toList();

  BookListingProvider() {
    _loadListings();
  }

  Future<void> _loadListings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            _listings = snapshot.docs
                .map((doc) => BookListing.fromFirestore(doc))
                .toList();
            _isLoading = false;
            notifyListeners();
          });
    } catch (e) {
      _error = 'Failed to load listings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  List<BookListing> getUserListings(String userId) {
    return _listings.where((listing) => listing.userId == userId).toList();
  }

  Future<String> addListing(
    BookListing listing, [
    List<int>? imageBytes,
  ]) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? imageUrl;

      // Upload image if provided
      if (imageBytes != null) {
        final storageRef = _storage.ref().child(
          'book_images/${listing.id}.jpg',
        );
        await storageRef.putData(imageBytes);
        imageUrl = await storageRef.getDownloadURL();
      }

      final listingWithImage = BookListing(
        id: listing.id,
        userId: listing.userId,
        title: listing.title,
        author: listing.author,
        condition: listing.condition,
        swapFor: listing.swapFor,
        createdAt: listing.createdAt,
        imageUrl: imageUrl,
        isAvailable: listing.isAvailable,
        isbn: listing.isbn,
        description: listing.description,
      );

      await _firestore
          .collection('listings')
          .doc(listing.id)
          .set(listingWithImage.toFirestore());

      _error = null;
      return listing.id;
    } catch (e) {
      _error = 'Failed to add listing: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateListing(String id, BookListing updatedListing) async {
    try {
      await _firestore
          .collection('listings')
          .doc(id)
          .update(updatedListing.toFirestore());
      _error = null;
    } catch (e) {
      _error = 'Failed to update listing: $e';
      rethrow;
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _firestore.collection('listings').doc(id).delete();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete listing: $e';
      rethrow;
    }
  }

  BookListing? getListing(String id) {
    try {
      return _listings.firstWhere((listing) => listing.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<BookListing>> searchListings(String query) async {
    if (query.isEmpty) return _listings;

    final lowercaseQuery = query.toLowerCase();
    return _listings.where((listing) {
      return listing.title.toLowerCase().contains(lowercaseQuery) ||
          listing.author.toLowerCase().contains(lowercaseQuery) ||
          listing.condition.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

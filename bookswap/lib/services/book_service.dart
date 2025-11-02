// lib/services/book_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/book_model.dart';
import 'chat_service.dart';

/// Service class for handling all book-related operations with Firebase
/// Includes creating, reading, updating, deleting books and managing swaps
class BookService {
  // Instance of Firestore for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Instance of Firebase Storage for image uploads
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Instance of ChatService for creating chat rooms on swap request
  final ChatService _chatService = ChatService(); // Assuming you have this import

  /// Creates a new book listing in Firestore
  /// 
  /// [title] - Book title
  /// [author] - Book author  
  /// [condition] - Book condition (New, Like New, Good, Used)
  /// [ownerId] - UID of the book owner
  /// [ownerName] - Name of the book owner
  /// [swapFor] - What the user wants in exchange (optional)
  /// [imageFile] - Book cover image file (optional)
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> createBookListing({
    required String title,
    required String author,
    required String condition,
    required String ownerId,
    required String ownerName,
    String? swapFor,
    File? imageFile, // Optional image file
  }) async {
    try {
      // Variable to store the uploaded image URL
      String? imageUrl;
      
      // Upload image if provided (with timeout)
      if (imageFile != null) {
        try {
          imageUrl = await _uploadImageWithTimeout(imageFile, ownerId);
        } catch (e) {
          print('Error uploading image: $e');
          // Decide: Fail the whole operation or proceed without image
          // For now, let's proceed without the image to avoid losing the listing
          imageUrl = null; 
        }
      }

      // Create the book document in Firestore
      DocumentReference docRef = await _firestore.collection('books').add({
        'title': title,
        'author': author,
        'condition': condition,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'imageUrl': imageUrl, // This will be null if upload failed or no image provided
        'createdAt': Timestamp.now(),
        'swapFor': swapFor,
        'swapStatus': 'Available',
        'requestedBy': null,
        'requestedByName': null,
      });

      print('Book created successfully with ID: ${docRef.id}');
      return true;
    } catch (e) {
      // Print error to console for debugging
      print('Error creating book listing: $e');
      return false;
    }
  }

  /// Uploads an image file to Firebase Storage with a timeout
  /// This prevents the app from hanging if the upload takes too long
  Future<String> _uploadImageWithTimeout(File imageFile, String ownerId) async {
    return _uploadImage(imageFile, ownerId).timeout(
      const Duration(seconds: 30), // 30-second timeout
      onTimeout: () {
        // Throw a timeout exception if upload takes too long
        throw TimeoutException('Image upload took too long', const Duration(seconds: 30));
      },
    );
  }

  /// Actual image upload function
  /// Uploads the image to Firebase Storage and returns the download URL
  Future<String> _uploadImage(File imageFile, String ownerId) async {
    // Validate the file exists
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    // Create a unique filename using owner ID and timestamp
    String fileName = 'book_images/${ownerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // Get a reference to the storage location
    Reference storageRef = _storage.ref().child(fileName);
    
    // Start the upload process
    UploadTask uploadTask = storageRef.putFile(imageFile);
    
    // Wait for the upload to complete
    TaskSnapshot snapshot = await uploadTask;
    
    // Get the download URL for the uploaded image
    String downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  }

  /// Gets all available book listings in real-time
  /// Filters for books where swapStatus is 'Available'
  /// Orders by creation date (newest first)
  Stream<List<BookListing>> getAvailableBooks() {
    return _firestore
        .collection('books')
        .where('swapStatus', isEqualTo: 'Available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }

  /// Gets user's book listings in real-time
  /// Filters for books where ownerId matches the provided user ID
  /// Orders by creation date (newest first)
  Stream<List<BookListing>> getUserBooks(String userId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }

  /// Updates an existing book listing
  /// Can update title, author, condition, swapFor, and image
  Future<bool> updateBookListing({
    required String bookId,
    String? title,
    String? author,
    String? condition,
    String? swapFor,
    File? imageFile,
  }) async {
    try {
      // Create a map of updates to apply
      Map<String, dynamic> updates = {};
      
      // Add non-null values to the updates map
      if (title != null) updates['title'] = title;
      if (author != null) updates['author'] = author;
      if (condition != null) updates['condition'] = condition;
      if (swapFor != null) updates['swapFor'] = swapFor;
      
      // Handle image upload if a new image is provided
      if (imageFile != null) {
        try {
          // Create a new filename for the updated image
          String fileName = 'book_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          // Get a reference to the new storage location
          Reference storageRef = _storage.ref().child(fileName);
          
          // Upload the new image
          UploadTask uploadTask = storageRef.putFile(imageFile);
          TaskSnapshot snapshot = await uploadTask;
          
          // Get the URL for the new image
          String imageUrl = await snapshot.ref.getDownloadURL();
          
          // Add the new image URL to the updates
          updates['imageUrl'] = imageUrl;
        } catch (e) {
          // Print error and return false if image upload fails
          print('Error uploading new image: $e');
          return false;
        }
      }

      // Apply the updates to the book document
      await _firestore.collection('books').doc(bookId).update(updates);
      return true;
    } catch (e) {
      // Print error and return false if the update fails
      print('Error updating book listing: $e');
      return false;
    }
  }

  /// Deletes a book listing from Firestore
  Future<bool> deleteBookListing(String bookId) async {
    try {
      // Delete the book document
      await _firestore.collection('books').doc(bookId).delete();
      return true;
    } catch (e) {
      // Print error and return false if deletion fails
      print('Error deleting book listing: $e');
      return false;
    }
  }

  /// Requests a swap for a book
  /// Updates the book's status to 'Pending' and records the requester
  /// Also creates a chat room between the two users involved in the swap
  Future<bool> requestSwap({
    required String bookId,
    required String requesterId,
    required String requesterName,
    required String ownerId, // Pass the owner ID to create the chat room
  }) async {
    try {
      // Update the book document with swap request details
      await _firestore.collection('books').doc(bookId).update({
        'swapStatus': 'Pending',
        'requestedBy': requesterId,
        'requestedByName': requesterName,
      });

      // Create a chat room between the requester and the owner
      // This ensures a communication channel exists for the swap
      await _chatService.getOrCreateChatRoomId(requesterId, ownerId);

      return true;
    } catch (e) {
      // Print error and return false if the request fails
      print('Error requesting swap: $e');
      return false;
    }
  }

  /// Accepts a swap request
  /// Updates the book's status to 'Completed'
  Future<bool> acceptSwap(String bookId) async {
    try {
      // Update the book document to mark the swap as completed
      await _firestore.collection('books').doc(bookId).update({
        'swapStatus': 'Completed',
      });
      return true;
    } catch (e) {
      // Print error and return false if the acceptance fails
      print('Error accepting swap: $e');
      return false;
    }
  }

  /// Cancels a swap request
  /// Updates the book's status back to 'Available' and clears requester info
  Future<bool> cancelSwap(String bookId) async {
    try {
      // Update the book document to cancel the swap request
      await _firestore.collection('books').doc(bookId).update({
        'swapStatus': 'Available',
        'requestedBy': null,
        'requestedByName': null,
      });
      return true;
    } catch (e) {
      // Print error and return false if the cancellation fails
      print('Error canceling swap: $e');
      return false;
    }
  }

  /// Gets user's swap requests (books they requested) in real-time
  /// Filters for books where requestedBy matches the provided user ID
  /// Orders by creation date (newest first)
  Stream<List<BookListing>> getUserSwapRequests(String userId) {
    print('DEBUG: getUserSwapRequests stream called for user: $userId'); // Debug log
    return _firestore
        .collection('books')
        .where('requestedBy', isEqualTo: userId) // Filter for books requested by the user
        .orderBy('createdAt', descending: true) // Order by creation date (newest first)
        .snapshots()
        .map((snapshot) {
      print('DEBUG: getUserSwapRequests snapshot received with ${snapshot.docs.length} docs'); // Debug log
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList(); // Use BookListing model
    });
  }
  Stream<List<BookListing>> getPendingSwapRequestsForOwner(String ownerId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: ownerId)
        .where('swapStatus', isEqualTo: 'Pending') // Filter specifically for pending requests for the owner
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }

   /// NEW: Gets books owned by the user that have been swapped (status = 'Completed')
  /// Filters for books where ownerId matches the user ID AND swapStatus is 'Completed'
  /// Useful for the owner to see completed swaps (history)
  Stream<List<BookListing>> getCompletedSwapsForOwner(String ownerId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: ownerId)
        .where('swapStatus', isEqualTo: 'Completed') // Filter specifically for completed swaps for the owner
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }
  
  /// Gets books owned by the user that have pending swap requests
  /// Filters for books where ownerId matches the user ID AND swapStatus is 'Pending'
  Stream<List<BookListing>> getPendingSwapRequests(String ownerId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: ownerId)
        .where('swapStatus', isEqualTo: 'Pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }

  /// NEW METHOD: Gets books owned by the user that have been swapped (status = 'Completed')
  /// Filters for books where ownerId matches the user ID AND swapStatus is 'Completed'
  /// Useful for the owner to see completed swaps (history)
  Stream<List<BookListing>> getCompletedSwaps(String ownerId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: ownerId)
        .where('swapStatus', isEqualTo: 'Completed') // Filter for completed swaps
        .orderBy('createdAt', descending: true) // Order by creation date (newest first)
        .snapshots() // Use snapshots() for real-time updates
        .map((snapshot) {
      // Map each document in the snapshot to a BookListing object
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }
}
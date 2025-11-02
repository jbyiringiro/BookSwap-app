// lib/services/book_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/book_model.dart';

/// Service class for handling all book-related operations with Firebase
/// Includes creating, reading, updating, deleting books and managing swaps
class BookService {
  // Instance of Firestore for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Instance of Firebase Storage for image uploads
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
        print('DEBUG: Starting image upload for file: ${imageFile.path}'); // Debug log
        try {
          imageUrl = await _uploadImageWithTimeout(imageFile, ownerId);
          print('DEBUG: Image upload successful, URL: $imageUrl'); // Debug log
        } catch (e) {
          print('ERROR: Failed to upload image: $e'); // Error log
          // Decide: Fail the whole operation or proceed without image
          // For now, let's proceed without the image to avoid losing the listing
          imageUrl = null; 
        }
      } else {
         print('DEBUG: No image file provided for upload'); // Debug log
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

      print('DEBUG: Book created successfully with ID: ${docRef.id}, Image URL: $imageUrl');
      return true;
    } catch (e) {
      // Print error to console for debugging
      print('ERROR: Error creating book listing: $e');
      return false;
    }
  }

  /// Uploads an image file to Firebase Storage with a timeout
  /// This prevents the app from hanging if the upload takes too long
  Future<String> _uploadImageWithTimeout(File imageFile, String ownerId) async {
    print('DEBUG: Entering _uploadImageWithTimeout'); // Debug log
    try {
        String result = await _uploadImage(imageFile, ownerId).timeout(
          const Duration(seconds: 30), // 30-second timeout
          onTimeout: () {
            // Throw a timeout exception if upload takes too long
            print('ERROR: Image upload timed out after 30 seconds'); // Error log
            throw TimeoutException('Image upload took too long', const Duration(seconds: 30));
          },
        );
        print('DEBUG: _uploadImageWithTimeout completed successfully'); // Debug log
        return result;
    } catch (e) {
        print('ERROR: _uploadImageWithTimeout failed: $e'); // Error log
        rethrow; // Rethrow the error so the calling function can handle it
    }
  }

  /// Actual image upload function
  /// Uploads the image to Firebase Storage and returns the download URL
  Future<String> _uploadImage(File imageFile, String ownerId) async {
    print('DEBUG: Entering _uploadImage'); // Debug log
    try {
      // Validate the file exists
      if (!await imageFile.exists()) {
        print('ERROR: Image file does not exist at path: ${imageFile.path}'); // Error log
        throw Exception('Image file does not exist');
      }

      // Get file size
      int fileSize = await imageFile.length();
      print('DEBUG: Image file size: ${fileSize ~/ 1024} KB'); // Debug log

      // Create a unique filename using owner ID and timestamp
      String fileName = 'book_images/${ownerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('DEBUG: Generated filename: $fileName'); // Debug log
      
      // Get a reference to the storage location
      Reference storageRef = _storage.ref().child(fileName);
      
      // Start the upload process
      print('DEBUG: Starting upload to: $fileName'); // Debug log
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;
      print('DEBUG: Upload task completed'); // Debug log
      
      // Get the download URL for the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('DEBUG: Got download URL: $downloadUrl'); // Debug log
      
      return downloadUrl;
    } catch (e) {
      print('ERROR: _uploadImage failed: $e'); // Error log
      rethrow; // Rethrow the error so the calling function can handle it
    }
  }

  /// Gets all available book listings in real-time
  /// Filters for books where swapStatus is 'Available'
  /// Orders by creation date (newest first)
  Stream<List<BookListing>> getAvailableBooks() {
    print('DEBUG: getAvailableBooks stream called'); // Debug log
    return _firestore
        .collection('books')
        .where('swapStatus', isEqualTo: 'Available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('DEBUG: getAvailableBooks snapshot received with ${snapshot.docs.length} docs'); // Debug log
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }

  /// Gets user's book listings in real-time
  /// Filters for books where ownerId matches the provided user ID
  /// Orders by creation date (newest first)
  Stream<List<BookListing>> getUserBooks(String userId) {
    print('DEBUG: getUserBooks stream called for user: $userId'); // Debug log
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('DEBUG: getUserBooks snapshot received with ${snapshot.docs.length} docs'); // Debug log
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
        print('DEBUG: Updating image for book: $bookId'); // Debug log
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
          print('DEBUG: Updated image URL: $imageUrl'); // Debug log
        } catch (e) {
          // Print error and return false if image upload fails
          print('ERROR: Failed to upload new image for update: $e'); // Error log
          return false;
        }
      }

      // Apply the updates to the book document
      await _firestore.collection('books').doc(bookId).update(updates);
      return true;
    } catch (e) {
      // Print error and return false if the update fails
      print('ERROR: Failed to update book listing: $e'); // Error log
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
      print('ERROR: Failed to delete book listing: $e'); // Error log
      return false;
    }
  }

  /// Requests a swap for a book
  /// Updates the book's status to 'Pending' and records the requester
  Future<bool> requestSwap({
    required String bookId,
    required String requesterId,
    required String requesterName,
  }) async {
    try {
      // Update the book document with swap request details
      await _firestore.collection('books').doc(bookId).update({
        'swapStatus': 'Pending',
        'requestedBy': requesterId,
        'requestedByName': requesterName,
      });
      return true;
    } catch (e) {
      // Print error and return false if the request fails
      print('ERROR: Failed to request swap: $e'); // Error log
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
      print('ERROR: Failed to accept swap: $e'); // Error log
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
      print('ERROR: Failed to cancel swap: $e'); // Error log
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
        .where('requestedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('DEBUG: getUserSwapRequests snapshot received with ${snapshot.docs.length} docs'); // Debug log
      return snapshot.docs.map((doc) => BookListing.fromFirestore(doc)).toList();
    });
  }
}
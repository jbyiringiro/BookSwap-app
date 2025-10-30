import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../models/swap_offer.dart';

class BookProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Book> _allBooks = [];
  List<Book> _myBooks = [];
  List<SwapOffer> _myOffers = [];
  bool _isLoading = false;

  List<Book> get allBooks => _allBooks;
  List<Book> get myBooks => _myBooks;
  List<SwapOffer> get myOffers => _myOffers;
  bool get isLoading => _isLoading;

  void listenToBooks() {
    _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _allBooks = snapshot.docs
              .map((doc) => Book.fromFirestore(doc))
              .toList();
          notifyListeners();
        });
  }

  void listenToMyBooks(String userId) {
    _firestore
        .collection('books')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _myBooks = snapshot.docs
              .map((doc) => Book.fromFirestore(doc))
              .toList();
          notifyListeners();
        });
  }

  void listenToMyOffers(String userId) {
    _firestore
        .collection('swapOffers')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _myOffers = snapshot.docs
              .map((doc) => SwapOffer.fromFirestore(doc))
              .toList();
          notifyListeners();
        });
  }

  Future<String?> addBook(Book book) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('books').add(book.toMap());

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> updateBook(
    String bookId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('books').doc(bookId).update(updates);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createSwapOffer(SwapOffer offer) async {
    try {
      await _firestore.collection('swapOffers').add(offer.toMap());
      await updateBook(offer.bookId, {'status': 'pending'});
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap_offer.dart';

class SwapOfferProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SwapOffer> _offers = [];
  bool _isLoading = false;
  String? _error;

  List<SwapOffer> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SwapOfferProvider() {
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('swapOffers')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            _offers = snapshot.docs
                .map((doc) => SwapOffer.fromFirestore(doc))
                .toList();
            _isLoading = false;
            notifyListeners();
          });
    } catch (e) {
      _error = 'Failed to load swap offers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SwapOffer> getUserOffers(String userId) {
    return _offers
        .where(
          (offer) => offer.fromUserId == userId || offer.toUserId == userId,
        )
        .toList();
  }

  List<SwapOffer> getPendingOffers(String userId) {
    return _offers
        .where(
          (offer) =>
              offer.toUserId == userId && offer.status == SwapStatus.pending,
        )
        .toList();
  }

  Future<String> addOffer(SwapOffer offer) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('swapOffers')
          .doc(offer.id)
          .set(offer.toFirestore());

      // Update the book listing to mark it as unavailable
      await _firestore.collection('listings').doc(offer.bookListingId).update({
        'isAvailable': false,
        'updatedAt': Timestamp.now(),
      });

      _error = null;
      return offer.id;
    } catch (e) {
      _error = 'Failed to add swap offer: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOfferStatus(String offerId, SwapStatus newStatus) async {
    try {
      await _firestore.collection('swapOffers').doc(offerId).update({
        'status': newStatus.index,
        'updatedAt': Timestamp.now(),
      });

      // If rejected, make the book available again
      if (newStatus == SwapStatus.rejected) {
        final offer = _offers.firstWhere((o) => o.id == offerId);
        await _firestore.collection('listings').doc(offer.bookListingId).update(
          {'isAvailable': true, 'updatedAt': Timestamp.now()},
        );
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to update offer status: $e';
      rethrow;
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('swapOffers').doc(offerId).delete();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete offer: $e';
      rethrow;
    }
  }
}

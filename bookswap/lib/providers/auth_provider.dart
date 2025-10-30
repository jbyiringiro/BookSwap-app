import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Check if user is already signed in
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadUserData(currentUser.uid);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _user = User.fromFirestore(userDoc.data()!, userDoc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!EmailValidator.validate(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email format',
        );
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _loadUserData(userCredential.user!.uid);
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      _user = null;
    } catch (e) {
      _error = 'Failed to sign in: $e';
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!EmailValidator.validate(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email format',
        );
      }

      if (name.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-name',
          message: 'Name cannot be empty',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user document in Firestore
      final newUser = User(
        id: userCredential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        createdAt: DateTime.now(),
        emailVerified: false,
      );

      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toFirestore());

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      _user = newUser;
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      _user = null;
    } catch (e) {
      _error = 'Failed to sign up: $e';
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e);
    } catch (e) {
      _error = 'Failed to reset password: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'email-already-in-use':
        return 'Email is already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

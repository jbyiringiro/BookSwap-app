// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the AuthResult class
import '../models/auth_result.dart';

/// Provider class to manage the authentication state of the user.
/// This class handles user sign-in, sign-up, sign-out, email verification checks,
/// and listens to authentication state changes to update the UI accordingly.
class AuthProvider with ChangeNotifier {
  // Instance of the authentication service to perform Firebase operations
  final AuthService _authService = AuthService();

  // Stores the current user's data once they are logged in
  BookSwapUser? _currentUser;

  // Tracks if any authentication operation is currently in progress
  bool _isLoading = false;

  /// Getter for the current user
  BookSwapUser? get currentUser => _currentUser;

  /// Getter for the loading state
  bool get isLoading => _isLoading;

  /// Checks if the user is currently authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Constructor: Initializes the provider and starts listening to auth state changes
  AuthProvider() {
    // Listen to changes in the user's authentication state (signed in/signed out)
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Callback triggered when the user's authentication state changes
  /// If the user is signed in, fetch their data from Firestore
  /// If the user is signed out, clear the current user data
  void _onAuthStateChanged(user) async {
    if (user != null) {
      // User is signed in, check if email is verified and fetch user data from Firestore
      if (user.emailVerified) {
        await _fetchUserData(user.uid);
      } else {
        // Email not verified, clear user data and notify listeners
        _currentUser = null;
        notifyListeners();
      }
    } else {
      // User is signed out, clear user data and notify listeners
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Fetches the user's data from Firestore based on their UID
  /// and updates the provider's current user state
  Future<void> _fetchUserData(String uid) async {
    try {
      // Get the user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Check if the document exists
      if (userDoc.exists) {
        // Cast the document data to a Map
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Create a BookSwapUser object from the Firestore data
        _currentUser = BookSwapUser.fromFirebaseUser(userData, uid);
        // Notify listeners that the user data has changed
        notifyListeners();
      }
    } catch (e) {
      // Print error to console for debugging
      print('Error fetching user  $e');
    }
  }

  /// Signs up a new user with email, password, and display name
  /// Returns an AuthResult object with success status and message
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Set loading state to true and notify listeners to show loading UI
    _setLoading(true);

    // Call the sign-up method in the auth service (this now returns AuthResult)
    AuthResult result = await _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    // Set loading state back to false
    _setLoading(false);
    return result; // Return the AuthResult object
  }

  /// Signs in an existing user with email and password
  /// Returns an AuthResult object with success status and message
  /// Returns true if successful and email is verified, false otherwise
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    // Set loading state to true and notify listeners to show loading UI
    _setLoading(true);

    // Call the sign-in method in the auth service (this now returns AuthResult)
    AuthResult result = await _authService.signIn(
      email: email,
      password: password,
    );

    // If sign-in was successful, fetch user data
    if (result.success) {
      await _fetchUserData(_authService.getCurrentUser()!.uid);
    }

    // Set loading state back to false
    _setLoading(false);
    return result; // Return the AuthResult object
  }

  /// Signs out the current user, clearing all user data and state
  Future<void> signOut() async {
    // Call the sign-out method in the auth service
    await _authService.signOut();

    // Clear the current user data
    _currentUser = null;

    // Notify listeners that the authentication state has changed
    notifyListeners();
  }

  /// Sends an email verification link to the current user's email address
  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  /// Checks if the current user's email address has been verified
  bool isEmailVerified() {
    return _authService.isEmailVerified();
  }

  /// Updates the email verification status in Firestore
  /// This should be called periodically or when the app starts
  Future<void> updateEmailVerificationStatus() async {
    await _authService.updateEmailVerificationStatus();
  }

  /// Private method to update the loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
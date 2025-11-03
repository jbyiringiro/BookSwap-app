// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// Import the AuthResult class
import '../models/auth_result.dart'; // Ensure the path is correct relative to this file

/// Service class responsible for handling all Firebase Authentication operations.
/// This includes sign-up, sign-in, sign-out, email verification, and managing user state.
class AuthService {
  // Instance of Firebase Auth for performing authentication operations
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instance of Firestore for storing and retrieving user data
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Getter to retrieve the currently signed-in user
  User? getCurrentUser() => _auth.currentUser;

  /// Stream that emits the current user's authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs up a new user with email and password
  /// Creates a user account in Firebase Auth and a corresponding document in Firestore
  /// Also sends an email verification link to the user
  /// Returns an AuthResult object containing success status and message
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create the user account in Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user's display name in Firebase Auth
      await credential.user?.updateDisplayName(displayName);

      // Send an email verification link to the user
      // This is crucial for the email verification requirement
      await credential.user?.sendEmailVerification();

      // Create a corresponding user document in Firestore
      // This creates the user profile data as required
      await _firestore.collection('users').doc(credential.user?.uid).set({
        'email': email,
        'displayName': displayName,
        'photoUrl': credential.user?.photoURL,
        'createdAt': Timestamp.now(),
        'isEmailVerified': false, // Initially false, will be updated when user verifies email
      });

      return AuthResult(success: true, message: 'Sign up successful! Please verify your email.');
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          return AuthResult(
            success: false,
            message: 'This email is already registered. Please try logging in instead.',
            errorCode: 'email-already-in-use'
          );
        case 'weak-password':
          return AuthResult(
            success: false,
            message: 'Password is too weak. Please use at least 6 characters.',
            errorCode: 'weak-password'
          );
        case 'invalid-email':
          return AuthResult(
            success: false,
            message: 'Email address is invalid.',
            errorCode: 'invalid-email'
          );
        default:
          return AuthResult(
            success: false,
            message: 'Sign up failed: ${e.message}',
            errorCode: e.code
          );
      }
    } catch (e) {
      // Print error to console for debugging
      debugPrint('Sign up error: $e');
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred during sign up.',
        errorCode: 'unknown'
      );
    }
  }

  /// Signs in an existing user with email and password
  /// Checks if the user's email is verified before allowing sign-in
  /// This enforces the email verification requirement
  /// Returns an AuthResult object containing success status and message
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to sign in the user
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user's email is verified
      // If not verified, sign them out and return false
      if (!credential.user!.emailVerified) {
        // Sign the user out immediately if email is not verified
        await _auth.signOut();
        return AuthResult(
          success: false,
          message: 'Email not verified. Please verify your email before signing in.',
          errorCode: 'email-not-verified'
        );
      }

      return AuthResult(
        success: true,
        message: 'Sign in successful!'
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          return AuthResult(
            success: false,
            message: 'No user found with this email. Please sign up first.',
            errorCode: 'user-not-found'
          );
        case 'wrong-password':
          return AuthResult(
            success: false,
            message: 'Incorrect password. Please try again.',
            errorCode: 'wrong-password'
          );
        case 'user-disabled':
          return AuthResult(
            success: false,
            message: 'This account has been disabled.',
            errorCode: 'user-disabled'
          );
        case 'too-many-requests':
          return AuthResult(
            success: false,
            message: 'Too many failed attempts. Please try again later.',
            errorCode: 'too-many-requests'
          );
        default:
          return AuthResult(
            success: false,
            message: 'Sign in failed: ${e.message}',
            errorCode: e.code
          );
      }
    } catch (e) {
      // Print error to console for debugging
      debugPrint('Sign in error: $e');
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred during sign in.',
        errorCode: 'unknown'
      );
    }
  }

  /// Signs out the currently authenticated user
  Future<void> signOut() async {
    try {
      // Perform the sign-out operation in Firebase Auth
      await _auth.signOut();
    } catch (e) {
      // Print error to console for debugging
      debugPrint('Sign out error: $e');
    }
  }

  /// Sends an email verification link to the currently signed-in user
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Checks if the currently signed-in user's email address has been verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Updates the email verification status in the Firestore user document
  /// This should be called when the user verifies their email externally
  Future<void> updateEmailVerificationStatus() async {
    final user = _auth.currentUser;
    if (user != null && user.emailVerified) {
      // Update the Firestore document to reflect the email verification status
      await _firestore.collection('users').doc(user.uid).update({
        'isEmailVerified': true,
      });
    }
  }
}
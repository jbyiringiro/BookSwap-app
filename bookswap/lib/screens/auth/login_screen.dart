// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_result.dart'; // Ensure the path is correct relative to this file
import 'forgot_password_screen.dart'; // Ensure this import exists

/// Screen for user login
/// Validates email and password, enforces email verification
/// Handles various login errors gracefully
/// Includes a link to the Forgot Password screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key to validate the form
  final _formKey = GlobalKey<FormState>();

  // Controllers for email and password input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Loading state to prevent multiple submissions
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12122F),
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: const Color(0xFF12122F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Email input field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF1E1E3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.blue, width: 2), // Changed to blue
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password input field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF1E1E3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.blue, width: 2), // Changed to blue
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8), // Reduced space before "Forgot Password?"
              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to the forgot password screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.blue), // Keep link blue
                  ),
                ),
              ),
              const SizedBox(height: 16), // Space before the login button
              // Consumer widget to access AuthProvider
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: _isLoading || authProvider.isLoading
                        ? null // Disable button while loading
                        : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Changed from yellow (e.g., Color(0xFFE6B84D)) to blue
                      foregroundColor: Colors.white, // Ensure text is white
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // Changed indicator color to contrast with blue
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 18),
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Link to sign up screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.blue), // Keep link blue
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the login process
  /// Validates form, calls AuthProvider.signIn, handles success/failure including email verification
  Future<void> _handleLogin() async {
    // Validate the form before proceeding
    if (_formKey.currentState!.validate()) {
      // Set loading state to true
      setState(() {
        _isLoading = true;
      });

      // Get the AuthProvider instance
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Attempt to sign in - NOW EXPECTS AuthResult
      AuthResult result = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.success) {
        // Navigate to home screen if login is successful
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error message based on the result
        // This handles email verification, wrong password, etc.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message), // Use the message from AuthResult
            backgroundColor: Colors.red,
          ),
        );
      }

      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
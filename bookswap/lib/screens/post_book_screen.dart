// lib/screens/post_book_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
// Add imports for kIsWeb
import 'package:flutter/foundation.dart'; // Contains kIsWeb
import '../services/book_service.dart';
import '../providers/auth_provider.dart';

class PostBookScreen extends StatefulWidget {
  const PostBookScreen({super.key});

  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _swapForController = TextEditingController();
  String _selectedCondition = 'Good';
  File? _selectedImage;
  Uint8List? _selectedImageBytes; //for web support
  bool _isLoading = false;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Used'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Read the image bytes
        final imageBytes = await pickedFile.readAsBytes();
        
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = imageBytes;
        });
      } catch (e) {
        debugPrint('Error reading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _postBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookService = BookService();

      // Check if email is verified before attempting to post
      if (!authProvider.isEmailVerified()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email address before posting a book.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return; // Exit the function if email is not verified
      }

      bool success = await bookService.createBookListing(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        condition: _selectedCondition,
        ownerId: authProvider.currentUser!.uid,
        ownerName: authProvider.currentUser?.displayName ?? '',
        swapFor: _swapForController.text.trim(),
        imageFile: _selectedImage,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post book. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add a check here as well, maybe redirect or show a message if not verified
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isEmailVerified()) {
        // Option 1: Redirect back or show a message
        WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Please verify your email address first.'),
                backgroundColor: Colors.orange,
            ),
            );
            // Navigator.pop(context); // Go back if not verified
        });
        // Option 2: Show a locked UI
        return Scaffold(
        appBar: AppBar(title: Text('Post a Book')),
        body: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                'Email Verification Required',
                style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                TextButton(
                onPressed: () {
                    authProvider.sendEmailVerification();
                    // Optionally navigate to settings
                    // Navigator.pushNamed(context, '/profile');
                },
                child: Text('Resend Verification Email'),
                ),
            ],
            ),
        ),
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage != null
                          ? Colors.blue
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('DEBUG: Image error: $error');
                              return const Icon(
                                Icons.book,
                                size: 30,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add book photo',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Book Title
              const Text('Book Title', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter book title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter book title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author
              const Text('Author', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter author name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter author name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Swap For
              const Text('Swap For', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _swapForController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'What you want in exchange',
                ),
              ),
              const SizedBox(height: 16),

              // Condition
              const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _conditions.map((condition) {
                  return ChoiceChip(
                    label: Text(condition),
                    selected: _selectedCondition == condition,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCondition = selected ? condition : 'Good';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Post Button
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Changed from yellow (Color(0xFFE6B84D)) to blue
                    foregroundColor: Colors.black, // Keep text black for contrast
                    padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black) // Keep spinner color for contrast
                      : const Text('Post'),
                ),
              ),
            ],
          ),
        ),
      ),
      // Note: Removed BottomNavBar from PostBookScreen if it was intended as a modal/popup
      // bottomNavigationBar: BottomNavBar(selectedIndex: 1),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    super.dispose();
  }
}

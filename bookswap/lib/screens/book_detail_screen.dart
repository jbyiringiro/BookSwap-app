// lib/screens/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../providers/auth_provider.dart';
import '../services/book_service.dart';
import '../services/chat_service.dart';
import '../widgets/bottom_nav_bar.dart';

/// Screen displaying detailed information about a specific book listing.
class BookDetailScreen extends StatefulWidget {
  final BookListing book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isLoading = false; // Add the loading state variable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if this is the first route in the stack
            if (ModalRoute.of(context)?.isFirst ?? true) {
              // If it's the first route, navigate to home screen
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              // Otherwise, pop to the previous screen
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final currentUser = authProvider.currentUser;
          final isOwner = currentUser?.uid == widget.book.ownerId; // Use widget.book to access the passed book

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover Image
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[800],
                  ),
                  child: widget.book.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.book.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('DEBUG: Image load error for ${widget.book.imageUrl}: $error');
                              return const Icon(
                                Icons.book,
                                size: 80,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.book,
                          size: 80,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(height: 16),
                // Book Title
                Text(
                  widget.book.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Book Author
                Text(
                  'by ${widget.book.author}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Book Condition
                Row(
                  children: [
                    const Text('Condition:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(widget.book.condition, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                // Owner Information
                Row(
                  children: [
                    const Text('Owner:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(widget.book.ownerName, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                // Swap For (if specified)
                if (widget.book.swapFor != null)
                  Row(
                    children: [
                      const Text('Swap For:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.book.swapFor!,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Swap Status
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.book.swapStatus == 'Available'
                            ? Colors.green.withValues(alpha: 0.2)
                            : widget.book.swapStatus == 'Pending'
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.book.swapStatus,
                        style: TextStyle(
                          color: widget.book.swapStatus == 'Available'
                              ? Colors.green
                              : widget.book.swapStatus == 'Pending'
                                  ? Colors.orange
                                  : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show who requested if pending
                if (widget.book.swapStatus == 'Pending' && widget.book.requestedByName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Requested by: ${widget.book.requestedByName}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                // Action Buttons (Request Swap, Accept Swap, etc.)
                if (isOwner && widget.book.swapStatus == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _acceptSwap, // Use the instance method
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Green for accept
                          foregroundColor: Colors.white,
                          minimumSize: const Size(100, 40),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Accept'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _declineSwap, // Use the instance method
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Red for decline
                          foregroundColor: Colors.white,
                          minimumSize: const Size(100, 40),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Decline'),
                      ),
                    ],
                  )
                else if (!isOwner && widget.book.swapStatus == 'Available')
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestSwap, // Use the instance method
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Blue for request swap
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 40),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Request Swap'),
                    ),
                  )
                else if (!isOwner && widget.book.swapStatus == 'Pending' && widget.book.requestedBy == currentUser?.uid)
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cancelSwap, // Use the instance method
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // Orange for cancel
                        foregroundColor: Colors.black,
                        minimumSize: const Size(150, 40),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('Cancel Request'),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E3C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.book.swapStatus == 'Pending' && !isOwner
                            ? 'Swap request pending'
                            : widget.book.swapStatus == 'Completed'
                                ? 'Swap completed'
                                : 'Not available for swap',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 0), // Assuming 0 is Browse
    );
  }

  /// Handles requesting a swap for the book
  Future<void> _requestSwap() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookService = BookService();

    if (authProvider.currentUser != null) {
      bool success = await bookService.requestSwap(
        bookId: widget.book.id, // The ID of the book being requested
        requesterId: authProvider.currentUser!.uid, // The ID of the user requesting
        requesterName: authProvider.currentUser?.displayName ?? '', // The name of the user requesting
        ownerId: widget.book.ownerId, // Pass the owner ID of the book being requested
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swap request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally navigate back or update UI state
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send swap request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles accepting a swap request for the book (owner action)
  Future<void> _acceptSwap() async {
    final bookService = BookService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    bool success = await bookService.acceptSwap(widget.book.id);

    if (success) {
      // Create or get chat room with user names
      String currentUserName = authProvider.currentUser?.displayName ?? 'User';
      await ChatService().getOrCreateChatRoomId(
        authProvider.currentUser!.uid,
        widget.book.requestedBy ?? '',
        user1Name: currentUserName,
        user2Name: widget.book.requestedByName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept swap. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Handles declining/cancelling a swap request for the book (owner action)
  Future<void> _declineSwap() async {
    final bookService = BookService();

    setState(() {
      _isLoading = true;
    });

    bool success = await bookService.cancelSwap(widget.book.id);

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap request declined successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate back after success
      Navigator.pop(context);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decline swap request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Handles cancelling a swap request the user made
  Future<void> _cancelSwap() async {
    final bookService = BookService();

    setState(() {
      _isLoading = true;
    });

    bool success = await bookService.cancelSwap(widget.book.id);

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap request cancelled successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate back after success
      Navigator.pop(context);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel swap request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}

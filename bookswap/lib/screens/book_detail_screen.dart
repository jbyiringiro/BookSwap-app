import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';
import '../providers/auth_provider.dart';

class BookDetailScreen extends StatelessWidget {
  final BookListing book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12122F),
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: const Color(0xFF12122F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Image
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                ),
                child: book.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          book.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
                book.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Author
              Text(
                'by ${book.author}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // Book Info
              Row(
                children: [
                  _buildInfoCard('Condition', book.condition),
                  const SizedBox(width: 16),
                  _buildInfoCard('Status', book.swapStatus),
                ],
              ),
              const SizedBox(height: 16),
              
              // Swap For
              if (book.swapFor != null)
                _buildDetailCard('Looking For', book.swapFor!),
              
              // Owner Info
              _buildDetailCard('Owner', book.ownerName),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUser = authProvider.currentUser;
                  final isOwner = currentUser?.uid == book.ownerId;
                  
                  if (isOwner) {
                    return Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showOwnerOptions(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Manage Listing',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (book.swapStatus == 'Pending')
                          ElevatedButton(
                            onPressed: () => _acceptSwap(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Accept Swap Request',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                      ],
                    );
                  } else if (book.swapStatus == 'Available') {
                    return ElevatedButton(
                      onPressed: () => _requestSwap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Request Swap',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  } else if (book.swapStatus == 'Pending' && 
                             book.requestedBy == currentUser?.uid) {
                    return ElevatedButton(
                      onPressed: () => _cancelSwap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel Swap Request',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  } else {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E3C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          book.swapStatus == 'Pending' 
                              ? 'Swap request pending' 
                              : 'Book not available',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E3C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestSwap(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookService = BookService();
    
    bool success = await bookService.requestSwap(
      bookId: book.id,
      requesterId: authProvider.currentUser!.uid,
      requesterName: authProvider.currentUser!.displayName,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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

  Future<void> _cancelSwap(BuildContext context) async {
    final bookService = BookService();
    
    bool success = await bookService.cancelSwap(book.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap request cancelled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel swap request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptSwap(BuildContext context) async {
    final bookService = BookService();
    
    bool success = await bookService.acceptSwap(book.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept swap. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOwnerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Listing', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Handle edit
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Listing', style: TextStyle(color: Colors.white)),
              onTap: () {
                _deleteListing(context);
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteListing(BuildContext context) async {
    final bookService = BookService();
    
    bool success = await bookService.deleteBookListing(book.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context); // Go back to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete listing. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
// lib/screens/my_listings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/book_service.dart';
import '../models/book_model.dart';
import '../widgets/book_card.dart'; // Assuming you have this widget
import '../widgets/bottom_nav_bar.dart';

/// Screen displaying the user's book listings and their swap requests ("My Offers").
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with TickerProviderStateMixin { // Required for TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 2 tabs: "My Listings" and "My Offers"
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Add a TabBar below the app bar title
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Listings'), // Tab for books the user owns
            Tab(text: 'My Offers'),    // Tab for books the user requested
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final currentUser = authProvider.currentUser;

          if (currentUser == null) {
            return const Center(
              child: Text(
                'Please sign in to view your listings and offers.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Use TabBarView to switch between the two content sections
          return TabBarView(
            controller: _tabController,
            children: [
              // --- TAB 1: My Listings (Books Owned by the User) ---
              _buildMyListingsTab(currentUser.uid),

              // --- TAB 2: My Offers (Books the User Requested) ---
              _buildMyOffersTab(currentUser.uid), // Combined Pending & Completed
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/post_book');
        },
        backgroundColor: const Color(0xFF4285F4), // Changed from yellow to blue
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
    );
  }

  /// Builds the content for the "My Listings" tab
  /// Shows all books where the current user is the owner
  Widget _buildMyListingsTab(String userId) {
    return StreamBuilder<List<BookListing>>(
      stream: BookService().getUserBooks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading listings: ${snapshot.error}'));
        }

        List<BookListing> books = snapshot.data ?? [];

        if (books.isEmpty) {
          return const Center(
            child: Text(
              'No listings yet.\n\nPost your first book!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                color: const Color(0xFF1E1E3C),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/book_detail',
                      arguments: book,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Book Image
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: book.imageUrl != null
                                ? Image.network(
                                    book.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.book,
                                        size: 30,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.book,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Book Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${book.author}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: book.swapStatus == 'Available'
                                          ? Colors.green.withOpacity(0.2)
                                          : book.swapStatus == 'Pending'
                                              ? Colors.orange.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      book.swapStatus,
                                      style: TextStyle(
                                        color: book.swapStatus == 'Available'
                                            ? Colors.green
                                            : book.swapStatus == 'Pending'
                                                ? Colors.orange
                                                : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${book.condition}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Edit and Delete Buttons
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.pushNamed(
                                context,
                                '/edit_book',
                                arguments: book,
                              );
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, book.id);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Shows delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Book'),
          content: const Text('Are you sure you want to delete this book listing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteBook(bookId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a book listing
  void _deleteBook(String bookId) async {
    final bookService = BookService();
    bool success = await bookService.deleteBookListing(bookId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete book. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Builds the content for the "My Offers" tab
  /// Shows books where the current user is the requester (regardless of status)
  /// Combines Pending and Completed swap requests
  Widget _buildMyOffersTab(String userId) {
    return StreamBuilder<List<BookListing>>(
      stream: BookService().getUserSwapRequests(userId), // Fetch books requested by the user
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading offers: ${snapshot.error}'));
        }

        List<BookListing> requestedBooks = snapshot.data ?? [];

        if (requestedBooks.isEmpty) {
          return const Center(
            child: Text(
              'No swap offers sent yet.\n\nBrowse listings to request a swap!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh handled automatically by StreamBuilder
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requestedBooks.length,
            itemBuilder: (context, index) {
              final book = requestedBooks[index];
              // Use the imported BookCard widget here, highlighting it as a requested book
              // The BookCard will show the correct swap status (Pending, Completed, etc.)
              return Card(
                color: const Color(0xFF1E1E3C),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to book detail screen for the requested book
                    Navigator.pushNamed(
                      context,
                      '/book_detail',
                      arguments: book,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Book Image using CachedNetworkImage (from BookCard)
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800], // Placeholder color while loading
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: book.imageUrl != null
                                ? Image.network(
                                    book.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.book,
                                        size: 30,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.book,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Book Info (similar to BookCard)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${book.ownerName}', // Show the *owner*'s name for requested books
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: book.swapStatus == 'Pending'
                                          ? Colors.orange.withOpacity(0.2)
                                          : book.swapStatus == 'Completed'
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.2), // For other statuses like 'Available' if somehow it appears here
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      book.swapStatus == 'Pending'
                                          ? 'Offer Sent' // Custom text for requested pending
                                          : book.swapStatus == 'Completed'
                                              ? 'Swap Accepted!' // Custom text for requested completed
                                              : book.swapStatus, // Show original status for others
                                      style: TextStyle(
                                        color: book.swapStatus == 'Pending'
                                            ? Colors.orange
                                            : book.swapStatus == 'Completed'
                                                ? Colors.green
                                                : Colors.grey, // For other statuses
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${book.condition}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              // Optionally, show what the user offered for this specific book
                              if (book.swapFor != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Offered for: ${book.swapFor}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
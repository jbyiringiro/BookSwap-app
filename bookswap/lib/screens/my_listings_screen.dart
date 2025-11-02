// lib/screens/my_listings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/book_service.dart';
import '../models/book_model.dart';
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
              _buildMyOffersTab(currentUser.uid),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/post_book');
        },
        backgroundColor: const Color(0xFF4285F4), // Sky blue color
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
    );
  }

  /// Builds the content for the "My Listings" tab
  /// Shows books where the current user is the owner
  Widget _buildMyListingsTab(String userId) {
    return StreamBuilder<List<BookListing>>(
      stream: BookService().getUserBooks(userId), // Fetch books owned by the user
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
          onRefresh: () async {
            // Refresh handled automatically by StreamBuilder
          },
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
                    // Navigate to book detail screen
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
                          child: book.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    book.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.book,
                                        size: 30,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.book,
                                  size: 30,
                                  color: Colors.grey,
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
                                book.author,
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
                              if (book.swapStatus == 'Pending' && book.requestedByName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Requested by: ${book.requestedByName}',
                                    style: const TextStyle(
                                      color: Colors.orange,
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

  /// Builds the content for the "My Offers" tab
  /// Shows books where the current user is the requester
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

        List<BookListing> offeredBooks = snapshot.data ?? [];

        if (offeredBooks.isEmpty) {
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
            itemCount: offeredBooks.length,
            itemBuilder: (context, index) {
              final book = offeredBooks[index];
              // Highlight that this is a book *the user requested*
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
                        // Book Image
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                          ),
                          child: book.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    book.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.book,
                                        size: 30,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.book,
                                  size: 30,
                                  color: Colors.grey,
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
                                book.author,
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
                                          ? Colors.grey.withOpacity(0.2)
                                          : book.swapStatus == 'Pending'
                                              ? Colors.orange.withOpacity(0.2)
                                              : Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      book.swapStatus,
                                      style: TextStyle(
                                        color: book.swapStatus == 'Available'
                                            ? Colors.grey
                                            : book.swapStatus == 'Pending'
                                                ? Colors.orange
                                                : Colors.green,
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
                              // Show status of the user's request for this specific book
                              // Use Provider.of here to access the authProvider within this builder
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  bool isRequestedByCurrentUser = book.requestedBy == authProvider.currentUser?.uid;
                                  if (isRequestedByCurrentUser) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Status: ${book.swapStatus == 'Pending' ? 'Offer Sent' : 'Offer ${book.swapStatus}'}',
                                        style: TextStyle(
                                          color: book.swapStatus == 'Pending'
                                              ? Colors.orange
                                              : book.swapStatus == 'Completed'
                                                  ? Colors.green
                                                  : Colors.grey,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink(); // Return empty widget if not requested by current user
                                },
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
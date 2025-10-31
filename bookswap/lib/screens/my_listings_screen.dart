// lib/screens/my_listings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/bottom_nav_bar.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(
              child: Text(
                'Please sign in to view your listings',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return StreamBuilder<List<BookListing>>(
            stream: BookService().getUserBooks(authProvider.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<BookListing> books = snapshot.data ?? [];

              if (books.isEmpty) {
                return const Center(
                  child: Text(
                    'No listings yet\n\nAdd your first book!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Refresh will happen automatically with StreamBuilder
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
                          Navigator.pushNamed(context, '/book_detail', arguments: book);
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/post_book');
        },
        backgroundColor: Colors.blue, // Changed from yellow (Color(0xFFE6B84D)) to blue
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 1),
    );
  }
}
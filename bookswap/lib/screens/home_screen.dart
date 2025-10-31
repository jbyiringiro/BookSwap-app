// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BookSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return StreamBuilder<List<BookListing>>(
            stream: BookService().getAvailableBooks(),
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
                    'No books available yet',
                    style: TextStyle(color: Colors.white),
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
                    return BookCard(
                      title: book.title,
                      author: book.author,
                      condition: book.condition,
                      timeAgo: _getTimeAgo(book.createdAt),
                      imageUrl: book.imageUrl ?? 'https://via.placeholder.com/100x150/4a2c2c/ffffff?text=BOOK',
                      onTap: () {
                        Navigator.pushNamed(context, '/book_detail', arguments: book);
                      },
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
      bottomNavigationBar: BottomNavBar(selectedIndex: 0),
    );
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class BookSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF12122F),
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // We'll handle results in the home screen
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<List<BookListing>>(
      stream: BookService().getAvailableBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<BookListing> books = snapshot.data ?? [];

        if (query.isNotEmpty) {
          books = books.where((book) {
            return book.title.toLowerCase().contains(query.toLowerCase()) ||
                   book.author.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              leading: book.imageUrl != null
                  ? Image.network(
                      book.imageUrl!,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.book),
                        );
                      },
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book),
                    ),
              title: Text(book.title),
              subtitle: Text(book.author),
              onTap: () {
                close(context, book.id);
                Navigator.pushNamed(context, '/book_detail', arguments: book);
              },
            );
          },
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_listing_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book_listing.dart';
import '../widgets/book_listing_widget.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  void _showPostBookDialog(BuildContext context) {
    final bookProvider = Provider.of<BookListingProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String title = '';
    String author = '';
    String swapFor = '';
    String condition = 'Like New';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post a Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Book Title'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Author'),
                onChanged: (value) => author = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Swap For'),
                onChanged: (value) => swapFor = value,
              ),
              const SizedBox(height: 16),
              const Text('Condition:'),
              Wrap(
                spacing: 8,
                children: ['New', 'Like New', 'Good', 'Used'].map((cond) {
                  return FilterChip(
                    label: Text(cond),
                    selected: condition == cond,
                    onSelected: (selected) {
                      condition = cond;
                      Navigator.of(context).pop();
                      _showPostBookDialog(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty && author.isNotEmpty && swapFor.isNotEmpty) {
                final newListing = BookListing(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: authProvider.user!.id,
                  title: title,
                  author: author,
                  condition: condition,
                  swapFor: swapFor,
                  createdAt: DateTime.now(),
                );
                bookProvider.addListing(newListing);
                Navigator.pop(context);
              }
            },
            child: const Text('POST'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userListings = bookProvider.getUserListings(authProvider.user!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: userListings.isEmpty
          ? const Center(
              child: Text(
                'No listings yet.\nTap + to add your first book!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: userListings.length,
              itemBuilder: (context, index) {
                final listing = userListings[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${listing.author}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(listing.condition),
                              backgroundColor: _getConditionColor(
                                listing.condition,
                              ),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Swap for: ${listing.swapFor}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Edit functionality
                              },
                              child: const Text('EDIT'),
                            ),
                            TextButton(
                              onPressed: () {
                                bookProvider.deleteListing(listing.id);
                              },
                              child: const Text(
                                'DELETE',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostBookDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'used':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

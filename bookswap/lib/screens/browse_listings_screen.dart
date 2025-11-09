import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../models/swap_offer.dart';

class BrowseListingsScreen extends StatelessWidget {
  const BrowseListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final books = bookProvider.allBooks
        .where((book) => book.ownerId != authProvider.user!.uid)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Listings')),
      body: books.isEmpty
          ? const Center(
              child: Text(
                'No books available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: book.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    book.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
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
                                      color: book.condition == 'New'
                                          ? Colors.green.shade100
                                          : book.condition == 'Like New'
                                          ? Colors.blue.shade100
                                          : book.condition == 'Good'
                                          ? Colors.orange.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      book.condition,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: book.condition == 'New'
                                            ? Colors.green.shade800
                                            : book.condition == 'Like New'
                                            ? Colors.blue.shade800
                                            : book.condition == 'Good'
                                            ? Colors.orange.shade800
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM d').format(book.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (book.status == 'available')
                                SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final userName = await authProvider
                                          .getUserName(authProvider.user!.uid);
                                      final offer = SwapOffer(
                                        id: '',
                                        bookId: book.id,
                                        bookTitle: book.title,
                                        senderId: authProvider.user!.uid,
                                        senderName: userName,
                                        receiverId: book.ownerId,
                                        receiverName: book.ownerName,
                                        status: 'pending',
                                        createdAt: DateTime.now(),
                                      );
                                      await bookProvider.createSwapOffer(offer);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Swap request sent!'),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE9B44C),
                                    ),
                                    child: const Text(
                                      'Request Swap',
                                      style: TextStyle(
                                        color: Color(0xFF1E2749),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    book.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

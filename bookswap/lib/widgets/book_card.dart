// lib/widgets/book_card.dart

import 'package:flutter/material.dart';
// Import CachedNetworkImage
import 'package:cached_network_image/cached_network_image.dart';

/// Reusable widget to display a book listing card
/// Shows book image, title, author, condition, and swap status
class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String condition;
  final String swapStatus; // 'Available', 'Pending', 'Completed'
  final String? imageUrl; // Make imageUrl nullable
  final String? requestedByName; // Name of user who requested the swap (if pending)
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapStatus, // Accept the swapStatus
    this.imageUrl, // Accept nullable imageUrl
    this.requestedByName, // Accept the requester name
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E3C),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book Image using CachedNetworkImage for better handling
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800], // Placeholder color while loading
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    // Use the imageUrl, or a placeholder if null
                    imageUrl: imageUrl ?? '',
                    fit: BoxFit.cover,
                    // Placeholder widget while the image is loading
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.book,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    // Error widget if the image fails to load
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.book,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    // Optional: Add fade-in animation
                    fadeInDuration: const Duration(milliseconds: 300),
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
                      title,
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
                      author,
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
                            color: swapStatus == 'Available'
                                ? Colors.green.withValues(alpha: 0.2)
                                : swapStatus == 'Pending'
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2), // Could be grey for 'Completed'
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            swapStatus,
                            style: TextStyle(
                              color: swapStatus == 'Available'
                                  ? Colors.green
                                  : swapStatus == 'Pending'
                                      ? Colors.orange
                                      : Colors.red, // Could be grey for 'Completed'
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $condition',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Show requester name only if status is 'Pending' and name exists
                    if (swapStatus == 'Pending' && requestedByName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Requested by: $requestedByName',
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
  }
}
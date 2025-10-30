import 'package:flutter/material.dart';
import '../models/swap_offer.dart';

class SwapOfferWidget extends StatelessWidget {
  final SwapOffer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const SwapOfferWidget({
    super.key,
    required this.offer,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swap Offer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_getStatusText(offer.status)}',
              style: TextStyle(
                color: _getStatusColor(offer.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(offer.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (offer.status == SwapStatus.pending &&
                onAccept != null &&
                onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('ACCEPT'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return 'Pending';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.rejected:
        return 'Rejected';
      case SwapStatus.completed:
        return 'Completed';
    }
  }

  Color _getStatusColor(SwapStatus status) {
    switch (status) {
      case SwapStatus.pending:
        return Colors.orange;
      case SwapStatus.accepted:
        return Colors.green;
      case SwapStatus.rejected:
        return Colors.red;
      case SwapStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import '../models/card_details.dart';

class CardDetailsDisplay extends StatelessWidget {
  final CardDetails cardDetails;

  const CardDetailsDisplay({Key? key, required this.cardDetails})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasName = cardDetails.cardHolderName?.isNotEmpty == true;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Card Number',
              value: cardDetails.getMaskedCardNumber(),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Expiry Date',
              value: cardDetails.expiryDate.isNotEmpty
                  ? cardDetails.expiryDate
                  : 'Not found',
            ),
            // Only show the cardholder name row when a name was actually found
            if (hasName) ...[
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Card Holder',
                value: cardDetails.cardHolderName!,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardDetails.isValid ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cardDetails.isValid ? '✓ Valid Card' : '✗ Invalid Card',
                style: TextStyle(
                  color: cardDetails.isValid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  // Removed [isOptional] — the caller now simply omits the row via [if (hasName)]
  // above, so this widget no longer needs to know about optionality.

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

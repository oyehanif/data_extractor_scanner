import 'package:flutter/material.dart';
import '../models/bank_details.dart';

class BankDetailsDisplay extends StatelessWidget {
  final BankDetails bankDetails;

  const BankDetailsDisplay({
    Key? key,
    required this.bankDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Account Holder',
              value: bankDetails.accountHolderName.isNotEmpty
                  ? bankDetails.accountHolderName
                  : 'Not found',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Account Number',
              value: bankDetails.accountNumber.isNotEmpty
                  ? bankDetails.accountNumber
                  : 'Not found',
            ),
            if (bankDetails.ifscCode != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                label: 'IFSC Code',
                value: bankDetails.ifscCode ?? 'Not found',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

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
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

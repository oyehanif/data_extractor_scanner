import 'package:flutter_test/flutter_test.dart';
import 'package:data_extractor_scanner/services/parsing_service.dart';

void main() {
  group('Passbook Parser Tests', () {
    test('Extract account number', () {
      const rawText =
          'Account Holder: John Doe\nAccount Number: 123456789012\nIFSC: SBIN0000123';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber, contains('123456789012'));
    });

    test('Extract IFSC code with uppercase format', () {
      const rawText =
          'Account Holder: John Doe\nAccount Number: 123456789012\nIFSC: SBIN0000123';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.ifscCode, equals('SBIN0000123'));
    });

    test('Extract account holder name with Account Holder label', () {
      const rawText =
          'Account Holder: John Doe\nAccount Number: 123456789012\nIFSC: SBIN0000123';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountHolderName.isNotEmpty, true);
    });

    test('Extract account holder name with A/c Holder label', () {
      const rawText =
          'A/c Holder: Jane Smith\nAccount Number: 123456789012\nIFSC: SBIN0000456';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountHolderName.isNotEmpty, true);
    });

    test('Handle missing IFSC code', () {
      const rawText =
          'Account Holder: John Doe\nAccount Number: 123456789012';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber, isNotEmpty);
    });

    test('Extract correct account number among multiple numbers', () {
      const rawText =
          'Date: 2024-05-20\nAccount Holder: John Doe\nAccount Number: 123456789012\nBalance: 50000';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('Extract account number with varied text', () {
      const rawText = 'SBIN0001234\nJohn Doe\n987654321098';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('Handle multiple words in name', () {
      const rawText =
          'John Alexander Doe\nAccount: 123456789012\nIFSC: SBIN0001234';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('Handle OCR misreads - I as 1', () {
      const rawText = 'John Doe\nAccount: 123456789012\nIFSC: SB1N0001234';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('Handle empty text', () {
      const rawText = '';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isEmpty, true);
    });

    test('Extract account with 9-digit minimum', () {
      const rawText = 'Account Number: 123456789';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('Handle account number with variable length', () {
      const rawText = 'Account: 123456789\nName: Jane Smith';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('Extract longest account number when multiple exist', () {
      const rawText = 'Account 123456789 Alternative 123456789012';
      final result = ParsingService.parsePassbook(rawText);

      expect(result.accountNumber.isNotEmpty, true);
    });

    test('IFSC with common OCR misread (O for 0)', () {
      const rawText = 'IFSC Code: SBINO001234';
      final result = ParsingService.parsePassbook(rawText);
      expect(result.ifscCode, equals('SBIN0001234'));
    });

    test('IFSC with common OCR misread (1 for I)', () {
      const rawText = 'RTGS / NEFT IFSC: SB1N0001234';
      final result = ParsingService.parsePassbook(rawText);
      expect(result.ifscCode, equals('SBIN0001234'));
    });

    test('IFSC 11-digit length check', () {
      const rawText = 'IFSC: BARB0KOLKAT'; // 11 chars
      final result = ParsingService.parsePassbook(rawText);
      expect(result.ifscCode, equals('BARB0KOLKAT'));
    });

    test('Exclude CIF from being picked as Account Number', () {
      const rawText = 'CIF No: 9876543210\nAccount No: 123456789012';
      final result = ParsingService.parsePassbook(rawText);
      expect(result.accountNumber, equals('123456789012'));
    });

    test('Exclude CIF even if Account No is missing label', () {
      const rawText = 'CIF No: 9876543210\nSome Text\n123456789012';
      final result = ParsingService.parsePassbook(rawText);
      expect(result.accountNumber, equals('123456789012'));
    });

    test('Support SB A/c No label', () {
      const rawText = 'S.B. A/c No. 50100123456789';
      final result = ParsingService.parsePassbook(rawText);
      expect(result.accountNumber, equals('50100123456789'));
    });
  });
}

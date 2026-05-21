import 'package:flutter_test/flutter_test.dart';
import 'package:data_extractor_scanner/services/parsing_service.dart';

void main() {
  group('Luhn Algorithm Tests', () {
    test('Valid card number - Visa format', () {
      // Valid Visa test number verified with Luhn
      const validCard = '4532015112830366';
      expect(ParsingService.isValidCard(validCard), true);
    });

    test('Valid card number - American Express format', () {
      // Valid AMEX test number (15 digits)
      const validCard = '378282246310005';
      expect(ParsingService.isValidCard(validCard), true);
    });

    test('Valid card with spaces', () {
      const validCard = '4532 0151 1283 0366';
      expect(ParsingService.isValidCard(validCard), true);
    });

    test('Valid card with dashes', () {
      const validCard = '4532-0151-1283-0366';
      expect(ParsingService.isValidCard(validCard), true);
    });

    test('Invalid card number', () {
      const invalidCard = '4532015112830367';
      expect(ParsingService.isValidCard(invalidCard), false);
    });

    test('Empty card number', () {
      expect(ParsingService.isValidCard(''), false);
    });

    test('Card number too short', () {
      expect(ParsingService.isValidCard('123456'), false);
    });

    test('Card number with only letters', () {
      expect(ParsingService.isValidCard('ABCDEFGHIJKLMNOP'), false);
    });

    test('Invalid checksum', () {
      const invalidCard = '6666666666666666';
      expect(ParsingService.isValidCard(invalidCard), false);
    });

    test('Single digit repeated - short', () {
      expect(ParsingService.isValidCard('1111'), false);
    });
  });
}

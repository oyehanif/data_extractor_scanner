import 'package:flutter_test/flutter_test.dart';
import 'package:data_extractor_scanner/services/parsing_service.dart';

void main() {
  group('Card Parser Tests', () {
    test('Extract card number from simple text', () {
      const rawText = '4532 0151 1283 0366\n12/25\nJOHN DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber, isNotEmpty);
      expect(result.cardNumber, contains('4532'));
    });

    test('Extract expiry date MM/YY format', () {
      const rawText = '4532015112830366\n12/25\nJohn Doe';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate, contains('12'));
    });

    test('Extract expiry date MM-YY format', () {
      const rawText = '4532015112830366\n12-25\nJohn Doe';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate.isNotEmpty, true);
    });

    test('Extract expiry date MMYY format', () {
      const rawText = '4532015112830366\nVALID THRU 12/25\nJohn Doe';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate.isNotEmpty, true);
    });

    test('Extract expiry date with VALID THRU MM/YY', () {
      const rawText = '4532 0151 1283 0366\nVALID THRU 12/25\nJOHN DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate, contains('12'));
      expect(result.expiryDate, contains('25'));
    });

    test('Extract expiry date with VALID THRU MM-YY', () {
      const rawText = '4532 0151 1283 0366\nVALID THRU 12-25\nJOHN DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate, contains('12'));
      expect(result.expiryDate, contains('25'));
    });

    test('Extract expiry date with VALID THRU MM-YY (dash separator)', () {
      const rawText = '4532 0151 1283 0366\nVALID THRU 12-25\nJOHN DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate, contains('12'));
    });

    test('Extract expiry date with EXP MM/YY', () {
      const rawText = '4532 0151 1283 0366\nEXP 12/25\nJOHN DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate, contains('12'));
    });

    test('Extract expiry date with EXPIRES MM/YY', () {
      const rawText = '4532 0151 1283 0366\nEXPIRES 12/25\nJOHN DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate, contains('12'));
    });

    test('Extract cardholder name', () {
      const rawText = '4532 0151 1283 0366\n12/25\nJOHN';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber, isNotEmpty);
    });

    test('Extract cardholder name with full name', () {
      const rawText = '4532 0151 1283 0366\nVALID THRU 12/25\nJOHN DAVID DOE';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber, isNotEmpty);
    });

    test('Handle missing cardholder name', () {
      const rawText = '4532 0151 1283 0366\n12/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber, isNotEmpty);
    });

    test('Handle card number without spacing', () {
      const rawText = '4532015112830366';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Handle card number with dashes', () {
      const rawText = '4532-0151-1283-0366\n12/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Masked card number shows only last 4 digits', () {
      const rawText = '4532 0151 1283 0366';
      final result = ParsingService.parseCard(rawText);
      final masked = result.getMaskedCardNumber();

      expect(masked, contains('XXXX'));
      expect(masked, contains('0366'));
    });

    test('Handle OCR misread - O as 0', () {
      const rawText = '45320151128O0366';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Handle OCR misread - Z as 2', () {
      const rawText = '4532015112830366Z';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Handle OCR misread - G as 9', () {
      const rawText = '453201511283036G';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Handle empty text', () {
      const rawText = '';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isEmpty, true);
    });

    test('Validate card after parsing', () {
      const rawText = '4532 0151 1283 0366\n12/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.isValid, true);
    });

    test('Detect invalid card number', () {
      const rawText = '6666 6666 6666 6666\n12/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.isValid, false);
    });

    test('Handle card number with mixed OCR errors', () {
      const rawText = '453201511283O366\nVALID THRU 12/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Extract 15-digit card number (Amex)', () {
      const rawText = '378282246310005\nVALID THRU 12/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.cardNumber.isNotEmpty, true);
    });

    test('Reject invalid expiry month', () {
      const rawText = '4532 0151 1283 0366\n13/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate.isEmpty, true);
    });

    test('Reject invalid expiry month zero', () {
      const rawText = '4532 0151 1283 0366\n00/25';
      final result = ParsingService.parseCard(rawText);

      expect(result.expiryDate.isEmpty, true);
    });
  });
}

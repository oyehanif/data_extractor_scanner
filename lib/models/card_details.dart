class CardDetails {
  final String cardNumber;
  final String expiryDate;
  final String? cardHolderName;
  final bool isValid;

  CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    this.cardHolderName,
    required this.isValid,
  });

  String getMaskedCardNumber() {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 4) return cardNumber;
    final lastFour = cleaned.substring(cleaned.length - 4);
    return 'XXXX XXXX XXXX $lastFour';
  }

  @override
  String toString() {
    return 'CardDetails(cardNumber: $cardNumber, expiryDate: $expiryDate, cardHolderName: $cardHolderName, isValid: $isValid)';
  }
}

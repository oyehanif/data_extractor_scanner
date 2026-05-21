class BankDetails {
  final String accountHolderName;
  final String accountNumber;
  final String? ifscCode;

  BankDetails({
    required this.accountHolderName,
    required this.accountNumber,
    this.ifscCode,
  });

  @override
  String toString() {
    return 'BankDetails(accountHolderName: $accountHolderName, accountNumber: $accountNumber, ifscCode: $ifscCode)';
  }
}

import '../models/card_details.dart';
import '../models/bank_details.dart';

class ParsingService {
  // ---------------------------------------------------------------------------
  // Bank name blocklist — these are institution/branch names that appear in
  // ALL CAPS on passbooks and must never be mistaken for the account holder.
  // ---------------------------------------------------------------------------
  static const _bankNameBlocklist = {
    'STATE BANK OF INDIA', 'BANK OF INDIA', 'BANK OF BARODA',
    'CENTRAL BANK OF INDIA', 'PUNJAB NATIONAL BANK', 'CANARA BANK',
    'UNION BANK OF INDIA', 'INDIAN BANK', 'UCO BANK', 'INDIAN OVERSEAS BANK',
    'HDFC BANK', 'ICICI BANK', 'AXIS BANK', 'KOTAK MAHINDRA BANK',
    'YES BANK', 'IDBI BANK', 'FEDERAL BANK', 'SOUTH INDIAN BANK',
    'KARNATAKA BANK', 'VIJAYA BANK', 'SYNDICATE BANK', 'ALLAHABAD BANK',
    'DENA BANK', 'CORPORATION BANK', 'ANDHRA BANK', 'ORIENTAL BANK',
    'RESERVE BANK OF INDIA', 'SBI', 'BOI', 'PNB', 'HDFC', 'ICICI',
  };

  // Words that appear in ALL CAPS on documents but are never a person's name.
  static const _genericBlockWords = {
    // Card labels
    'VALID', 'THRU', 'EXPIRES', 'EXPIRY', 'MEMBER', 'SINCE',
    'VISA', 'MASTERCARD', 'RUPAY', 'MAESTRO', 'AMEX',
    'DEBIT', 'CREDIT', 'CARD',
    // Bank / passbook labels
    'BANK', 'SAVINGS', 'ACCOUNT', 'CURRENT', 'BRANCH', 'PASSBOOK',
    'IFSC', 'MICR', 'NOMINEE', 'NOMINATION', 'OPERATING',
    'OFFICER', 'MANAGER', 'CENTRE', 'CENTER',
    // Address-related words common in branch addresses
    'ROAD', 'STREET', 'NAGAR', 'MILLS', 'CHOWKEY', 'CHOWKY',
    'CHAMBERS', 'COLONY', 'MARKET', 'COMPLEX', 'PLAZA', 'TOWER',
    'MAIDAN', 'MARG', 'CIRCLE', 'CROSS',
    // Honorifics — keep these so MRS/MR prefix does not confuse the blocker
    // (we handle them separately below)
  };

  // Honorific prefixes — if a name starts with one of these it is very likely
  // a real person's name.
  static const _honorifics = {'MR', 'MRS', 'MS', 'DR', 'SHRI', 'SMT', 'KU'};

  // ---------------------------------------------------------------------------
  // Card parsing
  // ---------------------------------------------------------------------------

  static bool isValidCard(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty || cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }
    int sum = 0;
    bool isEvenPosition = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      if (isEvenPosition) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      isEvenPosition = !isEvenPosition;
    }
    return sum % 10 == 0;
  }

  static CardDetails parseCard(String rawText) {
    final cleanedForNumbers = _cleanOCRTextNumeric(rawText);
    final cleanedForText = _normalizeWhitespace(rawText);

    final cardNumber = _extractCardNumber(cleanedForNumbers);
    final expiryDate = _extractExpiryDate(cleanedForNumbers);
    final cardHolderName = _extractCardHolderName(cleanedForText);
    final isValid = cardNumber.isNotEmpty && isValidCard(cardNumber);

    return CardDetails(
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
      isValid: isValid,
    );
  }

  static String _extractCardNumber(String text) {
    var match =
    RegExp(r'\b(\d{4})\s+(\d{4})\s+(\d{4})\s+(\d{4})\b').firstMatch(text);
    if (match != null) {
      return '${match.group(1)}${match.group(2)}${match.group(3)}${match.group(4)}';
    }
    match = RegExp(r'\b(\d{4})-(\d{4})-(\d{4})-(\d{4})\b').firstMatch(text);
    if (match != null) {
      return '${match.group(1)}${match.group(2)}${match.group(3)}${match.group(4)}';
    }
    match = RegExp(r'\b(\d{16})\b').firstMatch(text);
    if (match != null) return match.group(1) ?? '';

    match = RegExp(r'\b(\d{13,19})\b').firstMatch(text);
    if (match != null) {
      final cardNum = match.group(1) ?? '';
      if (!cardNum.startsWith('19') && !cardNum.startsWith('20')) {
        return cardNum;
      }
    }
    return '';
  }

  static String _extractExpiryDate(String text) {
    var match = RegExp(r'VALID\s+THRU\s+(\d{2})[/\s\-]?(\d{2})',
        caseSensitive: false)
        .firstMatch(text);
    if (match != null) {
      final month = match.group(1) ?? '';
      final year = match.group(2) ?? '';
      if (_isValidMonthYear(month, year)) return '$month/$year';
    }

    match = RegExp(r'(?:EXP|EXPIRES?)\s+(\d{2})[/\s\-]?(\d{2})',
        caseSensitive: false)
        .firstMatch(text);
    if (match != null) {
      final month = match.group(1) ?? '';
      final year = match.group(2) ?? '';
      if (_isValidMonthYear(month, year)) return '$month/$year';
    }

    for (final line in text.split('\n')) {
      if (line.contains(RegExp(r'\d{4}\s\d{4}'))) continue;
      match = RegExp(r'(\d{2})[/\-](\d{2})').firstMatch(line);
      if (match != null) {
        final month = match.group(1) ?? '';
        final year = match.group(2) ?? '';
        if (_isValidMonthYear(month, year)) return '$month/$year';
      }
    }
    return '';
  }

  static bool _isValidMonthYear(String month, String year) {
    final monthInt = int.tryParse(month) ?? 0;
    if (monthInt < 1 || monthInt > 12) return false;
    if (year.length != 2) return false;
    return true;
  }

  static String? _extractCardHolderName(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final digitCount = RegExp(r'\d').allMatches(trimmed).length;
      if (digitCount > trimmed.length * 0.3) continue;

      final allCapsMatch =
      RegExp(r'\b([A-Z]{2,}(?:\s+[A-Z]{2,})+)\b').firstMatch(trimmed);
      if (allCapsMatch != null) {
        final candidate = allCapsMatch.group(0) ?? '';
        if (_isValidPersonName(candidate)) return candidate.trim();
      }

      final titleMatch =
      RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b').firstMatch(trimmed);
      if (titleMatch != null) {
        final candidate = titleMatch.group(0) ?? '';
        if (candidate.length > 3 && !candidate.contains(RegExp(r'\d'))) {
          return candidate.trim();
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Passbook parsing
  // ---------------------------------------------------------------------------

  static BankDetails parsePassbook(String rawText) {
    final cleanedForNumbers = _cleanOCRTextNumeric(rawText);
    final cleanedForText = _normalizeWhitespace(rawText);

    // ── IFSC ──────────────────────────────────────────────────────────────────
    // Strategy 1: look for IFSC label then grab the next word
    String? ifscCode = _extractIFSCNearLabel(cleanedForText);

    // Strategy 2: scan every word for the IFSC pattern
    if (ifscCode == null) {
      for (final word in cleanedForText.split(RegExp(r'\s+'))) {
        final candidate = _cleanIFSC(word);
        if (RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(candidate)) {
          ifscCode = candidate;
          break;
        }
      }
    }

    // ── Account holder name ───────────────────────────────────────────────────
    // Strategy 1: look for explicit labels like "Name of Account Holder",
    //             "Account Holder", "Name And Address Of Account Holder/s"
    String accountHolderName =
        _extractNameNearLabel(cleanedForText) ?? '';

    // Strategy 2: look for honorific-prefixed names (MRS. TABASSUM NAFI SHAIKH)
    if (accountHolderName.isEmpty) {
      accountHolderName = _extractNameWithHonorific(cleanedForText) ?? '';
    }

    // Strategy 3: scored line scan — pick the line most likely to be a name
    if (accountHolderName.isEmpty) {
      accountHolderName = _extractNameByScoredScan(cleanedForText) ?? '';
    }

    // ── Account number ────────────────────────────────────────────────────────
    // Strategy 1: look for "Account No" / "A/c No" label then grab nearby digits
    String accountNumber =
        _extractAccountNumberNearLabel(cleanedForText) ?? '';

    // Strategy 2: pick the longest digit sequence that is not a phone / date /
    //             toll-free number or labeled as CIF/Customer ID
    if (accountNumber.isEmpty) {
      final excludedNumbers = _extractExcludedNumbers(cleanedForText);
      for (final match
      in RegExp(r'\b(\d{9,18})\b').allMatches(cleanedForNumbers)) {
        final num = match.group(0) ?? '';
        if (excludedNumbers.contains(num)) continue;
        
        if (!_looksLikeDateOrPhone(num) && !_looksLikeTollFree(num)) {
          if (accountNumber.isEmpty || num.length > accountNumber.length) {
            accountNumber = num;
          }
        }
      }
    }

    return BankDetails(
      accountHolderName: accountHolderName.trim(),
      accountNumber: accountNumber,
      ifscCode: ifscCode,
    );
  }

  // ── IFSC helpers ────────────────────────────────────────────────────────────

  /// Looks for an IFSC label and returns the next word if it matches the pattern.
  static String? _extractIFSCNearLabel(String text) {
    // Match "IFSC Code: SBIN0001234" or "IFSC Code:SBIN0001234" or "RTGS/NEFT IFSC SBIN0001234"
    final match = RegExp(
      r'(?:IFSC|IFS\s*Code|RTGS\s*/\s*NEFT\s*IFSC|I\.?F\.?S\.?C\.?)\s*(?:Code)?\s*[:=.-]?\s*([A-Z0-9]{9,11})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final candidate = _cleanIFSC(match.group(1)!);
      if (RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  /// Cleans potential IFSC code from common OCR misreads.
  static String _cleanIFSC(String input) {
    var upper = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (upper.length < 11) return upper;

    // IFSC is 11 chars: 4 chars (bank) + '0' (fixed) + 6 chars (branch)
    String bankPart = upper.substring(0, 4);
    String zeroPart = upper.substring(4, 5);
    String branchPart = upper.substring(5);

    // Bank part: common digits as letters
    bankPart = bankPart
        .replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('5', 'S')
        .replaceAll('8', 'B');

    // Fifth character must be '0'
    if (zeroPart == 'O') zeroPart = '0';

    return bankPart + zeroPart + branchPart;
  }

  // ── Name helpers ─────────────────────────────────────────────────────────────

  /// Extracts the value after common "Account Holder" style labels.
  static String? _extractNameNearLabel(String text) {
    // Covers: "Name of Account Holder", "Account Holder", "Name And Address Of
    //          Account Holder/s", "Khatadharak ka naam / Name of Account Holder"
    final patterns = [
      RegExp(
        r'(?:Name\s+of\s+Account\s+Holder|Name\s+of\s+Holder|Account\s+Holder|Name\s+And\s+Address\s+Of\s+Account\s+Holder|Khatadharak\s+ka\s+naam|Khatadharak\s+ka\s+nam)\s*[:=]\s*([A-Za-z .]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'Name\s+of\s+Account\s+Holder\s+(?:[:=]\s*)?([A-Za-z .]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'Name\s+of\s+Holder\s+(?:[:=]\s*)?([A-Za-z .]+)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final raw = (match.group(1) ?? '')
            .split(RegExp(r'[\n\r]'))
            .first
            .replaceAll(RegExp(r'\d+'), '')
            .trim();
        
        // Ensure we don't pick up labels like "Account Number" as a name
        if (raw.length > 3 && 
            _isValidPersonName(raw.toUpperCase()) && 
            !raw.toLowerCase().contains('account') &&
            !raw.toLowerCase().contains('number')) {
          return raw.trim();
        }
      }
    }
    return null;
  }

  /// Finds a name that starts with an honorific (MR / MRS / DR etc.).
  /// Handles both "MRS. TABASSUM NAFI SHAIKH" and "Mrs Tabassum Nafi Shaikh".
  static String? _extractNameWithHonorific(String text) {
    final match = RegExp(
      r'\b((?:MR|MRS|MS|DR|SHRI|SMT|KU)\.?\s+[A-Z][A-Za-z]*(?:\s+[A-Z][A-Za-z]*){1,4})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  /// Scored scan: give each line a confidence score and return the best candidate.
  ///
  /// Scoring:
  ///  +3  line follows an "Account Holder" keyword within 3 lines
  ///  +2  ALL CAPS, 2–4 words, each 2–15 chars, no digits
  ///  +1  Title Case, 2–4 words
  ///  -5  matches bank name blocklist
  ///  -3  contains a generic block word
  ///  -2  contains digits
  ///  -2  line looks like an address (contains numbers + street words)
  static String? _extractNameByScoredScan(String text) {
    final lines = text.split('\n');
    String? best;
    int bestScore = 0;

    // Find lines that are near "Account Holder" labels
    final labelLineIndices = <int>{};
    for (int i = 0; i < lines.length; i++) {
      if (RegExp(r'Account\s*Holder|Name\s*of\s*Account|Khatadharak',
          caseSensitive: false)
          .hasMatch(lines[i])) {
        for (int j = i + 1; j <= i + 3 && j < lines.length; j++) {
          labelLineIndices.add(j);
        }
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.length < 3) continue;

      // Skip lines that are clearly not names
      if (RegExp(r'^\d').hasMatch(trimmed)) continue;
      if (RegExp(
          r'(?:IFSC|MICR|Branch|Balance|Savings|Account\s*No|Date|Tel|Toll|Mobile|Email)',
          caseSensitive: false)
          .hasMatch(trimmed)) continue;

      int score = 0;

      if (labelLineIndices.contains(i)) score += 3;

      final words = trimmed.split(RegExp(r'\s+'));
      final digitCount = RegExp(r'\d').allMatches(trimmed).length;

      if (digitCount > 0) score -= 2;
      if (digitCount > trimmed.length * 0.2) continue; // mostly digits → skip

      // ALL CAPS name pattern
      final isAllCaps =
      words.every((w) => w == w.toUpperCase() && RegExp(r'^[A-Z]+$').hasMatch(w));
      final isTitleCase = words.every(
              (w) => w.isNotEmpty && w[0] == w[0].toUpperCase());

      if (isAllCaps && words.length >= 2 && words.length <= 5) {
        score += 2;
        final joined = words.join(' ');
        if (_bankNameBlocklist.contains(joined)) {
          score -= 5;
        }
        if (words.any((w) => _genericBlockWords.contains(w))) {
          score -= 3;
        }
        if (words.any((w) => _honorifics.contains(w))) {
          score += 2; // honorific prefix boosts confidence
        }
      } else if (isTitleCase && words.length >= 2 && words.length <= 5) {
        score += 1;
      }

      if (score > bestScore) {
        // Extract just the name portion (skip label text before the colon)
        final colonIdx = trimmed.indexOf(':');
        final candidate =
        colonIdx >= 0 ? trimmed.substring(colonIdx + 1).trim() : trimmed;
        if (candidate.length > 3) {
          bestScore = score;
          best = candidate;
        }
      }
    }

    return best;
  }

  // ── Account number helpers ───────────────────────────────────────────────────

  /// Looks for "Account No" / "A/c No" / "Khata Sankhya" label then grabs
  /// the nearby digit sequence.
  static String? _extractAccountNumberNearLabel(String text) {
    final match = RegExp(
      r'(?:Account\s*No|A[/\\]c\s*No|Khata\s*Sankhya|Account\s*Number|Acc\s*No|SB\s*A[/\\]c\s*No|Saving\s*Account|Cust\s*A[/\\]c|S\.?B\.?\s*A[/\\]c)\s*[:=.]?\s*(\d[\d\s]{7,17})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final raw = (match.group(1) ?? '').replaceAll(RegExp(r'\s'), '');
      if (raw.length >= 9 && raw.length <= 18) return raw;
    }
    return null;
  }

  /// Identifies numbers that should be excluded from being picked as Account Number
  /// because they are labeled as something else (CIF, Customer ID, MICR, etc.).
  static Set<String> _extractExcludedNumbers(String text) {
    final excluded = <String>{};
    final patterns = [
      RegExp(r'(?:CIF|Customer\s*ID|Cust\s*ID|Customer\s*Info|MICR|Tel|Mobile|Phone|Date)\s*[:=.]?\s*(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final val = match.group(1);
        if (val != null) excluded.add(val.replaceAll(RegExp(r'\s'), ''));
      }
    }
    return excluded;
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  /// Returns true if the candidate string looks like a real person's name.
  /// Used as a final gate before accepting any name.
  static bool _isValidPersonName(String candidate) {
    if (candidate.length <= 3) return false;
    if (candidate.contains(RegExp(r'\d'))) return false;

    final upper = candidate.toUpperCase().trim();

    // Reject if it exactly matches or contains a known bank name
    for (final bank in _bankNameBlocklist) {
      if (upper.contains(bank)) return false;
    }
    
    // Explicitly reject common bank-related phrases
    if (upper.contains('STATE BANK') || 
        upper.contains('BANK OF') || 
        upper.contains('CENTRAL BANK') ||
        upper.contains('RESERVE BANK') ||
        upper.contains('ACCOUNT NUMBER') ||
        upper.contains('ACCOUNT NO')) {
      return false;
    }

    final words = upper.split(RegExp(r'\s+'));

    // If it starts with an honorific, it is almost certainly a person's name
    if (_honorifics.contains(words.first.replaceAll('.', ''))) return true;

    // Reject if ALL words are generic block words
    if (words.every((w) => _genericBlockWords.contains(w))) return false;

    // Reject if more than half the words are generic block words
    final blockCount = words.where((w) => _genericBlockWords.contains(w)).length;
    if (blockCount > words.length / 2) return false;

    return true;
  }

  static String _cleanOCRTextNumeric(String text) {
    return text
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(RegExp(r'[Il|]'), '1')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Bb]'), '8')
        .replaceAll(RegExp(r'[Zz]'), '2')
        .replaceAll(RegExp(r'[Gg]'), '9')
        .replaceAll(RegExp(r'[Qq]'), '0')
        .replaceAll(RegExp(r'[Tt]'), '1');
  }

  static String _normalizeWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  static bool _looksLikeDateOrPhone(String num) {
    if (num.startsWith('19') || num.startsWith('20')) return true;
    if (num.length == 10 && num.startsWith('9')) return true;
    return false;
  }

  /// Toll-free numbers in India start with 1800 and are 10–11 digits.
  static bool _looksLikeTollFree(String num) {
    return num.startsWith('1800') && num.length <= 11;
  }
}
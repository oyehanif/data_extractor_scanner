import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bank_details.dart';
import '../services/parsing_service.dart';
import '../services/ocr_service.dart';
import 'card_scanner_viewmodel.dart';

class PassbookScannerState {
  final File? scannedImage;
  final BankDetails? bankDetails;
  final bool isLoading;
  final String? errorMessage;

  PassbookScannerState({
    this.scannedImage,
    this.bankDetails,
    this.isLoading = false,
    this.errorMessage,
  });

  PassbookScannerState copyWith({
    File? scannedImage,
    BankDetails? bankDetails,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PassbookScannerState(
      scannedImage: scannedImage ?? this.scannedImage,
      bankDetails: bankDetails ?? this.bankDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PassbookScannerNotifier extends StateNotifier<PassbookScannerState> {
  final OCRService ocrService;
  static bool _hasAttemptedRecovery = false;

  PassbookScannerNotifier(this.ocrService) : super(PassbookScannerState()) {
    if (!_hasAttemptedRecovery) {
      _hasAttemptedRecovery = true;
      _handleLostData();
    }
  }

  Future<void> _handleLostData() async {
    try {
      debugPrint('PassbookVM: Checking for lost data on app start...');
      final xFile = await ocrService.getLostData();
      if (xFile != null) {
        debugPrint('PassbookVM: Found lost image, processing: ${xFile.path}');
        await _processImage(xFile);
      }
    } catch (e) {
      debugPrint('Passbook Recovery Error: $e');
    }
  }

  Future<void> scanFromCamera() async {
    try {
      debugPrint('PassbookVM: Starting scanFromCamera...');
      final xFile = await ocrService.pickImageFromCamera();
      if (xFile != null) {
        debugPrint('PassbookVM: Image picked, starting processing...');
        state = state.copyWith(isLoading: true, errorMessage: null);
        await _processImage(xFile);
      } else {
        debugPrint('PassbookVM: No image picked (cancelled or error).');
      }
    } catch (e) {
      debugPrint('PassbookVM: Catch in scanFromCamera: $e');
      state = state.copyWith(
        errorMessage: 'Failed to scan: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> scanFromGallery() async {
    try {
      debugPrint('PassbookVM: Starting scanFromGallery...');
      final xFile = await ocrService.pickImageFromGallery();
      if (xFile != null) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        await _processImage(xFile);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load image: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> _processImage(XFile xFile) async {
    try {
      final file = File(xFile.path);

      debugPrint('PassbookVM: Updating state with image and loading = true');
      // 1. Show image and loading spinner IMMEDIATELY
      state = state.copyWith(
        scannedImage: file,
        isLoading: true,
        errorMessage: null,
        bankDetails: null, // Clear previous details
      );

      // Small delay to ensure the UI has one frame to draw the image before OCR starts
      debugPrint('PassbookVM: Waiting for UI frame...');
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('PassbookVM: Calling OCR...');
      final extractedText = await ocrService.extractTextFromXFile(xFile);
      debugPrint('PassbookVM: OCR Complete. Extracted length: ${extractedText.length}');

      if (extractedText.isEmpty) {
        state = state.copyWith(
          errorMessage: 'No text found in image',
          isLoading: false,
        );
        return;
      }

      // Move parsing to a background isolate to keep UI thread smooth
      final bankDetails = await compute(ParsingService.parsePassbook, extractedText);

      state = state.copyWith(
        bankDetails: bankDetails,
        isLoading: false,
        errorMessage: bankDetails.accountNumber.isEmpty
            ? 'No bank data found. Please try again with a clearer image.'
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error processing image: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void reset() {
    state = PassbookScannerState();
  }
}

final passbookScannerProvider =
    StateNotifierProvider<PassbookScannerNotifier, PassbookScannerState>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return PassbookScannerNotifier(ocrService);
});

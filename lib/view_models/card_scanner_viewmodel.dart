import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/card_details.dart';
import '../services/parsing_service.dart';
import '../services/ocr_service.dart';

final ocrServiceProvider = Provider((ref) {
  final service = OCRService();
  ref.onDispose(() => service.dispose());
  return service;
});

class CardScannerState {
  final File? scannedImage;
  final CardDetails? cardDetails;
  final bool isLoading;
  final String? errorMessage;

  CardScannerState({
    this.scannedImage,
    this.cardDetails,
    this.isLoading = false,
    this.errorMessage,
  });

  CardScannerState copyWith({
    File? scannedImage,
    CardDetails? cardDetails,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CardScannerState(
      scannedImage: scannedImage ?? this.scannedImage,
      cardDetails: cardDetails ?? this.cardDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CardScannerNotifier extends StateNotifier<CardScannerState> {
  final OCRService ocrService;
  static bool _hasAttemptedRecovery = false;

  CardScannerNotifier(this.ocrService) : super(CardScannerState()) {
    if (!_hasAttemptedRecovery) {
      _hasAttemptedRecovery = true;
      _handleLostData();
    }
  }

  Future<void> _handleLostData() async {
    try {
      debugPrint('CardVM: Checking for lost data on app start...');
      final xFile = await ocrService.getLostData();
      if (xFile != null) {
        debugPrint('CardVM: Found lost image, processing: ${xFile.path}');
        await _processImage(xFile);
      }
    } catch (e) {
      debugPrint('Card Recovery Error: $e');
    }
  }

  Future<void> scanFromCamera() async {
    try {
      debugPrint('CardVM: Starting scanFromCamera...');
      final xFile = await ocrService.pickImageFromCamera();
      if (xFile != null) {
        debugPrint('CardVM: Image picked, starting processing...');
        state = state.copyWith(isLoading: true, errorMessage: null);
        await _processImage(xFile);
      } else {
        debugPrint('CardVM: No image picked (cancelled or error).');
      }
    } catch (e) {
      debugPrint('CardVM: Catch in scanFromCamera: $e');
      state = state.copyWith(
        errorMessage: 'Failed to scan: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> scanFromGallery() async {
    try {
      debugPrint('CardVM: Starting scanFromGallery...');
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

      debugPrint('CardVM: Updating state with image and loading = true');
      // 1. Show image and loading spinner IMMEDIATELY
      state = state.copyWith(
        scannedImage: file,
        isLoading: true,
        errorMessage: null,
        cardDetails: null, // Clear previous details
      );

      // Small delay to ensure the UI has one frame to draw the image before OCR starts
      debugPrint('CardVM: Waiting for UI frame...');
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('CardVM: Calling OCR...');
      final extractedText = await ocrService.extractTextFromXFile(xFile);
      debugPrint('CardVM: OCR Complete. Extracted length: ${extractedText.length}');

      if (extractedText.isEmpty) {
        state = state.copyWith(
          errorMessage: 'No text found in image',
          isLoading: false,
        );
        return;
      }

      // Move parsing to a background isolate to keep UI thread smooth
      final cardDetails = await compute(ParsingService.parseCard, extractedText);

      state = state.copyWith(
        cardDetails: cardDetails,
        isLoading: false,
        errorMessage: cardDetails.cardNumber.isEmpty
            ? 'No card data found. Please try again with a clearer image.'
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
    state = CardScannerState();
  }
}

final cardScannerProvider =
    StateNotifierProvider<CardScannerNotifier, CardScannerState>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return CardScannerNotifier(ocrService);
});

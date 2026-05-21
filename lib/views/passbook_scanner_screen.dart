import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/passbook_scanner_viewmodel.dart';
import '../widgets/bank_details_display.dart';

class PassbookScannerScreen extends ConsumerWidget {
  const PassbookScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passbookScannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Passbook Scanner'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ScanPreview(
              imageFile: state.scannedImage,
              isLoading: state.isLoading,
              errorMessage: state.errorMessage,
            ),
            _ScanButtons(
              isLoading: state.isLoading,
              onCameraPressed: () =>
                  ref.read(passbookScannerProvider.notifier).scanFromCamera(),
              onGalleryPressed: () =>
                  ref.read(passbookScannerProvider.notifier).scanFromGallery(),
              onResetPressed: () =>
                  ref.read(passbookScannerProvider.notifier).reset(),
            ),
            if (state.bankDetails != null)
              BankDetailsDisplay(bankDetails: state.bankDetails!),
          ],
        ),
      ),
    );
  }
}

class _ScanPreview extends StatelessWidget {
  final dynamic imageFile;
  final bool isLoading;
  final String? errorMessage;

  const _ScanPreview({
    required this.imageFile,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey[200], // Background color to prevent white screen
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageFile != null)
            Image.file(
              imageFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('PassbookPreview: Image load error: $error');
                return const Center(child: Text('Error loading image'));
              },
            ),
          // Ensure we always have something visible
          if (imageFile == null && !isLoading && errorMessage == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.description, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No image scanned', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          if (errorMessage != null && !isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          if (isLoading)
            Container(
              color: Colors.black45, // Slightly darker overlay
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onResetPressed;

  const _ScanButtons({
    required this.isLoading,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onResetPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: isLoading ? null : onCameraPressed,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan with Camera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onGalleryPressed,
            icon: const Icon(Icons.image),
            label: const Text('Pick from Gallery'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onResetPressed,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class OCRService {
  final ImagePicker _imagePicker = ImagePicker();
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Picks image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      debugPrint('OCRService: Starting camera pick...');

      if (Platform.isAndroid) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          debugPrint('OCRService: Camera permission denied');
          return null;
        }
      }

      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      debugPrint('OCRService: Camera pick result: ${file?.path}');
      return file;
    } catch (e) {
      debugPrint('OCRService: Error picking from camera: $e');
      return null;
    }
  }

  /// Picks image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      debugPrint('OCRService: Starting gallery pick...');

      if (Platform.isAndroid) {
        final storageStatus = await Permission.photos.request();
        if (!storageStatus.isGranted) {
          debugPrint('OCRService: Storage permission denied');
          return null;
        }
      }

      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      debugPrint('OCRService: Gallery pick result: ${file?.path}');
      return file;
    } catch (e) {
      debugPrint('OCRService: Error picking from gallery: $e');
      return null;
    }
  }

  /// Retrieves lost data after activity was killed
  Future<XFile?> getLostData() async {
    try {
      if (Platform.isAndroid) {
        debugPrint('OCRService: Checking for lost data...');
        final LostDataResponse response = await _imagePicker.retrieveLostData();
        if (!response.isEmpty && response.file != null) {
          debugPrint('OCRService: Found lost data: ${response.file?.path}');
          return response.file;
        }
      }
    } catch (e) {
      debugPrint('OCRService: Error retrieving lost data: $e');
    }
    return null;
  }

  /// Extracts text from image file
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      debugPrint('OCRService: Extracting text from: ${imageFile.path}');
      if (!await imageFile.exists()) {
        debugPrint('OCRService: File does not exist!');
        return '';
      }
      
      final inputImage = InputImage.fromFile(imageFile);
      debugPrint('OCRService: Processing image with ML Kit...');
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      debugPrint('OCRService: ML Kit processing complete.');

      final buffer = StringBuffer();
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('OCRService: OCR Error: $e');
      return '';
    }
  }

  /// Extracts text from XFile
  Future<String> extractTextFromXFile(XFile xFile) async {
    final file = File(xFile.path);
    return extractTextFromImage(file);
  }

  void dispose() {
    textRecognizer.close();
  }
}

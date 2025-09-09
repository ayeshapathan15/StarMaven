import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  TextRecognizer? _textRecognizer;

  OCRService() {
    _initializeRecognizer();
  }

  void _initializeRecognizer() {
    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    } catch (e) {
      print('Error initializing text recognizer: $e');
    }
  }

  /// Extract raw text from image with proper null safety
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return 'Error: Image file not found';
      }

      // Check if recognizer is initialized
      if (_textRecognizer == null) {
        _initializeRecognizer();
        if (_textRecognizer == null) {
          return 'Error: OCR service not available';
        }
      }

      // Create input image
      InputImage? inputImage;
      try {
        inputImage = InputImage.fromFile(imageFile);
      } catch (e) {
        return 'Error: Could not process image file - $e';
      }

      if (inputImage == null) {
        return 'Error: Could not create input image';
      }

      // Process image
      RecognizedText? recognizedText;
      try {
        recognizedText = await _textRecognizer!.processImage(inputImage);
      } catch (e) {
        return 'Error: OCR processing failed - $e';
      }

      if (recognizedText == null) {
        return 'Error: No response from OCR service';
      }

      // Check if text was found
      if (recognizedText.text.isEmpty || recognizedText.text.trim().isEmpty) {
        return 'No text detected in the image. Please try with a clearer image.';
      }

      // Return cleaned text
      return recognizedText.text.trim();
    } catch (e) {
      return 'OCR processing failed: ${e.toString()}';
    }
  }

  /// Extract text with additional error checking
  Future<Map<String, dynamic>> extractTextWithDetails(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return {
          'text': 'Error: Image file not found',
          'success': false,
          'confidence': 0.0,
        };
      }

      if (_textRecognizer == null) {
        _initializeRecognizer();
        if (_textRecognizer == null) {
          return {
            'text': 'Error: OCR service not available',
            'success': false,
            'confidence': 0.0,
          };
        }
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      if (recognizedText == null || recognizedText.text.isEmpty) {
        return {
          'text': 'No text detected in the image.',
          'success': false,
          'confidence': 0.0,
        };
      }

      // Calculate confidence if available
      double totalConfidence = 0.0;
      int elementCount = 0;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            if (element.confidence != null) {
              totalConfidence += element.confidence!;
              elementCount++;
            }
          }
        }
      }

      double averageConfidence =
          elementCount > 0 ? totalConfidence / elementCount : 0.0;

      return {
        'text': recognizedText.text.trim(),
        'success': true,
        'confidence': averageConfidence * 100,
        'blocks': recognizedText.blocks.length,
        'lines': recognizedText.blocks.fold<int>(
          0,
          (sum, block) => sum + block.lines.length,
        ),
      };
    } catch (e) {
      return {
        'text': 'OCR processing failed: ${e.toString()}',
        'success': false,
        'confidence': 0.0,
      };
    }
  }

  void dispose() {
    try {
      _textRecognizer?.close();
      _textRecognizer = null;
    } catch (e) {
      print('Error disposing OCR service: $e');
    }
  }
}

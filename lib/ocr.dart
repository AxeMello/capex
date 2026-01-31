import 'package:google_ml_kit/google_ml_kit.dart';

Future<String> extractTextFromImage(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final recognizer = GoogleMlKit.vision.textRecognizer();

  final recognizedText = await recognizer.processImage(inputImage);
  recognizer.close();

  return recognizedText.text;
}

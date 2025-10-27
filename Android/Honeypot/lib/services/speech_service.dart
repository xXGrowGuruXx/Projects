import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<bool> initialize() async {
    final hasPermission = await Permission.microphone.isGranted;
    if (!hasPermission) {
      await Permission.microphone.request();
    }
    return await _speech.initialize();
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onStatusChanged,
    String locale = 'de_DE',
  }) async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        _isListening = true;
        _speech.listen(
          onResult: (result) {
            _recognizedText = result.recognizedWords;
            onResult(_recognizedText);
            // Wenn final result, listener stoppen
            if (result.finalResult) {
              _isListening = false;
              onStatusChanged?.call('done');
            }
          },
          localeId: locale,
          listenFor: const Duration(seconds: 60), // Max 60 Sekunden
        );
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void cancel() {
    _speech.cancel();
    _isListening = false;
  }
}

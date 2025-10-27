import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  Future<void> init() async {
    if (!_isInitialized) {
      await _recorder.openRecorder();
      await _player.openPlayer();
      _isInitialized = true;
    }
  }

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String?> startRecording() async {
    await init();
    if (await requestPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      _currentRecordingPath = path;
      return path;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      _isRecording = false;
      return _currentRecordingPath;
    }
    return null;
  }

  Future<void> playAudio(String path) async {
    await init();
    await _player.startPlayer(
      fromURI: path,
      codec: Codec.aacADTS,
    );
  }

  Future<void> pauseAudio() async {
    await _player.pausePlayer();
  }

  Future<void> stopAudio() async {
    await _player.stopPlayer();
  }

  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
  }
}

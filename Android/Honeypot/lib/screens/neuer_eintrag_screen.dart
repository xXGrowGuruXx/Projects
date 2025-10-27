import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/volk.dart';
import '../models/eintrag.dart';
import '../database/database_service.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';

class NeuerEintragScreen extends StatefulWidget {
  final Volk volk;
  const NeuerEintragScreen({super.key, required this.volk});

  @override
  State<NeuerEintragScreen> createState() => _NeuerEintragScreenState();
}

class _NeuerEintragScreenState extends State<NeuerEintragScreen> {
  final DatabaseService _db = DatabaseService();
  final AudioService _audioService = AudioService();
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _audioPath;
  List<String> _bildPaths = [];
  List<String> _videoPaths = [];
  bool _isRecording = false;
  bool _isSpeechActive = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioService.stopRecording();
      setState(() {
        _audioPath = path;
        _isRecording = false;
      });
    } else {
      await _audioService.requestPermission();
      await _audioService.startRecording();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeechActive) {
      await _speechService.stopListening();
      setState(() => _isSpeechActive = false);
    } else {
      final startText = _textController.text;
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            // Anhängen statt überschreiben
            if (startText.isEmpty) {
              _textController.text = text;
            } else {
              _textController.text = '$startText $text';
            }
          });
        },
        onStatusChanged: (status) {
          // Button zurücksetzen wenn Aufnahme stoppt
          if (status == 'notListening' || status == 'done') {
            setState(() => _isSpeechActive = false);
          }
        },
      );
      setState(() => _isSpeechActive = true);
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          _bildPaths.add(image.path);
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _bildPaths.add(image.path));
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() => _videoPaths.add(video.path));
    }
  }

  Future<void> _save() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Text eingeben')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final eintrag = Eintrag(
      id: const Uuid().v4(),
      volkId: widget.volk.id,
      datum: DateTime.now(),
      audioPath: _audioPath,
      text: _textController.text,
      bildPaths: _bildPaths,
      videoPaths: _videoPaths,
      erstelltAm: DateTime.now(),
    );

    await _db.insertEintrag(eintrag);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Eintrag'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Aufnahme stoppen' : 'Sprachnotiz aufnehmen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : null,
                foregroundColor: _isRecording ? Colors.white : null,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            if (_audioPath != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: const Text('Sprachnotiz vorhanden'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _audioService.playAudio(_audioPath!),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
                hintText: 'Beschreibe was du heute beobachtet hast...',
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Foto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.videocam),
              label: const Text('Video aufnehmen'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
            if (_bildPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Bilder:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bildPaths.map((path) {
                  return Stack(
                    children: [
                      Image.file(
                        File(path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() => _bildPaths.remove(path));
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
            if (_videoPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Videos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._videoPaths.map((path) => ListTile(
                    leading: const Icon(Icons.videocam),
                    title: Text(path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _videoPaths.remove(path));
                      },
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _speechService.cancel();
    _textController.dispose();
    super.dispose();
  }
}

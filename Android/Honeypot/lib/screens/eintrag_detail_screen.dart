import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/eintrag.dart';
import '../database/database_service.dart';
import '../services/audio_service.dart';

class EintragDetailScreen extends StatefulWidget {
  final Eintrag eintrag;
  const EintragDetailScreen({super.key, required this.eintrag});

  @override
  State<EintragDetailScreen> createState() => _EintragDetailScreenState();
}

class _EintragDetailScreenState extends State<EintragDetailScreen> {
  final DatabaseService _db = DatabaseService();
  final AudioService _audioService = AudioService();
  late TextEditingController _textController;
  bool _isEditing = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.eintrag.text);
  }

  Future<void> _save() async {
    final updated = widget.eintrag.copyWith(
      text: _textController.text,
      bearbeitetAm: DateTime.now(),
    );
    await _db.updateEintrag(updated);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gespeichert')),
      );
    }
  }

  Future<void> _delete() async {
    final hasFiles = widget.eintrag.audioPath != null || 
                     widget.eintrag.bildPaths.isNotEmpty || 
                     widget.eintrag.videoPaths.isNotEmpty;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: Text(
          hasFiles
              ? 'Dieser Eintrag enthält Dateien (Fotos, Videos, Sprachnotizen).\n\nSollen diese ebenfalls gelöscht werden?'
              : 'Diese Aktion kann nicht rückgängig gemacht werden.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(hasFiles ? 'Alles löschen' : 'Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Dateien löschen
      if (hasFiles) {
        try {
          if (widget.eintrag.audioPath != null) {
            await File(widget.eintrag.audioPath!).delete();
          }
          for (var path in widget.eintrag.bildPaths) {
            await File(path).delete();
          }
          for (var path in widget.eintrag.videoPaths) {
            await File(path).delete();
          }
        } catch (e) {
          // Fehler ignorieren wenn Dateien nicht existieren
        }
      }
      
      await _db.deleteEintrag(widget.eintrag.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eintrag'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(widget.eintrag.datum),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.eintrag.bearbeitetAm != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Bearbeitet: ${dateFormat.format(widget.eintrag.bearbeitetAm!)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            if (widget.eintrag.audioPath != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.audiotrack, size: 32),
                  title: const Text('Sprachnotiz'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          if (_isPlaying) {
                            await _audioService.pauseAudio();
                          } else {
                            await _audioService.playAudio(widget.eintrag.audioPath!);
                          }
                          setState(() => _isPlaying = !_isPlaying);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () async {
                          await _audioService.stopAudio();
                          setState(() => _isPlaying = false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_isEditing)
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                autofocus: true,
              )
            else
              Text(
                widget.eintrag.text,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            if (widget.eintrag.bildPaths.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Bilder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.eintrag.bildPaths.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(widget.eintrag.bildPaths[index]),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
            if (widget.eintrag.videoPaths.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Videos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...widget.eintrag.videoPaths.map(
                (path) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.videocam),
                    title: Text(path.split('/').last),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioService.dispose();
    super.dispose();
  }
}

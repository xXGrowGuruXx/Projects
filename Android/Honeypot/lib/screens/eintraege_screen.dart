import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/volk.dart';
import '../models/eintrag.dart';
import '../database/database_service.dart';
import 'neuer_eintrag_screen.dart';
import 'eintrag_detail_screen.dart';

class EintraegeScreen extends StatefulWidget {
  final Volk volk;
  const EintraegeScreen({super.key, required this.volk});

  @override
  State<EintraegeScreen> createState() => _EintraegeScreenState();
}

class _EintraegeScreenState extends State<EintraegeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Eintrag> _eintraege = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEintraege();
  }

  Future<void> _loadEintraege() async {
    setState(() => _isLoading = true);
    final eintraege = await _db.getEintraegeByVolk(widget.volk.id);
    setState(() {
      _eintraege = eintraege;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.volk.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eintraege.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Einträge',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _eintraege.length,
                  itemBuilder: (context, index) {
                    final eintrag = _eintraege[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EintragDetailScreen(eintrag: eintrag),
                            ),
                          );
                          _loadEintraege();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateFormat.format(eintrag.datum),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (eintrag.audioPath != null)
                                    const Icon(Icons.mic, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                eintrag.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              if (eintrag.bildPaths.isNotEmpty || eintrag.videoPaths.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      if (eintrag.bildPaths.isNotEmpty) ...[
                                        const Icon(Icons.image, size: 16),
                                        Text(' ${eintrag.bildPaths.length}'),
                                        const SizedBox(width: 16),
                                      ],
                                      if (eintrag.videoPaths.isNotEmpty) ...[
                                        const Icon(Icons.videocam, size: 16),
                                        Text(' ${eintrag.videoPaths.length}'),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NeuerEintragScreen(volk: widget.volk),
            ),
          );
          _loadEintraege();
        },
        icon: const Icon(Icons.add),
        label: const Text('Neuer Eintrag'),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_service.dart';
import '../models/volk.dart';
import '../api/http_server.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import 'eintraege_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'varroa_weather_screen.dart';

class VoelkerListScreen extends StatefulWidget {
  final SettingsService settingsService;
  final AuthService authService;
  
  const VoelkerListScreen({
    super.key,
    required this.settingsService,
    required this.authService,
  });

  @override
  State<VoelkerListScreen> createState() => _VoelkerListScreenState();
}

class _VoelkerListScreenState extends State<VoelkerListScreen> {
  final DatabaseService _db = DatabaseService();
  late final HttpServerService _server;
  List<Volk> _voelker = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _server = HttpServerService(
      settingsService: widget.settingsService,
      authService: widget.authService,
    );
    _loadVoelker();
  }

  Future<void> _loadVoelker() async {
    setState(() => _isLoading = true);
    final voelker = await _db.getAllVoelker();
    setState(() {
      _voelker = voelker;
      _isLoading = false;
    });
  }

  bool _isPremiumUser() {
    final user = widget.authService.currentUser;
    return user?.role == 'premium' || user?.role == 'admin';
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'Du hast das Limit von 3 Völkern erreicht.\n\n'
          'Upgrade auf Premium für:\n'
          '• Unbegrenzte Völker\n'
          '• Datenbank-Export\n'
          '• Cloud-Backup\n'
          '• Varroa-Erinnerungen\n'
          '• Und vieles mehr!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(authService: widget.authService),
              ));
            },
            icon: const Icon(Icons.star),
            label: const Text('Zum Profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addVolk() async {
    // Prüfe Völker-Limit für Standard-User
    if (!_isPremiumUser() && _voelker.length >= 3) {
      _showPremiumDialog();
      return;
    }

    final controller = TextEditingController();
    final beschreibungController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Volk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: beschreibungController,
              decoration: const InputDecoration(labelText: 'Beschreibung (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final volk = Volk(
                  id: const Uuid().v4(),
                  name: controller.text,
                  beschreibung: beschreibungController.text.isEmpty 
                      ? null 
                      : beschreibungController.text,
                  erstelltAm: DateTime.now(),
                );
                await _db.insertVolk(volk);
                if (context.mounted) Navigator.pop(context);
                _loadVoelker();
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVolk(Volk volk) async {
    // Prüfe ob Volk Einträge mit Dateien hat
    final eintraege = await _db.getEintraegeByVolk(volk.id);
    final hasFiles = eintraege.any((e) => 
      e.audioPath != null || e.bildPaths.isNotEmpty || e.videoPaths.isNotEmpty
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${volk.name}" löschen?'),
        content: Text(
          hasFiles
              ? 'Dieses Volk hat Einträge mit Dateien (Fotos, Videos, Sprachnotizen).\n\nAlle Einträge und Dateien werden ebenfalls gelöscht!'
              : 'Alle Einträge dieses Volkes werden ebenfalls gelöscht.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Alles löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Dateien aller Einträge löschen
      if (hasFiles) {
        for (var eintrag in eintraege) {
          try {
            if (eintrag.audioPath != null) {
              await File(eintrag.audioPath!).delete();
            }
            for (var path in eintrag.bildPaths) {
              await File(path).delete();
            }
            for (var path in eintrag.videoPaths) {
              await File(path).delete();
            }
          } catch (e) {
            // Fehler ignorieren
          }
        }
      }
      
      await _db.deleteVolk(volk.id);
      _loadVoelker();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${volk.name}" wurde gelöscht')),
        );
      }
    }
  }

  Future<void> _toggleServer() async {
    if (_server.isRunning) {
      await _server.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server gestoppt')),
        );
      }
    } else {
      await _server.start();
      if (mounted) {
        final ip = await _server.getLocalIpAddress();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server läuft auf: http://$ip:8080'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AnimatedBuilder(
              animation: widget.authService,
              builder: (context, _) {
                final user = widget.authService.currentUser;
                return DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFBB02), Color(0xFFFFA000)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      user?.photoUrl != null
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(user!.photoUrl!),
                          )
                        : const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 35, color: Color(0xFFFFBB02)),
                          ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? 'Imker',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(l10n.profile),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfileScreen(authService: widget.authService),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    settingsService: widget.settingsService,
                    authService: widget.authService,
                  ),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Varroa Wetter'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VarroaWeatherScreen(authService: widget.authService),
                ));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('🐝 ${l10n.voelker}'),
        actions: [
          IconButton(
            icon: Icon(_server.isRunning ? Icons.wifi : Icons.wifi_off),
            onPressed: _toggleServer,
            tooltip: _server.isRunning ? 'Server stoppen' : 'Server starten',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_server.isRunning)
            FutureBuilder<String>(
              future: _server.getLocalIpAddress(),
              builder: (context, snapshot) {
                final ip = snapshot.data ?? '0.0.0.0';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.green.shade200, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wifi, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            l10n.server_running,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.copy_to_browser,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'http://$ip:8080',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Expanded(
            child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _voelker.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hive, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.no_voelker,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.add_first_volk,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _voelker.length,
                  itemBuilder: (context, index) {
                    final volk = _voelker[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          child: Icon(Icons.hive),
                        ),
                        title: Text(
                          volk.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: volk.beschreibung != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(volk.beschreibung!),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EintraegeScreen(volk: volk),
                            ),
                          );
                        },
                        onLongPress: () => _deleteVolk(volk),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVolk,
        icon: const Icon(Icons.add),
        label: Text(l10n.new_volk),
      ),
    );
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }
}

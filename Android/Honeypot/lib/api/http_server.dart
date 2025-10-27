import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../database/database_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';

class HttpServerService {
  HttpServer? _server;
  final DatabaseService _db = DatabaseService();
  final SettingsService? settingsService;
  final AuthService? authService;
  int _port = 8080;
  
  HttpServerService({this.settingsService, this.authService});

  bool get isRunning => _server != null;
  String get serverUrl => _server != null ? 'http://0.0.0.0:$_port' : '';

  Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168') || addr.address.startsWith('10.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      return '0.0.0.0';
    }
    return '0.0.0.0';
  }

  Future<void> start() async {
    if (_server != null) return;

    final router = Router();

    // CORS Headers
    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    // API Endpoints
    router.get('/api/voelker', _getAllVoelker);
    router.get('/api/voelker/<volkId>', _getVolk);
    router.get('/api/voelker/<volkId>/eintraege', _getEintraege);
    router.get('/api/eintraege/<id>', _getEintrag);
    router.put('/api/eintraege/<id>', _updateEintrag);
    router.delete('/api/eintraege/<id>', _deleteEintrag);
    router.get('/api/export', _exportData);
    router.get('/api/media/<type>/<filename>', _getMedia);
    router.get('/api/language', _getLanguage);
    router.get('/api/user-role', _getUserRole);
    router.get('/', _getWebInterface);

    _server = await io.serve(handler, InternetAddress.anyIPv4, _port);
    final ip = await getLocalIpAddress();
    print('Server läuft auf: http://$ip:$_port');
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };

  Future<Response> _getAllVoelker(Request request) async {
    try {
      final voelker = await _db.getAllVoelker();
      return Response.ok(
        jsonEncode(voelker.map((v) => v.toMap()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getVolk(Request request, String volkId) async {
    try {
      final volk = await _db.getVolk(volkId);
      if (volk == null) {
        return Response.notFound(jsonEncode({'error': 'Volk nicht gefunden'}));
      }
      return Response.ok(
        jsonEncode(volk.toMap()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getEintraege(Request request, String volkId) async {
    try {
      final eintraege = await _db.getEintraegeByVolk(volkId);
      return Response.ok(
        jsonEncode(eintraege.map((e) => e.toMap()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getEintrag(Request request, String id) async {
    try {
      final eintrag = await _db.getEintrag(id);
      if (eintrag == null) {
        return Response.notFound(jsonEncode({'error': 'Eintrag nicht gefunden'}));
      }
      return Response.ok(
        jsonEncode(eintrag.toMap()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _updateEintrag(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final eintrag = await _db.getEintrag(id);
      
      if (eintrag == null) {
        return Response.notFound(jsonEncode({'error': 'Eintrag nicht gefunden'}));
      }

      final updated = eintrag.copyWith(
        text: data['text'],
        bearbeitetAm: DateTime.now(),
      );
      
      await _db.updateEintrag(updated);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _deleteEintrag(Request request, String id) async {
    try {
      await _db.deleteEintrag(id);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _exportData(Request request) async {
    try {
      // Format aus Query-Parameter auslesen (default: sqlite)
      final format = request.url.queryParameters['format'] ?? 'sqlite';
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      switch (format) {
        case 'sqlite':
          return await _exportSQLite(tempDir, timestamp);
        case 'pdf':
          return await _exportPDF(tempDir, timestamp);
        case 'excel':
          return await _exportExcel(tempDir, timestamp);
        default:
          return Response.badRequest(body: jsonEncode({'error': 'Ungültiges Format: $format'}));
      }
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }
  
  Future<Response> _exportSQLite(Directory tempDir, int timestamp) async {
    final exportDir = Directory('${tempDir.path}/export_$timestamp');
    await exportDir.create();

    // Datenbank kopieren
    final dbPath = await _db.database.then((db) => db.path);
    await File(dbPath).copy('${exportDir.path}/database.db');

    // Medien kopieren
    final appDir = await getApplicationDocumentsDirectory();
    final audioFiles = Directory(appDir.path).listSync().where((f) => f.path.endsWith('.m4a'));
    for (var file in audioFiles) {
      await File(file.path).copy('${exportDir.path}/${file.path.split('/').last}');
    }

    // ZIP erstellen
    final encoder = ZipFileEncoder();
    final zipPath = '${tempDir.path}/imker_tagebuch_export.zip';
    encoder.create(zipPath);
    encoder.addDirectory(exportDir);
    encoder.close();

    final zipFile = File(zipPath);
    final bytes = await zipFile.readAsBytes();

    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'application/zip',
        'Content-Disposition': 'attachment; filename="imker_tagebuch_export.zip"',
      },
    );
  }
  
  Future<Response> _exportPDF(Directory tempDir, int timestamp) async {
    // PDF-Export implementieren
    final pdf = pw.Document();
    
    // Alle Völker und Einträge holen
    final voelker = await _db.getAllVoelker();
    
    // Titelseite
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Imker Tagebuch', style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Export vom ${DateTime.now().toString().split('.')[0]}'),
                pw.SizedBox(height: 10),
                pw.Text('Anzahl Völker: ${voelker.length}'),
              ],
            ),
          );
        },
      ),
    );
    
    // Seite pro Volk
    for (var volk in voelker) {
      final eintraege = await _db.getEintraegeByVolk(volk.id);
      
      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Volk: ${volk.name}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Beschreibung: ${volk.beschreibung ?? "Keine Beschreibung"}'),
            pw.Text('Erstellt: ${volk.erstelltAm.toString().split('.')[0]}'),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Einträge (${eintraege.length})')),
            pw.SizedBox(height: 10),
            ...eintraege.map((eintrag) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    eintrag.erstelltAm.toString().split('.')[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(eintrag.text),
                ],
              ),
            )),
          ],
        ),
      );
    }
    
    final pdfFile = File('${tempDir.path}/imker_tagebuch_export.pdf');
    await pdfFile.writeAsBytes(await pdf.save());
    final bytes = await pdfFile.readAsBytes();
    
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': 'attachment; filename="imker_tagebuch_export.pdf"',
      },
    );
  }
  
  Future<Response> _exportExcel(Directory tempDir, int timestamp) async {
    // Excel-Export implementieren
    var excel = Excel.createExcel();
    excel.rename('Sheet1', 'Uebersicht');
    
    final voelker = await _db.getAllVoelker();
    final sheet = excel['Uebersicht'];
    
    // Header
    sheet.appendRow([TextCellValue('Voelker-Uebersicht')]);
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Beschreibung'),
      TextCellValue('Erstellt'),
      TextCellValue('Anzahl Eintraege')
    ]);
    
    // Daten
    for (var volk in voelker) {
      final eintraege = await _db.getEintraegeByVolk(volk.id);
      sheet.appendRow([
        TextCellValue(volk.name),
        TextCellValue(volk.beschreibung ?? ''),
        TextCellValue(volk.erstelltAm.toString().split('.')[0]),
        IntCellValue(eintraege.length),
      ]);
    }
    
    // Sheets für jedes Volk mit Einträgen
    for (var volk in voelker) {
      final eintraege = await _db.getEintraegeByVolk(volk.id);
      final sheetName = volk.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      excel.copy('Uebersicht', sheetName);
      excel.delete(sheetName);
      final volkSheet = excel[sheetName];
      
      volkSheet.appendRow([TextCellValue('Datum'), TextCellValue('Text'), TextCellValue('Bearbeitet')]);
      for (var eintrag in eintraege) {
        volkSheet.appendRow([
          TextCellValue(eintrag.erstelltAm.toString().split('.')[0]),
          TextCellValue(eintrag.text),
          TextCellValue(eintrag.bearbeitetAm?.toString().split('.')[0] ?? ''),
        ]);
      }
    }
    
    final excelFile = File('${tempDir.path}/imker_tagebuch_export.xlsx');
    await excelFile.writeAsBytes(excel.encode()!);
    final bytes = await excelFile.readAsBytes();
    
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': 'attachment; filename="imker_tagebuch_export.xlsx"',
      },
    );
  }

  Future<Response> _getLanguage(Request request) async {
    final lang = settingsService?.locale?.languageCode ?? 'de';
    return Response.ok(
      jsonEncode({'language': lang}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getUserRole(Request request) async {
    final user = authService?.currentUser;
    final role = user?.role ?? 'standard';
    final isPremium = role == 'premium' || role == 'admin';
    return Response.ok(
      jsonEncode({
        'role': role,
        'isPremium': isPremium,
        'isAuthenticated': authService?.isAuthenticated ?? false,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getMedia(Request request, String type, String filename) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$filename';
      final file = File(filePath);

      if (!await file.exists()) {
        return Response.notFound('Datei nicht gefunden');
      }

      final bytes = await file.readAsBytes();
      final mimeType = type == 'audio' ? 'audio/m4a' : 'image/jpeg';

      return Response.ok(bytes, headers: {'Content-Type': mimeType});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getWebInterface(Request request) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title id="page-title">Honeypot - Web Interface</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        /* Header */
        header {
            background: rgba(255,255,255,0.95);
            box-shadow: 0 2px 20px rgba(0,0,0,0.1);
            padding: 20px 0;
            position: sticky;
            top: 0;
            z-index: 1000;
        }
        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .logo {
            font-size: 32px;
            font-weight: 700;
            color: #667eea;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        nav {
            display: flex;
            gap: 20px;
        }
        nav button {
            background: transparent;
            border: 2px solid #667eea;
            color: #667eea;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s;
        }
        nav button:hover {
            background: #667eea;
            color: white;
        }
        
        /* Main Content */
        main {
            flex: 1;
            max-width: 1200px;
            width: 100%;
            margin: 40px auto;
            padding: 0 20px;
        }
        .content-card {
            background: rgba(255,255,255,0.95);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #2c3e50; 
            margin-bottom: 30px;
            font-size: 36px;
        }
        .voelker-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); 
            gap: 24px;
            margin-top: 30px;
        }
        .volk-card { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 16px; 
            padding: 24px; 
            cursor: pointer; 
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .volk-card:hover { 
            transform: translateY(-8px); 
            box-shadow: 0 12px 30px rgba(0,0,0,0.2);
        }
        .volk-name { 
            font-size: 24px; 
            font-weight: 700; 
            margin-bottom: 12px; 
        }
        .volk-info { 
            opacity: 0.9; 
            font-size: 14px;
            margin-top: 8px;
        }
        .eintrag { 
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            border-radius: 8px; 
            padding: 20px; 
            margin-bottom: 20px;
            transition: all 0.2s;
        }
        .eintrag:hover {
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .eintrag-datum { 
            color: #667eea; 
            font-weight: 700; 
            margin-bottom: 12px;
            font-size: 16px;
        }
        .eintrag-text { 
            color: #2c3e50; 
            line-height: 1.8;
        }
        .back-btn { 
            background: #667eea; 
            color: white; 
            border: none; 
            padding: 12px 24px; 
            border-radius: 8px; 
            cursor: pointer; 
            margin-bottom: 24px;
            font-weight: 600;
            transition: all 0.3s;
        }
        .back-btn:hover {
            background: #764ba2;
        }
        .export-btn { 
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white; 
            border: none; 
            padding: 16px 32px; 
            border-radius: 10px; 
            cursor: pointer; 
            font-size: 18px;
            font-weight: 700;
            box-shadow: 0 4px 15px rgba(245, 87, 108, 0.3);
            transition: all 0.3s;
        }
        .export-btn:hover { 
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(245, 87, 108, 0.4);
        }
        
        /* Footer */
        footer {
            background: rgba(0,0,0,0.8);
            color: white;
            text-align: center;
            padding: 24px 20px;
            margin-top: 60px;
        }
        .footer-content {
            max-width: 1200px;
            margin: 0 auto;
        }
        .copyright {
            font-size: 14px;
            opacity: 0.9;
        }
        .creator {
            font-weight: 700;
            color: #667eea;
        }
    </style>
</head>
<body>
    <header>
        <div class="header-content">
            <div class="logo" id="logo">🍯 Honeypot</div>
            <nav>
                <button id="btn-hives" onclick="loadVoelker()">🏡 Völker</button>
            </nav>
        </div>
    </header>
    
    <main>
        <div class="content-card" id="content"></div>
    </main>
    
    <footer>
        <div class="footer-content">
            <p class="copyright" id="copyright">Copyright © 2025 created by <span class="creator">xXGrowGuruXx</span></p>
        </div>
    </footer>
    <script>
        let currentVolk = null;
        let currentLang = 'de';
        
        const translations = {
            de: {
                title: 'Honeypot',
                hives: 'Völker',
                export: 'Export',
                myHives: 'Meine Völker',
                exportAll: 'Komplettes Tagebuch exportieren',
                noHives: 'Noch keine Völker vorhanden',
                noDescription: 'Keine Beschreibung',
                created: 'Erstellt',
                backToHives: 'Zurück zu Völkern',
                noEntries: 'Noch keine Einträge vorhanden',
                voiceNote: 'Sprachnotiz vorhanden',
                copyright: 'Copyright © 2025 created by',
                premiumTitle: 'Premium Feature',
                premiumMessage: 'Der Export ist nur für Premium- und Admin-Benutzer verfügbar. Bitte upgraden Sie in der App auf Premium, um diese Funktion zu nutzen.',
                premiumOk: 'Verstanden'
            },
            en: {
                title: 'Honeypot',
                hives: 'Hives',
                export: 'Export',
                myHives: 'My Hives',
                exportAll: 'Export Complete Diary',
                noHives: 'No hives yet',
                noDescription: 'No Description',
                created: 'Created',
                backToHives: 'Back to Hives',
                noEntries: 'No entries yet',
                voiceNote: 'Voice note available',
                copyright: 'Copyright © 2025 created by',
                premiumTitle: 'Premium Feature',
                premiumMessage: 'Export is only available for Premium and Admin users. Please upgrade to Premium in the app to use this feature.',
                premiumOk: 'Got it'
            },
            fr: {
                title: 'Honeypot',
                hives: 'Ruches',
                export: 'Exporter',
                myHives: 'Mes Ruches',
                exportAll: 'Exporter le Journal Complet',
                noHives: 'Pas encore de ruches',
                noDescription: 'Pas de Description',
                created: 'Créé',
                backToHives: 'Retour aux Ruches',
                noEntries: "Pas encore d'entrées",
                voiceNote: 'Note vocale disponible',
                copyright: 'Copyright © 2025 créé par',
                premiumTitle: 'Fonctionnalité Premium',
                premiumMessage: "L'exportation n'est disponible que pour les utilisateurs Premium et Admin. Veuillez passer à Premium dans l'application pour utiliser cette fonctionnalité.",
                premiumOk: 'Compris'
            },
            es: {
                title: 'Honeypot',
                hives: 'Colmenas',
                export: 'Exportar',
                myHives: 'Mis Colmenas',
                exportAll: 'Exportar Diario Completo',
                noHives: 'Aún no hay colmenas',
                noDescription: 'Sin Descripción',
                created: 'Creado',
                backToHives: 'Volver a Colmenas',
                noEntries: 'Aún no hay entradas',
                voiceNote: 'Nota de voz disponible',
                copyright: 'Copyright © 2025 creado por',
                premiumTitle: 'Función Premium',
                premiumMessage: 'La exportación solo está disponible para usuarios Premium y Admin. Actúalice a Premium en la aplicación para usar esta función.',
                premiumOk: 'Entendido'
            },
            it: {
                title: 'Honeypot',
                hives: 'Alveari',
                export: 'Esporta',
                myHives: 'I Miei Alveari',
                exportAll: 'Esporta Diario Completo',
                noHives: 'Nessun alveare ancora',
                noDescription: 'Nessuna Descrizione',
                created: 'Creato',
                backToHives: 'Torna agli Alveari',
                noEntries: 'Nessuna voce ancora',
                voiceNote: 'Nota vocale disponibile',
                copyright: 'Copyright © 2025 creato da',
                premiumTitle: 'Funzione Premium',
                premiumMessage: "L'esportazione è disponibile solo per utenti Premium e Admin. Effettua l'upgrade a Premium nell'app per utilizzare questa funzione.",
                premiumOk: 'Capito'
            },
            pl: {
                title: 'Honeypot',
                hives: 'Ule',
                export: 'Eksportuj',
                myHives: 'Moje Ule',
                exportAll: 'Eksportuj Cały Dziennik',
                noHives: 'Jeszcze brak uli',
                noDescription: 'Brak Opisu',
                created: 'Utworzono',
                backToHives: 'Powrót do Uli',
                noEntries: 'Jeszcze brak wpisów',
                voiceNote: 'Notatka Głosowa Dostępna',
                copyright: 'Copyright © 2025 utworzył',
                premiumTitle: 'Funkcja Premium',
                premiumMessage: 'Eksport jest dostępny tylko dla użytkowników Premium i Admin. Zaktualizuj do Premium w aplikacji, aby używać tej funkcji.',
                premiumOk: 'Rozumiem'
            },
            tr: {
                title: 'Honeypot',
                hives: 'Kovanlar',
                export: 'Dışa Aktar',
                myHives: 'Kovanlarım',
                exportAll: 'Tüm Günlüğü Dışa Aktar',
                noHives: 'Henüz kovan yok',
                noDescription: 'Açıklama Yok',
                created: 'Oluşturuldu',
                backToHives: 'Kovanlara Geri Dön',
                noEntries: 'Henüz giriş yok',
                voiceNote: 'Sesli Not Mevcut',
                copyright: 'Copyright © 2025 oluşturan',
                premiumTitle: 'Premium Özellik',
                premiumMessage: 'Dışa aktarma yalnızca Premium ve Admin kullanıcıları için kullanılabilir. Bu özelliği kullanmak için lütfen uygulamada Premiuma yükseltin.',
                premiumOk: 'Anlaşıldı'
            },
            ru: {
                title: 'Honeypot',
                hives: 'Ульи',
                export: 'Экспорт',
                myHives: 'Мои Ульи',
                exportAll: 'Экспортировать Весь Дневник',
                noHives: 'Пока нет ульев',
                noDescription: 'Нет Описания',
                created: 'Создано',
                backToHives: 'Вернуться к Ульям',
                noEntries: 'Пока нет записей',
                voiceNote: 'Голосовая Заметка Доступна',
                copyright: 'Copyright © 2025 создал',
                premiumTitle: 'Премиум функция',
                premiumMessage: 'Экспорт доступен только для пользователей Premium и Admin. Пожалуйста, обновитесь до Premium в приложении.',
                premiumOk: 'Понятно'
            },
            uk: {
                title: 'Honeypot',
                hives: 'Вулики',
                export: 'Експорт',
                myHives: 'Мої Вулики',
                exportAll: 'Експортувати Весь Щоденник',
                noHives: 'Поки немає вуликів',
                noDescription: 'Немає Опису',
                created: 'Створено',
                backToHives: 'Повернутися до Вуликів',
                noEntries: 'Поки немає записів',
                voiceNote: 'Голосова Примітка Доступна',
                copyright: 'Copyright © 2025 створив',
                premiumTitle: 'Преміум функція',
                premiumMessage: 'Експорт доступний тільки для користувачів Premium та Admin. Будь ласка, оновіться до Premium в додатку.',
                premiumOk: 'Зрозуміло'
            },
            zh: {
                title: 'Honeypot',
                hives: '蜂箱',
                export: '导出',
                myHives: '我的蜂箱',
                exportAll: '导出整个日记',
                noHives: '暂无蜂箱',
                noDescription: '无描述',
                created: '已创建',
                backToHives: '返回蜂箱',
                noEntries: '暂无条目',
                voiceNote: '语音备忘可用',
                copyright: 'Copyright © 2025 作者',
                premiumTitle: '高级功能',
                premiumMessage: '导出仅限Premium和Admin用户使用。请在应用程序中升级到Premium以使用此功能。',
                premiumOk: '知道了'
            }
        };
        
        function t(key) {
            return translations[currentLang]?.[key] || translations['de'][key] || key;
        }
        
        async function initLanguage() {
            try {
                const res = await fetch('/api/language');
                const data = await res.json();
                currentLang = data.language || 'de';
                document.documentElement.lang = currentLang;
                document.getElementById('page-title').textContent = t('title') + ' - Web Interface';
            } catch (e) {
                console.error('Language load error:', e);
                currentLang = 'de';
            }
        }

        async function loadVoelker() {
            const res = await fetch('/api/voelker');
            const voelker = await res.json();
            
            const localeMap = {'de':'de-DE','en':'en-US','fr':'fr-FR','es':'es-ES','it':'it-IT','pl':'pl-PL','tr':'tr-TR','ru':'ru-RU','uk':'uk-UA','zh':'zh-CN'};
            const locale = localeMap[currentLang] || 'de-DE';
            
            const html = voelker.map(v => 
                '<div class="volk-card" onclick="loadEintraege(\\'' + v.id + '\\', \\'' + v.name.replace(/'/g, "\\\\'" ) + '\\')">' +
                    '<div class="volk-name">🐝 ' + v.name + '</div>' +
                    '<div class="volk-info">' + (v.beschreibung || t('noDescription')) + '</div>' +
                    '<div class="volk-info">📅 ' + t('created') + ': ' + new Date(v.erstellt_am).toLocaleDateString(locale) + '</div>' +
                '</div>'
            ).join('');
            
            // Export-Button mit Premium-Krone
            const exportBtnHtml = '<button class="export-btn" style="margin:0;" onclick="handleExportClick()">👑 📦 ' + t('exportAll') + '</button>';
            
            document.getElementById('content').innerHTML = 
                '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:30px;">' +
                    '<h1 style="margin:0;">' + t('myHives') + '</h1>' +
                    exportBtnHtml +
                '</div>' +
                '<div class="voelker-grid">' + (html || '<p style="text-align:center;color:#7f8c8d;">' + t('noHives') + '</p>') + '</div>';
        }

        async function loadEintraege(volkId, volkName) {
            currentVolk = volkId;
            const res = await fetch('/api/voelker/' + volkId + '/eintraege');
            const eintraege = await res.json();
            
            const localeMap = {'de':'de-DE','en':'en-US','fr':'fr-FR','es':'es-ES','it':'it-IT','pl':'pl-PL','tr':'tr-TR','ru':'ru-RU','uk':'uk-UA','zh':'zh-CN'};
            const locale = localeMap[currentLang] || 'de-DE';
            
            const html = eintraege.map(e => 
                '<div class="eintrag">' +
                    '<div class="eintrag-datum">📅 ' + new Date(e.datum).toLocaleDateString(locale) + '</div>' +
                    '<div class="eintrag-text">' + e.text + '</div>' +
                    (e.audio_path ? '<div style="margin-top:10px;">🎙️ ' + t('voiceNote') + '</div>' : '') +
                '</div>'
            ).join('');
            
            document.getElementById('content').innerHTML = 
                '<button class="back-btn" onclick="loadVoelker()">← ' + t('backToHives') + '</button>' +
                '<h1>🐝 ' + volkName.replace(/'/g, "\\'") + '</h1>' +
                (html || '<p style="text-align:center;color:#7f8c8d;padding:40px;">' + t('noEntries') + '</p>');
        }

        let userIsPremium = false;
        
        async function handleExportClick() {
            if (!userIsPremium) {
                showPremiumDialog();
            } else {
                await exportData();
            }
        }
        
        async function exportData() {
            // Zeige Format-Auswahl
            const format = await showExportDialog();
            if (!format) return;
            
            const a = document.createElement('a');
            a.href = '/api/export?format=' + format;
            a.download = 'imker_tagebuch_export.' + (format === 'sqlite' ? 'zip' : format);
            a.click();
        }
        
        function showPremiumDialog() {
            const modal = document.createElement('div');
            modal.style = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0,0,0,0.5);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 9999;
            `;
            
            modal.innerHTML = `
                <div style="
                    background: white;
                    border-radius: 20px;
                    padding: 40px;
                    max-width: 500px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    text-align: center;
                ">
                    <div style="font-size: 64px; margin-bottom: 20px;">👑</div>
                    <h2 style="margin-bottom: 20px; color: #2c3e50;">` + t('premiumTitle') + `</h2>
                    <p style="color: #7f8c8d; line-height: 1.6; margin-bottom: 30px;">` + t('premiumMessage') + `</p>
                    <button onclick="closePremiumDialog()" style="
                        padding: 15px 40px;
                        border: none;
                        border-radius: 8px;
                        background: #667eea;
                        color: white;
                        cursor: pointer;
                        font-size: 16px;
                        font-weight: 600;
                    ">
                        ` + t('premiumOk') + `
                    </button>
                </div>
            `;
            
            window.closePremiumDialog = () => {
                document.body.removeChild(modal);
                delete window.closePremiumDialog;
            };
            
            document.body.appendChild(modal);
        }
        
        function showExportDialog() {
            return new Promise((resolve) => {
                const modal = document.createElement('div');
                modal.style = `
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0,0,0,0.5);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 9999;
                `;
                
                modal.innerHTML = `
                    <div style="
                        background: white;
                        border-radius: 20px;
                        padding: 40px;
                        max-width: 500px;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    ">
                        <h2 style="margin-bottom: 20px; color: #2c3e50;">Export-Format wählen</h2>
                        <div style="display: flex; flex-direction: column; gap: 15px;">
                            <button onclick="selectFormat('sqlite')" style="
                                padding: 20px;
                                border: 2px solid #667eea;
                                border-radius: 12px;
                                background: white;
                                cursor: pointer;
                                font-size: 16px;
                                font-weight: 600;
                                color: #667eea;
                                transition: all 0.3s;
                            " onmouseover="this.style.background='#667eea'; this.style.color='white'" onmouseout="this.style.background='white'; this.style.color='#667eea'">
                                📦 SQLite Datenbank + Medien (ZIP)
                            </button>
                            <button onclick="selectFormat('pdf')" style="
                                padding: 20px;
                                border: 2px solid #667eea;
                                border-radius: 12px;
                                background: white;
                                cursor: pointer;
                                font-size: 16px;
                                font-weight: 600;
                                color: #667eea;
                                transition: all 0.3s;
                            " onmouseover="this.style.background='#667eea'; this.style.color='white'" onmouseout="this.style.background='white'; this.style.color='#667eea'">
                                📄 PDF Dokument
                            </button>
                            <button onclick="selectFormat('excel')" style="
                                padding: 20px;
                                border: 2px solid #667eea;
                                border-radius: 12px;
                                background: white;
                                cursor: pointer;
                                font-size: 16px;
                                font-weight: 600;
                                color: #667eea;
                                transition: all 0.3s;
                            " onmouseover="this.style.background='#667eea'; this.style.color='white'" onmouseout="this.style.background='white'; this.style.color='#667eea'">
                                📈 Excel Tabelle
                            </button>
                            <button onclick="selectFormat(null)" style="
                                padding: 15px;
                                border: none;
                                border-radius: 8px;
                                background: #ccc;
                                cursor: pointer;
                                font-size: 14px;
                            ">
                                Abbrechen
                            </button>
                        </div>
                    </div>
                `;
                
                window.selectFormat = (format) => {
                    document.body.removeChild(modal);
                    delete window.selectFormat;
                    resolve(format);
                };
                
                document.body.appendChild(modal);
            });
        }
        
        function updateUILanguage() {
            document.getElementById('logo').textContent = '🐝 ' + t('title');
            document.getElementById('btn-hives').textContent = '🏡 ' + t('hives');
            document.getElementById('copyright').innerHTML = t('copyright') + ' <span class="creator">xXGrowGuruXx</span>';
        }
        
        async function checkUserRole() {
            try {
                const res = await fetch('/api/user-role');
                const data = await res.json();
                userIsPremium = data.isPremium || false;
            } catch (e) {
                console.error('Role check error:', e);
                userIsPremium = false;
            }
        }

        async function init() {
            await initLanguage();
            await checkUserRole();
            updateUILanguage();
            await loadVoelker();
        }

        init();
    </script>
</body>
</html>
    ''';

    return Response.ok(html, headers: {'Content-Type': 'text/html; charset=utf-8'});
  }
}

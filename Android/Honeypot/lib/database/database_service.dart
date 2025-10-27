import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/volk.dart';
import '../models/eintrag.dart';

class DatabaseService {
  static Database? _database;
  // TODO: Verschlüsselung später implementieren
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'imker_tagebuch.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE voelker (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        beschreibung TEXT,
        erstellt_am TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE eintraege (
        id TEXT PRIMARY KEY,
        volk_id TEXT NOT NULL,
        datum TEXT NOT NULL,
        audio_path TEXT,
        text TEXT NOT NULL,
        bild_paths TEXT,
        video_paths TEXT,
        erstellt_am TEXT NOT NULL,
        bearbeitet_am TEXT,
        FOREIGN KEY (volk_id) REFERENCES voelker (id) ON DELETE CASCADE
      )
    ''');
  }

  // Volk CRUD
  Future<void> insertVolk(Volk volk) async {
    final db = await database;
    await db.insert('voelker', volk.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Volk>> getAllVoelker() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('voelker', orderBy: 'erstellt_am DESC');
    return List.generate(maps.length, (i) => Volk.fromMap(maps[i]));
  }

  Future<Volk?> getVolk(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'voelker',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Volk.fromMap(maps.first);
  }

  Future<void> updateVolk(Volk volk) async {
    final db = await database;
    await db.update('voelker', volk.toMap(), where: 'id = ?', whereArgs: [volk.id]);
  }

  Future<void> deleteVolk(String id) async {
    final db = await database;
    await db.delete('voelker', where: 'id = ?', whereArgs: [id]);
  }

  // Eintrag CRUD
  Future<void> insertEintrag(Eintrag eintrag) async {
    final db = await database;
    await db.insert('eintraege', eintrag.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Eintrag>> getEintraegeByVolk(String volkId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'eintraege',
      where: 'volk_id = ?',
      whereArgs: [volkId],
      orderBy: 'datum DESC',
    );
    return List.generate(maps.length, (i) => Eintrag.fromMap(maps[i]));
  }

  Future<List<Eintrag>> getAllEintraege() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('eintraege', orderBy: 'datum DESC');
    return List.generate(maps.length, (i) => Eintrag.fromMap(maps[i]));
  }

  Future<Eintrag?> getEintrag(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'eintraege',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Eintrag.fromMap(maps.first);
  }

  Future<void> updateEintrag(Eintrag eintrag) async {
    final db = await database;
    await db.update('eintraege', eintrag.toMap(), where: 'id = ?', whereArgs: [eintrag.id]);
  }

  Future<void> deleteEintrag(String id) async {
    final db = await database;
    await db.delete('eintraege', where: 'id = ?', whereArgs: [id]);
  }
}

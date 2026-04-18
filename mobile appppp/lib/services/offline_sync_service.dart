import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/complaint_model.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  static Database? _database;

  OfflineSyncService._internal();

  factory OfflineSyncService() {
    return _instance;
  }

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grievance_system.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_complaints (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT,
        priority TEXT,
        latitude REAL,
        longitude REAL,
        image_url TEXT,
        voice_url TEXT,
        user_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Save complaint locally
  Future<void> savePendingComplaint(Complaint complaint) async {
    final db = await database;
    await db.insert(
      'offline_complaints',
      {
        'id': complaint.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': complaint.title,
        'description': complaint.description,
        'category': complaint.category,
        'status': complaint.status,
        'priority': complaint.priority,
        'latitude': complaint.latitude,
        'longitude': complaint.longitude,
        'image_url': complaint.imageUrl,
        'voice_url': complaint.voiceUrl,
        'user_id': complaint.userId,
        'created_at': complaint.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get pending complaints
  Future<List<Complaint>> getPendingComplaints() async {
    final db = await database;
    final maps = await db.query(
      'offline_complaints',
      where: 'synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return Complaint(
        id: maps[i]['id'] as String,
        title: maps[i]['title'] as String,
        description: maps[i]['description'] as String,
        category: maps[i]['category'] as String,
        status: maps[i]['status'] as String? ?? 'Submitted',
        priority: maps[i]['priority'] as String?,
        latitude: maps[i]['latitude'] as double?,
        longitude: maps[i]['longitude'] as double?,
        imageUrl: maps[i]['image_url'] as String?,
        voiceUrl: maps[i]['voice_url'] as String?,
        userId: maps[i]['user_id'] as String,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        updatedAt: maps[i]['updated_at'] != null
            ? DateTime.parse(maps[i]['updated_at'] as String)
            : null,
      );
    });
  }

  // Mark as synced
  Future<void> markAsSynced(String complaintId) async {
    final db = await database;
    await db.update(
      'offline_complaints',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [complaintId],
    );
  }

  // Delete complaint
  Future<void> deleteComplaint(String complaintId) async {
    final db = await database;
    await db.delete(
      'offline_complaints',
      where: 'id = ?',
      whereArgs: [complaintId],
    );
  }

  // Clear all
  Future<void> clear() async {
    final db = await database;
    await db.delete('offline_complaints');
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

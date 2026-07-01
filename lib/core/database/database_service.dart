import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be overridden in main.dart');
});

class DatabaseService {
  final Database? _db;

  DatabaseService(this._db);

  static Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'qasida_burda.db');

    return await openDatabase(
      pathString,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop and recreate all tables on schema version bump
        await db.execute('DROP TABLE IF EXISTS favorites');
        await db.execute('DROP TABLE IF EXISTS bookmarks');
        await db.execute('DROP TABLE IF EXISTS verses');
        await db.execute('DROP TABLE IF EXISTS chapters');
        await _createTables(db);
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    // Create chapters table
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY,
        chapter_number INTEGER NOT NULL,
        title_arabic TEXT NOT NULL,
        title_english TEXT NOT NULL,
        title_urdu TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Create verses table
    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        text_arabic TEXT NOT NULL,
        text_english TEXT NOT NULL,
        text_urdu TEXT NOT NULL,
        text_transliteration TEXT,
        FOREIGN KEY (chapter_number) REFERENCES chapters (chapter_number)
      )
    ''');

    // Create bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id INTEGER NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id INTEGER NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Database get database => _db!;

  Future<void> seedDatabase() async {
    if (_db == null) return; // Guard for testing
    // Check if chapters table is empty
    final count = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM chapters'));
    if (count == 0) {
      try {
        final jsonString = await rootBundle.loadString('assets/data/qasida_burda.json');
        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> chapters = data['chapters'];

        await database.transaction((txn) async {
          for (final ch in chapters) {
            final int chapterNumber = ch['chapter'] as int;
            final String? chapterDescription = ch['description'] as String?;

            // title is now an object with arabic, english and urdu fields
            final Map<String, dynamic> titleMap =
                ch['title'] as Map<String, dynamic>? ?? {};

            await txn.insert('chapters', {
              'chapter_number': chapterNumber,
              'title_arabic': titleMap['arabic'] as String? ?? '',
              'title_english': titleMap['english'] as String? ?? '',
              'title_urdu': titleMap['urdu'] as String? ?? '',
              'description': chapterDescription,
            });

            final List<dynamic> verses = ch['verses'] ?? [];
            for (final v in verses) {
              await txn.insert('verses', {
                'chapter_number': chapterNumber,
                'verse_number': v['verse'] as int,
                'text_arabic': v['arabic'] as String? ?? '',
                'text_english': v['english'] as String? ?? '',
                // Store 'singable' in the urdu column (no urdu in new data)
                'text_urdu': v['singable'] as String? ?? '',
                'text_transliteration': v['transliteration'] as String? ?? '',
              });
            }
          }
        });
      } catch (e) {
        debugPrint('Error seeding database: $e');
      }
    }
  }

  // Helper query methods will be added here
  Future<List<Map<String, dynamic>>> getChapters() async {
    return await database.query('chapters', orderBy: 'chapter_number');
  }

  Future<List<Map<String, dynamic>>> getVerses(int chapterNumber) async {
    return await database.query(
      'verses',
      where: 'chapter_number = ?',
      whereArgs: [chapterNumber],
      orderBy: 'verse_number',
    );
  }

  Future<List<Map<String, dynamic>>> getAllVerses() async {
    return await database.query('verses', orderBy: 'chapter_number, verse_number');
  }

  Future<int> insertBookmark(int verseId) async {
    return await database.insert(
      'bookmarks',
      {
        'verse_id': verseId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteBookmark(int verseId) async {
    return await database.delete(
      'bookmarks',
      where: 'verse_id = ?',
      whereArgs: [verseId],
    );
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    return await database.rawQuery('''
      SELECT verses.*, bookmarks.created_at
      FROM bookmarks
      INNER JOIN verses ON bookmarks.verse_id = verses.id
      ORDER BY bookmarks.created_at DESC
    ''');
  }
}

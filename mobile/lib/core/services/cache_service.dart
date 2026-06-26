import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CacheService {
  Database? _db;

  final List<Map<String, dynamic>> _webListings = [];
  final List<Map<String, dynamic>> _webFavorites = [];
  final List<Map<String, dynamic>> _webCategories = [];

  /// Normalise les listes issues de `.map(...).toList()` (souvent `List<dynamic>`).
  static List<Map<String, dynamic>> normalizeMaps(Iterable<dynamic> items) {
    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite indisponible sur le web');
    }
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'souk_tchad_cache.db'),
      version: 2,
      onCreate: (db, _) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_categories (
              id TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              cached_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE cached_listings (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_favorites (
        listing_id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cached_categories (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> cacheListings(Iterable<dynamic> listings) async {
    final rows = normalizeMaps(listings);
    if (kIsWeb) {
      _webListings
        ..clear()
        ..addAll(rows);
      return;
    }
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final listing in rows) {
      batch.insert(
        'cached_listings',
        {
          'id': listing['id'],
          'data': jsonEncode(listing),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedListings() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webListings);
    }
    final db = await database;
    final rows = await db.query(
      'cached_listings',
      orderBy: 'cached_at DESC',
      limit: 50,
    );
    return rows
        .map((r) => jsonDecode(r['data']! as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> cacheFavorites(Iterable<dynamic> favorites) async {
    final rows = normalizeMaps(favorites);
    if (kIsWeb) {
      _webFavorites
        ..clear()
        ..addAll(rows);
      return;
    }
    final db = await database;
    await db.delete('cached_favorites');
    final batch = db.batch();
    for (final fav in rows) {
      final listing = fav['listing'] as Map<String, dynamic>;
      batch.insert('cached_favorites', {
        'listing_id': listing['id'],
        'data': jsonEncode(fav),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheCategories(Iterable<dynamic> categories) async {
    final rows = normalizeMaps(categories);
    if (kIsWeb) {
      _webCategories
        ..clear()
        ..addAll(rows);
      return;
    }
    final db = await database;
    await db.delete('cached_categories');
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final category in rows) {
      batch.insert(
        'cached_categories',
        {
          'id': category['id'],
          'data': jsonEncode(category),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedCategories() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webCategories);
    }
    final db = await database;
    final rows = await db.query(
      'cached_categories',
      orderBy: 'cached_at DESC',
    );
    return rows
        .map((r) => jsonDecode(r['data']! as String) as Map<String, dynamic>)
        .toList();
  }

  /// Données liées au compte (favoris) — pas les annonces publiques.
  Future<void> clearUserData() async {
    if (kIsWeb) {
      _webFavorites.clear();
      return;
    }
    final db = await database;
    await db.delete('cached_favorites');
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      _webListings.clear();
      _webFavorites.clear();
      _webCategories.clear();
      return;
    }
    final db = await database;
    await db.delete('cached_listings');
    await db.delete('cached_favorites');
    await db.delete('cached_categories');
  }

  Future<List<Map<String, dynamic>>> getCachedFavorites() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webFavorites);
    }
    final db = await database;
    final rows = await db.query('cached_favorites');
    return rows
        .map((r) => jsonDecode(r['data']! as String) as Map<String, dynamic>)
        .toList();
  }
}

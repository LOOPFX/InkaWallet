import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

/// StorageService manages local data storage
/// Uses Hive for settings, SQLite for transactions, SharedPreferences for simple data
class StorageService {
  static late Box _settingsBox;
  static late SharedPreferences _prefs;
  static Database? _database;

  /// Initialize storage services
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox('settings');
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize SQLite database
    await _initDatabase();
  }

  /// Initialize SQLite database for offline transactions
  static Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'inkawallet.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create transactions table
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            wallet_id TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            recipient_name TEXT,
            recipient_phone TEXT,
            recipient_wallet_provider TEXT,
            sender_name TEXT,
            sender_phone TEXT,
            description TEXT,
            status TEXT NOT NULL,
            reference_number TEXT,
            created_at TEXT NOT NULL,
            completed_at TEXT,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Create cache table for API responses
        await db.execute('''
          CREATE TABLE cache (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            expiry INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // Settings Management

  /// Save setting
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Get setting
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  /// Check if inclusive mode is enabled
  static bool isInclusiveModeEnabled() {
    return getSetting(
      AppConstants.keyInclusiveModeEnabled,
      defaultValue: true, // Enabled by default
    );
  }

  /// Set inclusive mode
  static Future<void> setInclusiveMode(bool enabled) async {
    await saveSetting(AppConstants.keyInclusiveModeEnabled, enabled);
  }

  // SharedPreferences (Simple Key-Value Storage)

  /// Save string preference
  static Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Get string preference
  static String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Save boolean preference
  static Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Get boolean preference
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Check if first launch
  static bool isFirstLaunch() {
    return getBool(AppConstants.keyFirstLaunch) ?? true;
  }

  /// Set first launch completed
  static Future<void> setFirstLaunchCompleted() async {
    await saveBool(AppConstants.keyFirstLaunch, false);
  }

  // SQLite (Offline Transactions)

  /// Save transaction offline
  static Future<void> saveTransaction(Transaction transaction) async {
    if (_database == null) return;

    await _database!.insert(
      'transactions',
      {
        'id': transaction.id,
        'wallet_id': transaction.walletId,
        'type': transaction.type.name,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'recipient_name': transaction.recipientName,
        'recipient_phone': transaction.recipientPhone,
        'recipient_wallet_provider': transaction.recipientWalletProvider,
        'sender_name': transaction.senderName,
        'sender_phone': transaction.senderPhone,
        'description': transaction.description,
        'status': transaction.status.name,
        'reference_number': transaction.referenceNumber,
        'created_at': transaction.createdAt.toIso8601String(),
        'completed_at': transaction.completedAt?.toIso8601String(),
        'is_synced': transaction.isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all transactions
  static Future<List<Transaction>> getAllTransactions() async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromJson({
        ...maps[i],
        'is_synced': maps[i]['is_synced'] == 1,
      });
    });
  }

  /// Get unsynced transactions
  static Future<List<Transaction>> getUnsyncedTransactions() async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromJson({
        ...maps[i],
        'is_synced': false,
      });
    });
  }

  /// Mark transaction as synced
  static Future<void> markTransactionSynced(String transactionId) async {
    if (_database == null) return;

    await _database!.update(
      'transactions',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Delete synced transactions older than 30 days
  static Future<void> cleanupOldTransactions() async {
    if (_database == null) return;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    await _database!.delete(
      'transactions',
      where: 'is_synced = ? AND created_at < ?',
      whereArgs: [1, thirtyDaysAgo.toIso8601String()],
    );
  }

  // Cache Management

  /// Save to cache
  static Future<void> saveToCache(String key, String value, Duration expiry) async {
    if (_database == null) return;

    final expiryTime = DateTime.now().add(expiry).millisecondsSinceEpoch;

    await _database!.insert(
      'cache',
      {
        'key': key,
        'value': value,
        'expiry': expiryTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get from cache
  static Future<String?> getFromCache(String key) async {
    if (_database == null) return null;

    final List<Map<String, dynamic>> maps = await _database!.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;

    final expiry = maps[0]['expiry'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      // Cache expired
      await _database!.delete('cache', where: 'key = ?', whereArgs: [key]);
      return null;
    }

    return maps[0]['value'] as String;
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    if (_database == null) return;
    await _database!.delete('cache');
  }

  /// Clear all data (for logout)
  static Future<void> clearAll() async {
    await _settingsBox.clear();
    await _prefs.clear();
    if (_database != null) {
      await _database!.delete('transactions');
      await _database!.delete('cache');
    }
  }
}

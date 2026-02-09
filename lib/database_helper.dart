import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'carenest.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        avatar_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        message_type TEXT DEFAULT 'text',
        is_read INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id) REFERENCES users (id),
        FOREIGN KEY (receiver_id) REFERENCES users (id)
      )
    ''');

    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        activity_type TEXT NOT NULL,
        start_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP,
        location TEXT,
        max_participants INTEGER,
        created_by INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // Activity participants table
    await db.execute('''
      CREATE TABLE activity_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        status TEXT DEFAULT 'registered',
        registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (activity_id) REFERENCES activities (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(activity_id, user_id)
      )
    ''');

    // Health records table
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        health_type TEXT NOT NULL,
        value TEXT NOT NULL,
        unit TEXT,
        notes TEXT,
        recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        notification_type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Community posts table
    await db.execute('''
      CREATE TABLE community_posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        post_type TEXT DEFAULT 'general',
        likes_count INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Emergency alerts table
    await db.execute('''
      CREATE TABLE emergency_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        alert_type TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        resolved_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Sample users
    await db.insert('users', {
      'username': 'john_doe',
      'email': 'john@example.com',
      'password': 'password123',
      'full_name': 'John Doe',
    });

    await db.insert('users', {
      'username': 'jane_smith',
      'email': 'jane@example.com',
      'password': 'password123',
      'full_name': 'Jane Smith',
    });

    // Sample activities
    await db.insert('activities', {
      'title': 'Community Movie Night',
      'description': 'Join us for a fun movie night in the main hall',
      'activity_type': 'entertainment',
      'start_time': DateTime.now().add(Duration(days: 2)).toIso8601String(),
      'location': 'Main Hall',
      'max_participants': 50,
      'created_by': 1,
    });

    await db.insert('activities', {
      'title': 'Morning Yoga Session',
      'description': 'Start your day with gentle stretching and meditation',
      'activity_type': 'wellness',
      'start_time': DateTime.now().add(Duration(days: 1)).toIso8601String(),
      'location': 'Wellness Center',
      'max_participants': 20,
      'created_by': 2,
    });

    // Sample community posts
    await db.insert('community_posts', {
      'user_id': 1,
      'title': 'Welcome New Residents!',
      'content': 'Let\'s give a warm welcome to our new community members!',
      'post_type': 'announcement',
    });

    await db.insert('community_posts', {
      'user_id': 2,
      'title': 'Garden Club Meeting',
      'content': 'The garden club will meet this Thursday at 3 PM. All are welcome!',
      'post_type': 'event',
    });

    // Sample notifications
    await db.insert('notifications', {
      'user_id': 1,
      'title': 'Activity Reminder',
      'message': 'Don\'t forget about the movie night tomorrow!',
      'notification_type': 'reminder',
    });

    await db.insert('notifications', {
      'user_id': 2,
      'title': 'Health Check Reminder',
      'message': 'Your weekly health check is scheduled for tomorrow',
      'notification_type': 'health',
    });
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Message operations
  Future<List<Map<String, dynamic>>> getMessages(int userId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'receiver_id = ? OR sender_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> sendMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert('messages', message);
  }

  // Activity operations
  Future<List<Map<String, dynamic>>> getActivities() async {
    final db = await database;
    return await db.query(
      'activities',
      where: 'start_time >= ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'start_time ASC',
    );
  }

  Future<int> joinActivity(int activityId, int userId) async {
    final db = await database;
    return await db.insert('activity_participants', {
      'activity_id': activityId,
      'user_id': userId,
    });
  }

  // Notification operations
  Future<List<Map<String, dynamic>>> getNotifications(int userId) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markNotificationRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Community posts operations
  Future<List<Map<String, dynamic>>> getCommunityPosts() async {
    final db = await database;
    return await db.query(
      'community_posts',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> createPost(Map<String, dynamic> post) async {
    final db = await database;
    return await db.insert('community_posts', post);
  }

  // Emergency alert operations
  Future<int> createEmergencyAlert(Map<String, dynamic> alert) async {
    final db = await database;
    return await db.insert('emergency_alerts', alert);
  }

  Future<List<Map<String, dynamic>>> getActiveEmergencyAlerts() async {
    final db = await database;
    return await db.query(
      'emergency_alerts',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'created_at DESC',
    );
  }

  // Health records operations
  Future<List<Map<String, dynamic>>> getHealthRecords(int userId) async {
    final db = await database;
    return await db.query(
      'health_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'recorded_at DESC',
    );
  }

  Future<int> addHealthRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('health_records', record);
  }
}

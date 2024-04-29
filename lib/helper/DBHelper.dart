import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo.db');
    return await openDatabase(
      path,
      version: 10, // Increase the version number when changing the schema
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE tasks(id INTEGER PRIMARY KEY, task TEXT, checked INTEGER DEFAULT 0)",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 10) {
          // Add the 'checked' column if upgrading from version 1
          db.execute("ALTER TABLE tasks ADD COLUMN checked INTEGER DEFAULT 0");
        }
      },
    );
  }

  static Future<void> insertTask(String task, bool checked) async {
    final Database db = await database;
    await db.insert(
      'tasks',
      {'task': task, 'checked': checked ? 1 : 0}, // Convert bool to integer (1 for true, 0 for false)
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  static Future<List<String>> getTasks() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) {
      return maps[i]['task'];
    });
  }

  static Future<void> deleteTask(String task) async {
    final Database db = await database;
    await db.delete(
      'tasks',
      where: 'task = ?',
      whereArgs: [task],
    );
  }

  static Future<void> updateTask(String newTask, bool checked) async {
    final Database db = await database;
    await db.update(
      'tasks',
      {'task': newTask, 'checked': checked ? 1 : 0},
      where: 'task = ?',
      whereArgs: [newTask],
    );
  }

  static Future<bool?> getTaskCheckedStatus(String task) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'tasks',
      columns: ['checked'],
      where: 'task = ?',
      whereArgs: [task],
    );

    if (result.isNotEmpty) {
      return result.first['checked'] == 1; // Convert 1 to true, 0 to false
    } else {
      // Task not found, return null or handle as needed
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTaskRow(String task) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'tasks',
      where: 'task = ?',
      whereArgs: [task],
    );

    if (result.isNotEmpty) {
      return result.first; // Return the entire row
    } else {
      // Task not found, return null or handle as needed
      return null;
    }
  }

}


// class DBHelper {
//   static Database? _database;
//
//   static Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await initDatabase();
//     return _database!;
//   }
//
//   static Future<Database> initDatabase() async {
//     String path = join(await getDatabasesPath(), 'todo.db');
//     return await openDatabase(
//       path,
//       version: 2,
//       onCreate: (db, version) {
//         return db.execute(
//           "CREATE TABLE tasks(id INTEGER PRIMARY KEY, task TEXT)",
//         );
//       },
//     );
//   }
//
//   static Future<void> insertTask(String task) async {
//     final Database db = await database;
//     await db.insert(
//       'tasks',
//       {'task': task},
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   static Future<List<String>> getTasks() async {
//     final Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('tasks');
//     return List.generate(maps.length, (i) {
//       return maps[i]['task'];
//     });
//   }
//
//   static Future<void> deleteTask(String task) async {
//     final Database db = await database;
//     await db.delete(
//       'tasks',
//       where: 'task = ?',
//       whereArgs: [task],
//     );
//   }
// }

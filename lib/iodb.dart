import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import './ioif.dart';

class DataModel {
  final int id;
  final String name;
  final String data;
  final bool removed;
  int ts;

  DataModel(
      {this.id = null,
      this.name,
      this.data,
      this.removed = false,
      this.ts = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'data': data,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'removed': removed,
    };
  }

  DataModel fromMap(Map<String, dynamic> obj) {
    return DataModel(
        id: obj["id"],
        name: obj["name"],
        data: obj["data"],
        removed: obj["removed"],
        ts: obj["ts"]);
  }
}

class IoDB extends IoIf {
  Database db;

  void initialize() async {
    if (db == null) {
      db = await openDatabase(join(await getDatabasesPath(), 'workflow.db'),
          onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE data(id PRIMARY KEY INTEGER AUTOINCREMENT, name TEXT, data TEXT, ts INT, removed BOOL)");
      }, version: 1);
    }
  }

  IoDB() {}

  @override
  Future<List<String>> ls(String path) async {
    List<Map<String, dynamic>> res = await db.query('data',
        where: 'name LIKE "?%',
        whereArgs: [path],
        columns: ["name"],
        distinct: true);
    return res.map((f) => f["name"] as String);
  }

  @override
  Future<String> read(String name) async {
    List<Map<String, dynamic>> res = await db.query('data',
        where: 'name = ? AND removed = false',
        whereArgs: [name],
        orderBy: 'ts DESC',
        limit: 1);
    if (res.isEmpty) {
      throw new Error();
    }
    if (res.length == 1) {
      return res[0]["data"];
    }
    throw new Error();
  }

  @override
  Future write(String name, String content) async {
    var data = DataModel(name: name, data: content);
    return db.insert('data', data.toMap());
  }

  @override
  Future remove(String name) async {
    return db.update('data', {"removed": true},
        where: 'name = ?', whereArgs: [name]);
  }
}

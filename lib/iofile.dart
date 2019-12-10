import 'dart:io';

import 'package:path/path.dart';

import './ioif.dart';

class IoFile extends IoIf {
  Directory root;

  IoFile(String basedir) {
    root = Directory(basedir);
  }

  @override
  Future<List<String>> ls(String path) {
    var dir = new Directory(join(root.path, path));
    return dir.list().map((e) => basename(e.path)).toList();
  }

  @override
  Future<String> read(String name) {
    var out = new File(join(root.path, name));
    return out.readAsString();
  }

  @override
  Future write(String name, String content) {
    var out = new File(join(root.path, name));
    return out.writeAsString(content);
  }

  @override
  Future remove(String name) {
    return File(join(root.path, name)).delete();
  }
}

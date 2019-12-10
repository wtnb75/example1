import './convert.dart';

abstract class IoIf {
  Future<List<String>> ls(String path);

  Future<String> read(String name);

  Future write(String name, String content);

  Future remove(String name);

  Future<Map<String, dynamic>> readMap(String name) {
    return read(name).then((s) => yaml2obj(s));
  }

  Future writeMap(String name, Map<String, dynamic> obj) {
    return write(name, obj2yaml(obj));
  }
}

import 'dart:convert';

import 'package:yaml/yaml.dart';

dynamic yaml2obj(String node) {
  return jsonDecode(jsonEncode(loadYaml(node)));
}

String obj2yaml(dynamic node) {
  return loadYaml(jsonEncode(node)).toString();
}

dynamic yaml2obj_2(YamlNode node) {
  switch (node) {
    case YamlMap _:
      var res = <String, dynamic>{};
      for (var k in node.keys) {
        var ks = k as String;
        res[ks] = yaml2obj_2(node[ks]);
      }
      return res;
    case YamlList _:
      var res = <dynamic>[];
      for (var v in node) {
        res.add(yaml2obj_2(v));
      }
      return res;
    case YamlScalar _:
      return node.value;
  }
  return null;
}

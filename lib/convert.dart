import 'dart:convert';

import 'package:yaml/yaml.dart';

dynamic yaml2obj(String node) {
  return jsonDecode(jsonEncode(loadYaml(node)));
}

String obj2yaml(dynamic node) {
  return loadYaml(jsonEncode(node)).toString();
}

dynamic yaml2obj_2(YamlNode node) {
  switch (node.runtimeType) {
    case YamlMap:
      var res = Map<String, dynamic>();
      (node as YamlMap).keys.forEach((k) {
        var ks = k as String;
        res[ks] = yaml2obj_2((node as YamlMap)[ks]);
      });
      return res;
    case YamlList:
      var res = List<dynamic>();
      (node as YamlList).forEach((v) => res.add(yaml2obj_2(v)));
      return res;
    case YamlScalar:
      return node.value;
  }
  return null;
}

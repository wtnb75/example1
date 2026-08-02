import 'package:flutter/services.dart' show AssetBundle;
import 'package:logging/logging.dart';

import './convert.dart';
import './ioif.dart';

final log = Logger("ioresource");

class IoResource extends IoIf {
  AssetBundle? bundle;

  IoResource({this.bundle});

  @override
  Future<List<String>> ls(String path) {
    log.shout("loading $path/index.yaml");
    // Deliberately uses read()+yaml2obj() (dynamic) rather than readMap()
    // (Map<String, dynamic>): index.yaml's top level may genuinely be either
    // a Map or a List at runtime, and readMap()'s declared return type would
    // make the analyzer treat the Map branch below as statically guaranteed,
    // masking the real List case this method is written to also handle.
    return read("$path/index.yaml").then((s) => yaml2obj(s)).then((r) {
      log.shout("read: $r");
      if (r is Map) {
        var rmap = r as Map<String, dynamic>;
        if (rmap.keys.isNotEmpty) {
          var r2 = rmap[rmap.keys.first];
          if (r2 is List) {
            return r2.map((e) => e as String).toList();
          } else {
            throw Error();
          }
        }
      }
      if (r is List) {
        return r as List<String>;
      } else {
        throw Error();
      }
    });
  }

  @override
  Future<String> read(String name) {
    return bundle!.loadString(name);
  }

  @override
  Future write(String name, String content) {
    // not suppoorted
    throw Error();
  }

  @override
  Future remove(String name) {
    // not suppoorted
    throw Error();
  }
}

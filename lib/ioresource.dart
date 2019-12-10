import 'package:flutter/services.dart' show AssetBundle;
import 'package:logging/logging.dart';

import './ioif.dart';

final log = new Logger("ioresource");

class IoResource extends IoIf {
  AssetBundle bundle;

  IoResource({this.bundle});

  @override
  Future<List<String>> ls(String path) {
    log.shout("loading ${path}/index.yaml");
    return readMap("${path}/index.yaml").then((r) {
      log.shout("read: ${r}");
      if (r is Map) {
        var rmap = r as Map<String, dynamic>;
        if (rmap.keys.length != 0) {
          var r2 = rmap[rmap.keys.first];
          if (r2 is List) {
            return r2.map((e) => e as String).toList();
          } else {
            throw new Error();
          }
        }
      }
      if (r is List) {
        return r as List<String>;
      } else {
        throw new Error();
      }
    });
  }

  @override
  Future<String> read(String name) {
    return bundle.loadString(name);
  }

  @override
  Future write(String name, String content) {
    // not suppoorted
    throw new Error();
  }

  @override
  Future remove(String name) {
    // not suppoorted
    throw new Error();
  }
}

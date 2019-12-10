import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:example1/convert.dart';
import 'package:example1/data.dart';
import 'package:example1/iofile.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main(List<String> args) {
  var parser = new ArgParser();
  parser.addFlag('verbose', callback: (verbose) {
    if (verbose) {
      Logger.root.level = Level.ALL; // defaults to Level.INFO
      Logger.root.onRecord.listen((record) {
        print('${record.level.name}: ${record.time}: ${record.message}');
      });
    }
  });
  var result = parser.parse(args);
  log.shout("argument parsed: ${result}");
  test('yaml2obj', () {
    expect(yaml2obj("{}"), {});
    expect(yaml2obj("{a: 1}"), {"a": 1});
    expect(yaml2obj("{a: [1,2,3]}"), {
      "a": [1, 2, 3]
    });
  });
  test('obj2yaml', () {
    expect(obj2yaml({"a": 1}), "{a: 1}");
  });
  test('splittag', () {
    var input = """
    {
      "tasks": [{"type": "text", "descirption": "hello world 123 t123"}],
      "tags": ["world", "hel", "help321"]
    }
    """;
    var wf = WorkFlow(jsonDecode(input));
    var res = wf.tagger("hello world 123 help321");
    log.shout("${res}");
    expect(res[0].type, TextElementType.Tag);
    expect(res[0].value, "hel");
    expect(res[1].type, TextElementType.Text);
    expect(res[1].value, "lo ");
    expect(res[2].type, TextElementType.Tag);
    expect(res[2].value, "world");
    expect(res[3].type, TextElementType.Text);
    expect(res[3].value, " ");
    expect(res[4].type, TextElementType.Number);
    expect(res[4].value, "123");
    expect(res[5].type, TextElementType.Text);
    expect(res[5].value, " ");
    expect(res[6].type, TextElementType.Tag);
    expect(res[6].value, "help321");
    expect(res.length, 7);
  });
  test('iofile', () async {
    var db = IoFile(Directory.systemTemp.createTempSync("pfx").path);
    log.shout("tmpdir ${db.root}");
    await db.write("hello", "world");
    var world = await db.read("hello");
    expect(world, "world");
    await db.write("hello", "world2");
    var world2 = await db.read("hello");
    expect(world2, "world2");
    var ls = await db.ls(".");
    expect(ls, ["hello"]);
    await db.remove("hello");
    var ls2 = await db.ls(".");
    log.shout("ls result: ${ls2}");
    expect(ls2.isEmpty, true);
    log.shout("remove ${db.root}");
    await db.root.delete();
  });
  test('iofile-map', () async {
    var db = IoFile(Directory.systemTemp.createTempSync("pfx").path);
    log.shout("tmpdir ${db.root}");
    await db.writeMap("hello", {
      "a": true,
      "b": [1, 2, 3],
      "c": {"d": "e"}
    });
    var world = await db.readMap("hello");
    expect(world["a"], true);
    expect(world["b"], [1, 2, 3]);
    expect(world["c"], {"d": "e"});
    await db.remove("hello");
    await db.root.delete();
  });
  test('history', () {
    var hist = History();
    hist.fromMap({
      "name": "name",
      "data": [
        {"checked": false, "name": "hello"}
      ]
    });
    log.shout("history = ${jsonEncode(hist.toMap())}");
  });
}

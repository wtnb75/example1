import 'package:logging/logging.dart';

import './ioif.dart';

final log = new Logger("data");

class TaskIf {
  String type;
  String description;
  String note;

  TaskIf(Map<String, dynamic> obj) {
    fromMap(obj);
  }

  void fromMap(Map<String, dynamic> obj) {
    log.shout("fromMap: ${obj}");
    type = obj["type"];
    if (obj["description"] is List) {
      description = obj["description"].join("\n");
    } else {
      description = obj["description"];
    }
    if (obj["note"] is List) {
      note = obj["note"].join("\n");
    } else {
      note = obj["note"];
    }
  }

  Map<String, dynamic> toMap() {
    var res = Map<String, dynamic>();
    if (type != null) {
      res["type"] = type;
    }
    if (description != null) {
      res["description"] = description;
    }
    if (note != null) {
      res["note"] = note;
    }
    return res;
  }
}

class TaskText extends TaskIf {
  TaskText(Map<String, dynamic> obj) : super(obj);
}

class TaskNote extends TaskIf {
  TaskNote(Map<String, dynamic> obj) : super(obj);
}

class TaskUrl extends TaskIf {
  String url;

  TaskUrl(Map<String, dynamic> obj) : super(obj);

  void fromMap(Map<String, dynamic> obj) {
    super.fromMap(obj);
    url = obj["url"];
  }
}

class TaskWait extends TaskIf {
  Duration wait;

  TaskWait(Map<String, dynamic> obj) : super(obj) {
    fromMap(obj);
  }

  String duration2str() {
    if (wait == null) {
      return "(invalid)";
    }
    var sec = wait.inSeconds;
    var minval = (sec / 60).floor();
    var secval = (sec % 60).floor();
    if (secval == 0) {
      return "${minval} min";
    }
    return "${minval}:${secval.toString().padLeft(2, '0')}";
  }

  @override
  void fromMap(Map<String, dynamic> obj) {
    super.fromMap(obj);
    if (obj["wait"] is Duration) {
      log.shout("wait is duration: ${obj['wait']}");
      wait = obj["wait"];
    } else if (obj["wait"] is int) {
      log.shout("wait is int: ${obj['wait']}");
      wait = Duration(seconds: obj["wait"]);
    } else {
      log.shout("invalid wait type? ${obj['wait'].runtimeType}");
    }
  }

  @override
  Map<String, dynamic> toMap() {
    var res = super.toMap();
    res["wait"] = wait.inSeconds;
    return res;
  }
}

TaskIf genTask(Map<String, dynamic> obj) {
  switch (obj["type"]) {
    case "text":
      return TaskText(obj);
    case "note":
      return TaskNote(obj);
    case "wait":
      return TaskWait(obj);
    case "url":
      return TaskUrl(obj);
  }
  return TaskIf(obj);
}

enum TextElementType { Text, Tag, Number }

class TextElement {
  TextElementType type;
  String value;

  TextElement(this.type, this.value);

  String toString() {
    return "${value}(${type.toString().split(".")[1]})";
  }
}

class WorkFlow {
  String name;
  String description;
  String note;
  List<TaskIf> tasks;
  List<String> tags;

  WorkFlow(Map<String, dynamic> obj) {
    fromMap(obj);
  }

  void fromMap(Map<String, dynamic> obj) {
    name = obj["name"];
    description = obj["description"];
    note = obj["note"];
    tags = (obj["tags"] as List<dynamic>).cast<String>();
    tasks = List<TaskIf>();
    obj["tasks"].forEach((e) {
      tasks.add(genTask(e));
    });
  }

  Map<String, dynamic> toMap() {
    var res = Map<String, dynamic>();
    res["name"] = name;
    res["tags"] = tags;
    var tsks = List<Map<String, dynamic>>();
    tasks.forEach((f) => tsks.add(f.toMap()));
    res["tasks"] = tsks;
    return res;
  }

  List<TextElement> tagger(String descr) {
    var res = List<TextElement>();
    var tagset = Set.of(tags);
    var tg = tagset.toList();
    tg.sort((a, b) => b.length.compareTo(a.length));
    var desc = [descr];
    for (var t in tg) {
      log.shout("desc: ${desc}, tags: ${t}/${tags}");
      var res = <String>[];
      for (var d in desc) {
        if (tags.contains(d)) {
          log.shout("it is tag ${d}");
          res.add(d);
          continue;
        }
        var token = d.split(t);
        if (token.length == 1) {
          log.shout("not split: ${d}");
          res.add(d);
        } else {
          log.shout("split: token=${token}, t=${t}, d=${d}");
          res.add(token[0]);
          for (var i = 1; i < token.length; i++) {
            res.add(t);
            res.add(token[i]);
          }
        }
      }
      desc = res;
    }
    desc.removeWhere((s) => s == "");
    log.shout("split result: ${desc}");
    var numpat = new RegExp('[0-9]+');
    desc.forEach((txt) {
      if (tagset.contains(txt)) {
        log.shout("tag: ${txt}");
        res.add(TextElement(TextElementType.Tag, txt));
      } else {
        var matches = numpat.allMatches(txt);
        var cur = 0;
        matches.forEach((m) {
          if (m.start != cur) {
            res.add(
                TextElement(TextElementType.Text, txt.substring(cur, m.start)));
          }
          res.add(TextElement(TextElementType.Number, m.group(0)));
          cur = m.end;
        });
        res.add(TextElement(TextElementType.Text, txt.substring(cur)));
      }
    });
    return res;
  }
}

class HistoryElement {
  String name;
  bool checked;
  DateTime checkedAt;
  String note;

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "checked": checked,
      "checkedAt": checkedAt,
      "note": note,
    };
  }

  void fromMap(Map<String, dynamic> obj) {
    name = obj["name"];
    checked = obj["checked"];
    checkedAt = obj["checkedAt"];
    note = obj["note"];
  }
}

class History {
  String name;
  DateTime startedAt;
  DateTime finishedAt;
  List<HistoryElement> data;

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "startedAt": startedAt,
      "finishedAt": finishedAt,
      "data": data.map((e) => e.toMap()).toList(),
    };
  }

  void fromMap(Map<String, dynamic> obj) {
    name = obj["name"];
    startedAt = obj["startedAt"];
    finishedAt = obj["finishedAt"];
    data = List<HistoryElement>();
    obj["data"].forEach((e) {
      var r = HistoryElement();
      r.fromMap(e);
      data.add(r);
    });
  }
}

Future<WorkFlow> readWork(IoIf inp, String name) {
  log.shout("reading work ${name}");
  return inp.readMap(name).then((obj) => new WorkFlow(obj));
}

Future<List<String>> listWork(IoIf inp) {
  return inp.ls("workflow");
}

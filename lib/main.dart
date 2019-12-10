import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';

import './ioresource.dart';
import 'pages/actpage.dart';
import 'pages/checkpage.dart';
import 'pages/dopage.dart';
import 'pages/planpage.dart';

final log = new Logger("app");
final iomod = IoResource(bundle: rootBundle);

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.time} ${rec.loggerName} ${rec.level.name} ${rec.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

// TODO: remove from here (1)
abstract class TaskIf {
  String typeName;

  TaskIf(this.typeName);

  Widget planView(Set<String> tags);

  Widget workView(Set<String> tags);

  Map save() {
    return {"type": typeName};
  }
}

typedef Widget str2widget(String s);

class TextTask extends TaskIf {
  String description;
  bool _isChecked = false;

  TextTask(this.description) : super("text");

  List<Widget> fixtags(
      Set<String> tags, str2widget tagstyle, str2widget normalstyle) {
    var tg = tags.toList();
    tg.sort((a, b) => b.length.compareTo(a.length));
    log.shout("sorted by length: ${tg}");
    var desc = [description];
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
    List<Widget> rsp = [];
    desc.forEach((e) {
      if (tags.contains(e)) {
        rsp.add(tagstyle(e));
      } else {
        rsp.add(normalstyle(e));
      }
    });
    return rsp;
  }

  @override
  Widget planView(Set<String> tags) {
    return Wrap(
        children: fixtags(
            tags,
            (t) => Text(t, style: TextStyle(color: Colors.red, fontSize: 15.0)),
            (t) =>
                Text(t, style: TextStyle(color: Colors.blue, fontSize: 15.0))));
  }

  @override
  Widget workView(Set<String> tags) {
    return ListTile(
        leading:
            Icon(_isChecked ? Icons.check_box : Icons.check_box_outline_blank),
        title: planView(tags),
        onTap: () {
          log.shout("toggle ${_isChecked}");
          _isChecked = !_isChecked;
        });
  }

  @override
  Map save() {
    var res = super.save();
    res["description"] = description;
    return res;
  }
}

class WaitTask extends TaskIf {
  Duration duration;
  String description;

  WaitTask(this.duration, this.description) : super("wait");

  void start() {
    log.info("start sleep(${description}): ${duration}");
  }

  String duration2str(Duration d) {
    if (d.inHours != 0) {
      return "${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, "0")}:${d.inSeconds.remainder(60).toString().padLeft(2, "0")}";
    } else {
      return "${d.inMinutes.remainder(60).toString().padLeft(2, "0")}:${d.inSeconds.remainder(60).toString().padLeft(2, "0")}";
    }
  }

  @override
  Widget planView(Set<String> tags) {
    return RaisedButton(
        child: Text(description + "(" + duration2str(duration) + ")"),
        color: Colors.white,
        onPressed: () {
          start();
        },
        shape: StadiumBorder(side: BorderSide(color: Colors.green)));
  }

  @override
  Widget workView(Set<String> tags) {
    return planView(tags);
  }

  @override
  Map save() {
    var res = super.save();
    res["duration"] = duration.inSeconds;
    res["description"] = description;
    return res;
  }
}

TaskIf makeTask(Map<String, dynamic> obj) {
  log.info("making task: ${obj}");
  switch (obj["type"]) {
    case "wait":
      assert(obj["duration"] != null);
      assert(obj["description"] != null);
      return WaitTask(Duration(seconds: obj["duration"]), obj["description"]);
    case "text":
      assert(obj["description"] != null);
      return TextTask(obj["description"]);
  }
  throw new Error();
}

// TODO: remove to here (1)

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workflow Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AppPage(title: ""),
    );
  }
}

class AppPage extends StatelessWidget {
  final String title;

  AppPage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
              title: TabBar(tabs: [
            Tab(icon: Icon(Icons.edit), text: "Plan"),
            Tab(icon: Icon(Icons.work), text: "Do"),
            Tab(icon: Icon(Icons.check), text: "Check"),
            Tab(icon: Icon(Icons.rate_review), text: "Act"),
          ])),
          body: TabBarView(children: [
            PlanPageIndex(input: iomod),
            DoPageIndex(input: iomod),
            CheckPageIndex(input: iomod),
            ActPageIndex(input: iomod),
          ]),
        ));
  }
}

// TODO: remove from here (2)

class PlanPage extends StatefulWidget {
  PlanPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _PlanPageState createState() => _PlanPageState();
}

enum HomeState {
  InputTag,
  InputWork,
}

class _PlanPageState extends State<PlanPage> {
  HomeState state = HomeState.InputTag;
  List<TaskIf> tasks;
  Set<String> tags;
  TextEditingController _tagControl = TextEditingController();
  TextEditingController _workControl = TextEditingController();

  void insertToWork(String s) {
    if (!_workControl.selection.isValid) {
      _workControl.text = (_workControl.text.trim() + " " + s).trim();
    } else {
      var text = _workControl.text;
      var vals = [
        text.substring(0, _workControl.selection.start).trim(),
        s,
        text.substring(_workControl.selection.end).trim(),
      ];
      var offset = vals[0].length + s.length + 2;
      _workControl.text = vals.join(" ");
      _workControl.selection =
          TextSelection.fromPosition(TextPosition(offset: offset));
    }
  }

  void addTag(String s) {
    setState(() {
      tags.add(s);
    });
  }

  void addTask(String s) {
    setState(() {
      tasks.add(makeTask({"type": "text", "description": _workControl.text}));
    });
  }

  Map save() {
    Map<String, dynamic> res = {"type": "work"};
    res["tags"] = tags.toList();
    res["tasks"] = tasks.map((e) => e.save()).toList();
    return res;
  }

  Widget button(String txt, Function fn) {
    return RaisedButton(
        child: Text(txt),
        color: Colors.white,
        onPressed: () {
          fn(txt);
        },
        shape: StadiumBorder(side: BorderSide(color: Colors.green)));
  }

  Widget upper(BuildContext context) {
    var tg = tags.toList();
    tg.sort();
    return Wrap(
        spacing: 10.0,
        children: tg.map((e) => button(e, insertToWork)).toList());
  }

  Widget lower(BuildContext context) {
    return Expanded(
        child: ListView(
            children:
                tasks.map((e) => Card(child: e.planView(tags))).toList()));
  }

  Widget tagInput(BuildContext context) {
    return TextField(
      controller: _tagControl,
      decoration: InputDecoration(
          filled: true,
          prefixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _tagControl.clear();
            },
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              addTag(_tagControl.text);
              _tagControl.clear();
            },
          )),
    );
  }

  Widget workInput(BuildContext context) {
    return Expanded(
        child: TextField(
      keyboardType: TextInputType.multiline,
      maxLines: null,
      controller: _workControl,
      decoration: InputDecoration(
          filled: true,
          prefixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _workControl.clear();
            },
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              addTask(_workControl.text);
              _workControl.clear();
            },
          )),
    ));
  }

  Map<String, dynamic> workData;

  Future loadWorkData() {
    return iomod.readMap("data/index.yaml").then((index) {
      log.info("index ${index}");
      var wf = (index["workflow"] as List<dynamic>).map((e) => e as String);
      var rng = Random();
      var idx = rng.nextInt(wf.length);
      String basename = index["workflow"][idx];
      return iomod.readMap("data/$basename.yaml").then((wd) => workData = wd);
    });
  }

  @override
  Widget build(BuildContext context) {
    log.shout("tasks-type: ${workData['tasks'].runtimeType}");
    tasks = new List<TaskIf>();
    workData["tasks"]
        .forEach((e) => tasks.add(makeTask(e as Map<String, dynamic>)));
    tags = new Set<String>();
    workData["tags"].forEach((e) => tags.add(e as String));
    log.shout("tags: ${tags}");
    log.shout("tasks: ${tasks}");
    var children = <Widget>[];
    switch (state) {
      case HomeState.InputTag:
        children.addAll([
          upper(context),
          Padding(padding: EdgeInsets.all(2.0)),
          tagInput(context),
          Padding(padding: EdgeInsets.all(2.0)),
          lower(context),
        ]);
        break;
      case HomeState.InputWork:
        children.addAll([
          upper(context),
          Padding(padding: EdgeInsets.all(2.0)),
          workInput(context),
        ]);
        break;
    }
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
// TODO: remove to here (2)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../data.dart';
import '../ioif.dart';

final log = new Logger("dopage");

class WaitTimer extends StatefulWidget {
  final Duration duration;
  final Function onFinished;

  WaitTimer({this.duration, this.onFinished});

  @override
  State<StatefulWidget> createState() => _WaitTimerState(duration: duration);
}

class _WaitTimerState extends State<WaitTimer> {
  String _time = '';
  DateTime started;
  Duration duration;
  Timer tm;
  TextStyle style = normalStyle;
  static const TextStyle normalStyle = TextStyle(fontSize: 24);
  static const TextStyle stopStyle = TextStyle(fontSize: 24, color: Colors.red);

  _WaitTimerState({this.duration});

  void startTimer() {
    log.shout("startTimer");
    started = DateTime.now();
    tm = Timer.periodic(
      Duration(seconds: 1),
      _onTimer,
    );
    style = normalStyle;
  }

  void resetTimer() {
    log.shout("resetTimer");
    duration = widget.duration;
    style = normalStyle;
  }

  void stopTimer() {
    if (tm != null) {
      tm.cancel();
    }
    if (started != null) {
      duration = duration - DateTime.now().difference(started);
    }
    style = stopStyle;
    started = null;
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  String durationStr(Duration val) {
    var sec = val.inSeconds as int;
    var minval = (sec / 60).floor();
    var secval = (sec % 60).floor();
    if (secval == 0) {
      return "${minval} min";
    }
    return "${minval}:${secval.toString().padLeft(2, '0')}";
  }

  Duration restDuration() {
    var now = DateTime.now();
    return duration - now.difference(started);
  }

  void _onTimer(Timer timer) {
    var rest = restDuration();
    if (rest.isNegative) {
      timer.cancel();
      setState(() {
        _time = "finished";
        style = stopStyle;
      });
      if (widget.onFinished != null) {
        widget.onFinished();
      }
    } else {
      setState(() => _time = "${durationStr(rest)}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (started == null) {
      return GestureDetector(
        child: Text(durationStr(duration), style: style),
        onTap: () {
          setState(() {
            _time = durationStr(duration);
            startTimer();
          });
        },
        onLongPress: () {
          setState(() => resetTimer());
        },
      );
    } else {
      return GestureDetector(
        child: Text(_time, style: style),
        onTap: () {
          setState(() => stopTimer());
        },
        onLongPress: () {
          setState(() {
            stopTimer();
            resetTimer();
          });
        },
      );
    }
  }
}

class DoPageIndex extends StatefulWidget {
  final IoIf input;

  DoPageIndex({this.input}) {
    log.shout("input type: ${input.runtimeType}");
  }

  @override
  _DoPageIndexState createState() => _DoPageIndexState();
}

class _DoPageIndexState extends State<DoPageIndex> {
  List<String> names;

  @override
  void dispose() {
    super.dispose();
    log.shout("dispose ${this.runtimeType}");
  }

  void reload() async {
    log.shout("loading index");
    widget.input.ls("workflow").then((e) {
      if (mounted) {
        setState(() => names = e);
      }
    });
  }

  String fname2name(String fname) {
    if (fname.endsWith(".yaml") || fname.endsWith(".json")) {
      return fname.substring(0, fname.length - 5);
    }
    return fname;
  }

  Widget build1(BuildContext context, int index) {
    log.shout("build1 ${index} ${names[index]}");
    return FlatButton(
      color: Colors.blueGrey[200],
      child: Text(fname2name(names[index])),
      onPressed: () {
        log.shout("pushed ${index}: ${names[index]}");
        readWork(widget.input, "workflow/${names[index]}").then((work) {
          log.shout("navigate to ${work.name}");
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (c) => DoParent(flow: work)));
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (names == null) {
      reload();
      return Text("loading...");
    }
    log.shout("wrap");
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      direction: Axis.horizontal,
      children: new List.generate(names.length, (i) => build1(context, i)),
    );
  }
}

class DoParent extends StatelessWidget {
  final WorkFlow flow;

  DoParent({this.flow});

  @override
  Widget build(BuildContext context) {
    log.shout("doparent ${flow.name}");
    return Scaffold(
      appBar: AppBar(title: Text("${flow.name}")),
      body: DoPage(flow: flow),
    );
  }
}

class DoPage extends StatefulWidget {
  final WorkFlow flow;

  DoPage({this.flow});

  @override
  _DoPageState createState() => _DoPageState();
}

class _DoPageState extends State<DoPage> {
  void click(int idx, bool newstate) {
    log.shout("clicked: idx=${idx}, state=${newstate}");
    setState(() {
      flags[idx] = newstate;
    });
  }

  List<bool> flags;

  @override
  void initState() {
    if (flags == null) {
      flags = widget.flow.tasks.map((e) => false).toList();
    }
    super.initState();
  }

  Widget maketip(TaskIf task, Widget prep, Widget post) {
    List<Widget> res = <Widget>[];
    if (prep != null) {
      res.add(prep);
    }
    if (task.description != null) {
      res.add(Expanded(child: Text(task.description)));
    }
    if (post != null) {
      res.add(post);
    }
    if (task.note != null) {
      return Tooltip(message: task.note, child: Row(children: res));
    } else {
      return Row(children: res);
    }
  }

  Widget _makewidget(int idx, TaskIf task) {
    log.shout("task${idx} type=${task.type} ${task.runtimeType}");
    if (task is TaskText) {
      log.shout("text ${task.toMap()}");
      return maketip(
          task,
          Checkbox(
            value: flags[idx],
            onChanged: (flag) {
              click(idx, flag);
            },
          ),
          null);
    } else if (task is TaskNote) {
      log.shout("note: ${task.toMap()}");
      return maketip(task, null, null);
    } else if (task is TaskWait) {
      return maketip(
          task,
          Checkbox(
            value: flags[idx],
            onChanged: (flag) {
              click(idx, flag);
            },
          ),
          WaitTimer(
              duration: task.wait,
              onFinished: () {
                click(idx, true);
              }));
    } else if (task is TaskUrl) {
      return maketip(task, null, Text(task.url));
    }
    return Text("invalid task: ${task.runtimeType}, ${task.toMap()}");
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.flow.tasks.length,
        itemBuilder: (ctxt, i) {
          return _makewidget(i, widget.flow.tasks[i]);
        });
  }
}

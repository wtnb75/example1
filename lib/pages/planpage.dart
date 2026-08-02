import 'package:flutter/material.dart';

import '../data.dart';
import '../ioif.dart';

class PlanPageIndex extends StatefulWidget {
  final IoIf input;

  const PlanPageIndex({super.key, required this.input});

  @override
  State<PlanPageIndex> createState() => _PlanPageIndexState();
}

class _PlanPageIndexState extends State<PlanPageIndex> {
  List<String>? names;

  @override
  void dispose() {
    super.dispose();
    log.shout("dispose $runtimeType");
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
      log.shout("fname \"${fname.substring(0, fname.length - 5)}\"");
      return fname.substring(0, fname.length - 5);
    }
    return fname;
  }

  Widget build1(BuildContext context, int index) {
    return TextButton(
      style: TextButton.styleFrom(backgroundColor: Colors.blueGrey[200]),
      child: Text(fname2name(names![index])),
      onPressed: () {
        log.shout("pushed $index: ${names![index]}");
        readWork(widget.input, "workflow/${names![index]}").then((work) {
          log.shout("navigate to ${work.name}");
          if (!context.mounted) return;
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (c) => PlanParent(flow: work)));
        });
      },
    );
  }

  Widget buildAdd(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        log.shout("pushed");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (names == null) {
      reload();
      return const Text("loading...");
    }
    return Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        direction: Axis.horizontal,
        children: List.generate(names!.length + 2, (i) {
          if (i == 0 || i == names!.length + 1) {
            return buildAdd(context);
          } else {
            return build1(context, i - 1);
          }
        }));
  }
}

class PlanParent extends StatelessWidget {
  final WorkFlow flow;

  const PlanParent({super.key, required this.flow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${flow.name}")),
      body: PlanPageEach(parent: this),
    );
  }
}

class PlanPageEach extends StatefulWidget {
  final PlanParent parent;

  const PlanPageEach({super.key, required this.parent});

  @override
  State<PlanPageEach> createState() => _PlanPageEachState();
}

class _PlanPageEachState extends State<PlanPageEach> {
  late TextEditingController _namectrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _namectrl = TextEditingController(text: "${widget.parent.flow.name}");
  }

  String get name => _namectrl.text;

  @override
  void dispose() {
    _namectrl.dispose();
    super.dispose();
  }

  Widget buildForm(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: "name: "),
                controller: _namectrl,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter some text";
                  } else {
                    return null;
                  }
                },
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    child: const Text("Submit"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        log.shout("pressed submit $name");
                      }
                    },
                  ))
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return buildForm(context);
      } else {
        return buildForm(context);
      }
    });
  }
}

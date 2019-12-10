import 'package:flutter/material.dart';

import '../ioif.dart';

class ActPageIndex extends StatelessWidget {
  final IoIf input;

  ActPageIndex({this.input});

  @override
  Widget build(BuildContext context) {
    return Text("${this.runtimeType}");
  }
}

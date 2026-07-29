import 'package:flutter/material.dart';

import '../ioif.dart';

class ActPageIndex extends StatelessWidget {
  final IoIf input;

  ActPageIndex({required this.input});

  @override
  Widget build(BuildContext context) {
    return Text("${this.runtimeType}");
  }
}

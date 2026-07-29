import 'package:flutter/material.dart';

import '../ioif.dart';

class CheckPageIndex extends StatelessWidget {
  final IoIf input;

  CheckPageIndex({required this.input});

  @override
  Widget build(BuildContext context) {
    return Text("${this.runtimeType}");
  }
}

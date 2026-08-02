import 'package:flutter/material.dart';

import '../ioif.dart';

class ActPageIndex extends StatelessWidget {
  final IoIf input;

  const ActPageIndex({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    return Text("$runtimeType");
  }
}

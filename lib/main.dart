import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';

import './ioresource.dart';
import 'pages/actpage.dart';
import 'pages/checkpage.dart';
import 'pages/dopage.dart';
import 'pages/planpage.dart';

final log = Logger("app");
final iomod = IoResource(bundle: rootBundle);

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    developer.log(
      rec.message,
      time: rec.time,
      level: rec.level.value,
      name: rec.loggerName,
    );
  });
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workflow Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppPage(title: ""),
    );
  }
}

class AppPage extends StatelessWidget {
  final String title;

  const AppPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
              title: const TabBar(tabs: [
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

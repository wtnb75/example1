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
    print('${rec.time} ${rec.loggerName} ${rec.level.name} ${rec.message}');
  });
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

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

  AppPage({Key? key, required this.title}) : super(key: key);

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

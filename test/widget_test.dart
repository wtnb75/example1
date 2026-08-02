// Smoke tests for the top-level app shell.
//
// This is intentionally minimal: it just verifies that `MyApp` builds
// without error and that the four workflow-stage tabs (Plan/Do/Check/Act)
// defined in `AppPage` (lib/main.dart) are actually rendered. It replaces
// the stock `flutter create` counter-app template, which doesn't apply to
// this codebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example1/main.dart';

void main() {
  testWidgets('MyApp renders the Plan/Do/Check/Act tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Do'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('Act'), findsOneWidget);
  });

  testWidgets('AppPage wires up a DefaultTabController with 4 tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(controller.length, 4);
  });
}

import 'package:_02_week_2_declarative_ui_responsive_design/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard satu kolom di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AcademicOverviewApp());

    final width = tester.getSize(find.byType(Card).first).width;
    // lebar card di layar 400px dikurangi padding di bawah 400
    expect(width, lessThan(400));
  });

  testWidgets('Dashboard dua kolom di layar lebar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AcademicOverviewApp());

    final width = tester.getSize(find.byType(Card).first).width;
    // layar 1200 dibagi 2 kolom, lebar card lebih dari 500
    expect(width, greaterThan(500));
  });
}

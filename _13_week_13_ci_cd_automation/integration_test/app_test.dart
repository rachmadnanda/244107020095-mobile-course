import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:week_13_ci_cd_automation/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mulai dari database kosong agar hasil tidak bergantung pada data lama.
    final dbPath = p.join(await getDatabasesPath(), 'offline_notes.db');
    await databaseFactory.deleteDatabase(dbPath);
  });

  testWidgets('alur utama: tambah catatan, buka detail, lalu cari', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    final title = 'Catatan integrasi ${DateTime.now().millisecondsSinceEpoch}';
    const body = 'Isi catatan dari integration test';

    await tester.tap(find.byKey(const Key('add-note-fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('note-title-field')), title);
    await tester.enterText(find.byKey(const Key('note-body-field')), body);
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);

    await tester.tap(find.text(title));
    await tester.pumpAndSettle();

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(find.text(body), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('note-search-field')),
      'integrasi',
    );
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);
  });
}

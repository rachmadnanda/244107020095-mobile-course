// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_4_networking_rest_api/data/models/post.dart';
import 'package:week_4_networking_rest_api/data/providers.dart';
import 'package:week_4_networking_rest_api/data/repositories/post_repository.dart';
import 'package:week_4_networking_rest_api/main.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository() : super(Dio());

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    return const [];
  }
}

void main() {
  testWidgets('aplikasi menampilkan halaman posts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Posts Paged'), findsOneWidget);
  });
}

import 'package:_04_week_4_networking_rest_api/data/comment_provider.dart';
import 'package:_04_week_4_networking_rest_api/data/models/comment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Comment.fromJson aman terhadap field yang hilang', () {
    final comment = Comment.fromJson({'id': 10});

    expect(comment.id, 10);
    expect(comment.postId, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson aman terhadap nilai null', () {
    final comment = Comment.fromJson({
      'postId': null,
      'id': null,
      'name': null,
      'email': null,
      'body': null,
    });

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('friendlyCommentErrorMessage untuk timeout', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/comments'),
      type: DioExceptionType.receiveTimeout,
    );

    expect(friendlyCommentErrorMessage(error), contains('timeout'));
  });

  test('friendlyCommentErrorMessage untuk 404', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/comments'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/comments'),
        statusCode: 404,
      ),
    );

    expect(friendlyCommentErrorMessage(error), contains('404'));
  });

  test('friendlyCommentErrorMessage untuk 500', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/comments'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/comments'),
        statusCode: 500,
      ),
    );

    expect(friendlyCommentErrorMessage(error), contains('500'));
  });
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/features/services/content_binary_uploader.dart';

void main() {
  test('streams the exact binary to a protected PUT grant', () async {
    late http.Request captured;
    final progress = <double>[];
    final uploader = ContentBinaryUploader(
      clientFactory: () => MockClient((request) async {
        captured = request;
        return http.Response('', 200);
      }),
    );

    await uploader.put(
      url: 'https://storage.example.test/upload?signature=secret',
      contentType: 'application/pdf',
      expectedBytes: 6,
      openRead: () => Stream.fromIterable(const [
        <int>[1, 2],
        <int>[3, 4, 5, 6],
      ]),
      onProgress: progress.add,
    );

    expect(captured.method, 'PUT');
    expect(captured.headers['content-type'], 'application/pdf');
    expect(captured.bodyBytes, <int>[1, 2, 3, 4, 5, 6]);
    expect(progress.last, 1);
  });

  test(
    'rejects a non-HTTPS remote upload grant before opening the file',
    () async {
      var opened = false;
      final uploader = ContentBinaryUploader(
        clientFactory: () => MockClient((_) async => http.Response('', 200)),
      );

      await expectLater(
        uploader.put(
          url: 'http://storage.example.test/upload',
          contentType: 'application/pdf',
          expectedBytes: 1,
          openRead: () {
            opened = true;
            return Stream.value(utf8.encode('x'));
          },
        ),
        throwsA(isA<ContentUploadException>()),
      );
      expect(opened, isFalse);
    },
  );

  test('rejects a payload whose bytes changed after grant creation', () async {
    final uploader = ContentBinaryUploader(
      clientFactory: () => MockClient((_) async => http.Response('', 200)),
    );

    await expectLater(
      uploader.put(
        url: 'https://storage.example.test/upload',
        contentType: 'application/pdf',
        expectedBytes: 2,
        openRead: () => Stream.value(const <int>[1, 2, 3]),
      ),
      throwsA(isA<ContentUploadException>()),
    );
  });
}

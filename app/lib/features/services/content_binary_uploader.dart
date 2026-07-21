import 'dart:async';

import 'package:http/http.dart' as http;

/// Streams one content file directly to a short-lived backend upload grant.
///
/// The payload is never buffered in full, the granted host is validated before
/// a byte leaves the device, and the exact size declared to the backend is
/// enforced while streaming. The authenticated API confirms the file only
/// after this method returns successfully.
final class ContentBinaryUploader {
  ContentBinaryUploader({http.Client Function()? clientFactory})
    : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;

  Future<void> put({
    required String url,
    required String contentType,
    required int expectedBytes,
    required Stream<List<int>> Function() openRead,
    void Function(double value)? onProgress,
  }) async {
    if (expectedBytes <= 0) {
      throw const ContentUploadException('The selected file is empty.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ContentUploadException('The upload link is invalid.');
    }
    final loopback =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) {
      throw const ContentUploadException(
        'The upload link is not protected by HTTPS.',
      );
    }
    if (contentType.trim().isEmpty ||
        contentType.contains('\r') ||
        contentType.contains('\n')) {
      throw const ContentUploadException('The file type is invalid.');
    }

    final client = _clientFactory();
    try {
      final request = http.StreamedRequest('PUT', uri)
        ..contentLength = expectedBytes
        ..headers['content-type'] = contentType;
      var transferred = 0;

      Future<void> streamPayload() async {
        Object? failure;
        StackTrace? failureStack;
        try {
          await for (final chunk in openRead().timeout(
            const Duration(minutes: 5),
          )) {
            transferred += chunk.length;
            if (transferred > expectedBytes) {
              throw const ContentUploadException(
                'The selected file changed while it was being uploaded.',
              );
            }
            request.sink.add(chunk);
            onProgress?.call(transferred / expectedBytes);
          }
          if (transferred != expectedBytes) {
            throw const ContentUploadException(
              'The selected file changed while it was being uploaded.',
            );
          }
        } on Object catch (error, stack) {
          failure = error;
          failureStack = stack;
        }
        try {
          // Always terminate the HTTP body. Leaving the sink open after a file
          // read error strands the socket and can keep a failed upload alive.
          await request.sink.close();
        } on Object catch (error, stack) {
          failure ??= error;
          failureStack ??= stack;
        }
        if (failure != null) {
          Error.throwWithStackTrace(failure, failureStack!);
        }
      }

      final responseFuture = client
          .send(request)
          .timeout(const Duration(minutes: 5));
      // Attach listeners to transfer and response immediately. This prevents a
      // body failure from leaving an unobserved response future behind.
      final completed = await Future.wait<dynamic>([
        responseFuture,
        streamPayload(),
      ], eagerError: false);
      final response = completed.first as http.StreamedResponse;
      await response.stream.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ContentUploadException(
          'Storage rejected the upload (${response.statusCode}).',
        );
      }
      onProgress?.call(1);
    } on TimeoutException {
      throw const ContentUploadException(
        'The upload took too long. Check your connection and try again.',
      );
    } finally {
      client.close();
    }
  }
}

final class ContentUploadException implements Exception {
  const ContentUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

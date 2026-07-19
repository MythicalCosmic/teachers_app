import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release Android manifest allows production API traffic', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      RegExp(
        r'<uses-permission\s+android:name="android\.permission\.INTERNET"\s*/>',
      ).allMatches(manifest),
      hasLength(1),
    );
    expect(
      RegExp(
        r'<uses-permission\s+android:name="android\.permission\.RECORD_AUDIO"\s*/>',
      ).allMatches(manifest),
      hasLength(1),
    );
  });

  test('iOS declares privacy reasons for messaging media', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    for (final key in <String>[
      'NSCameraUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSPhotoLibraryUsageDescription',
    ]) {
      expect(infoPlist, contains('<key>$key</key>'));
    }

    expect(infoPlist, contains('staff conversation'));
    expect(infoPlist, contains('voice message'));
  });
}

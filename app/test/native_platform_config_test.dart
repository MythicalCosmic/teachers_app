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
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('starforge_messages'));
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });

  test('iOS native plugins are integrated through CocoaPods', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    final debugConfig = File('ios/Flutter/Debug.xcconfig').readAsStringSync();
    final releaseConfig = File(
      'ios/Flutter/Release.xcconfig',
    ).readAsStringSync();

    expect(podfile, contains("platform :ios, '15.0'"));
    expect(podfile, contains('flutter_ios_podfile_setup'));
    expect(podfile, contains('flutter_install_all_ios_pods'));
    expect(podfile, contains('flutter_additional_ios_build_settings'));
    expect(debugConfig, contains('Pods-Runner.debug.xcconfig'));
    expect(releaseConfig, contains('Pods-Runner.release.xcconfig'));
    expect(debugConfig, contains('#include "Generated.xcconfig"'));
    expect(releaseConfig, contains('#include "Generated.xcconfig"'));
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
    expect(infoPlist, contains('<string>fetch</string>'));
    expect(infoPlist, contains('<string>remote-notification</string>'));
  });

  test(
    'push credentials remain external and iOS entitlement is profile driven',
    () {
      final appGradle = File('android/app/build.gradle.kts').readAsStringSync();
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final entitlements = File(
        'ios/Runner/PushNotifications.entitlements',
      ).readAsStringSync();

      expect(appGradle, contains('file("google-services.json").isFile'));
      expect(project, contains(r'$(STARFORGE_PUSH_ENTITLEMENTS)'));
      expect(entitlements, contains(r'$(APS_ENVIRONMENT)'));
      final ignore = File('.gitignore').readAsStringSync();
      expect(ignore, contains('/android/app/google-services.json'));
      expect(ignore, contains('/ios/Runner/GoogleService-Info.plist'));
    },
  );
}

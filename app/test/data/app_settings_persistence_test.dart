import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';

void main() {
  group('AppSettings JSON persistence and migration', () {
    test('English and every appearance control survive a JSON round trip', () {
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        palette: AppPalette.samarqand,
        locale: AppLocale.en,
        visualStyle: AppVisualStyle.maximalism,
        fontChoice: AppFontChoice.editorial,
        layoutDensity: AppLayoutDensity.spacious,
        surfaceOpacity: 0.63,
        navigationOpacity: 0.57,
        motionIntensity: 1.25,
      );

      final restored = AppSettings.fromJson(settings.toJson());

      expect(restored.themeMode, AppThemeMode.dark);
      expect(restored.palette, AppPalette.samarqand);
      expect(restored.locale, AppLocale.en);
      expect(restored.visualStyle, AppVisualStyle.maximalism);
      expect(restored.fontChoice, AppFontChoice.editorial);
      expect(restored.layoutDensity, AppLayoutDensity.spacious);
      expect(restored.surfaceOpacity, 0.63);
      expect(restored.navigationOpacity, 0.57);
      expect(restored.motionIntensity, 1.25);
    });

    test(
      'legacy settings without customization fields migrate to defaults',
      () {
        final migrated = AppSettings.fromJson({
          'themeMode': 'system',
          'palette': 'saroy',
          'locale': 'ru',
          'liquidGlass': false,
        });

        expect(migrated.themeMode, AppThemeMode.system);
        expect(migrated.palette, AppPalette.saroy);
        expect(migrated.locale, AppLocale.ru);
        expect(migrated.liquidGlass, isFalse);
        expect(migrated.visualStyle, AppVisualStyle.classic);
        expect(migrated.fontChoice, AppFontChoice.manrope);
        expect(migrated.layoutDensity, AppLayoutDensity.comfortable);
        expect(migrated.surfaceOpacity, 1);
        expect(migrated.navigationOpacity, 0.78);
        expect(migrated.motionIntensity, 1);
      },
    );

    test('unknown enum values and unsafe numeric values migrate safely', () {
      final migrated = AppSettings.fromJson({
        'locale': 'unsupported-locale',
        'visualStyle': 'future-style',
        'fontChoice': 'future-font',
        'layoutDensity': 'future-density',
        'surfaceOpacity': 0.1,
        'navigationOpacity': 4,
        'motionIntensity': 9,
      });

      expect(migrated.locale, AppLocale.uz);
      expect(migrated.visualStyle, AppVisualStyle.classic);
      expect(migrated.fontChoice, AppFontChoice.manrope);
      expect(migrated.layoutDensity, AppLayoutDensity.comfortable);
      expect(migrated.surfaceOpacity, 0.45);
      expect(migrated.navigationOpacity, 1);
      expect(migrated.motionIntensity, 1.35);
    });

    test(
      'AppState setters persist English and customization across restart',
      () async {
        final storage = MemoryAppStorage();
        final state = await AppState.bootstrap(storage: storage);

        await state.setLocale(AppLocale.en);
        await state.setVisualStyle(AppVisualStyle.liquidGlass);
        await state.setFontChoice(AppFontChoice.system);
        await state.setLayoutDensity(AppLayoutDensity.compact);
        await state.setSurfaceOpacity(0.71);
        await state.setNavigationOpacity(0.66);
        await state.setMotionIntensity(0.8);

        final restored = await AppState.bootstrap(storage: storage);
        expect(restored.settings.locale, AppLocale.en);
        expect(restored.settings.visualStyle, AppVisualStyle.liquidGlass);
        expect(restored.settings.fontChoice, AppFontChoice.system);
        expect(restored.settings.layoutDensity, AppLayoutDensity.compact);
        expect(restored.settings.surfaceOpacity, 0.71);
        expect(restored.settings.navigationOpacity, 0.66);
        expect(restored.settings.motionIntensity, 0.8);
      },
    );
  });

  test('extended staff profile fields persist across restart', () async {
    final storage = MemoryAppStorage();
    final state = await AppState.bootstrap(storage: storage);
    await state.signIn(username: 'nigora.karimova', password: 'demo2026');

    await state.updateProfile(
      displayName: 'Nigora Karimova',
      email: 'nigora@starforge.uz',
      username: 'nigora.staff',
      phone: '+998 90 123 45 67',
      bio: 'English language mentor',
      avatarColorValue: const Color(0xFF346D91).toARGB32(),
    );

    final restored = await AppState.bootstrap(storage: storage);
    expect(restored.session?.username, 'nigora.staff');
    expect(restored.session?.phone, '+998 90 123 45 67');
    expect(restored.session?.bio, 'English language mentor');
    expect(
      restored.session?.avatarColorValue,
      const Color(0xFF346D91).toARGB32(),
    );
  });
}

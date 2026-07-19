/// Compile-time production configuration.
///
/// Override either value in CI with `--dart-define`. The platform URL is the
/// public tenant-discovery host; authenticated traffic always uses the tenant
/// URL returned by `/api/v1/platform/resolve/`.
abstract final class ApiConfig {
  static const platformBaseUrl = String.fromEnvironment(
    'STARFORGE_PLATFORM_URL',
    defaultValue: 'https://starforge.78.111.91.113.nip.io',
  );

  static const defaultCenterSlug = String.fromEnvironment(
    'STARFORGE_CENTER_SLUG',
    defaultValue: '',
  );

  static const requestTimeout = Duration(seconds: 18);
}

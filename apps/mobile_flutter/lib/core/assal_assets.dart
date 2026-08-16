/// Runtime asset contract for the customer Web/APK application.
/// Keep paths centralized so a platform build cannot silently drift from the
/// audited project assets.
abstract final class AssalAssets {
  static const logoInternal = 'assets/logo-internal-runtime.svg';
  static const logoExternal = 'assets/logo-external-runtime.svg';
  static const demoCatalog = 'assets/demo_catalog.json';
  static const fontFamily = 'IBM Plex Sans Arabic';
}

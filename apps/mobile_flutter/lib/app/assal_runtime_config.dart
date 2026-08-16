class AssalRuntimeConfig {
  const AssalRuntimeConfig({required this.mode, required this.supabaseUrl, required this.supabasePublishableKey, this.androidRedirect = 'com.assalkom.assalkom://login-callback/'});

  final String mode;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String androidRedirect;

  factory AssalRuntimeConfig.fromEnvironment() => const AssalRuntimeConfig(
        mode: String.fromEnvironment('ASSALKOM_MODE', defaultValue: 'demo'),
        supabaseUrl: String.fromEnvironment('ASSALKOM_SUPABASE_URL'),
        supabasePublishableKey: String.fromEnvironment('ASSALKOM_SUPABASE_PUBLISHABLE_KEY'),
        androidRedirect: String.fromEnvironment('ASSALKOM_ANDROID_REDIRECT', defaultValue: 'com.assalkom.assalkom://login-callback/'),
      );

  bool get isProduction => mode == 'production';
  bool get isConfigured => supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}

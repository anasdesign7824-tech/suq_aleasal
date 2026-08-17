class AssalRuntimeConfig {
  const AssalRuntimeConfig(
      {required this.mode,
      required this.supabaseUrl,
      required this.supabasePublishableKey});

  final String mode;
  final String supabaseUrl;
  final String supabasePublishableKey;

  factory AssalRuntimeConfig.fromEnvironment() => const AssalRuntimeConfig(
        mode: String.fromEnvironment('ASSALKOM_MODE', defaultValue: 'demo'),
        supabaseUrl: String.fromEnvironment('ASSALKOM_SUPABASE_URL'),
        supabasePublishableKey:
            String.fromEnvironment('ASSALKOM_SUPABASE_PUBLISHABLE_KEY'),
      );

  bool get isProduction => mode == 'production';
  bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}

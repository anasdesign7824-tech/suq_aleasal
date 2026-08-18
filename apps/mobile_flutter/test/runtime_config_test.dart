import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/app/assal_runtime_config.dart';

void main() {
  test('unconfigured runtime never reports demo implicitly', () {
    const config = AssalRuntimeConfig(
      mode: 'unconfigured',
      supabaseUrl: '',
      supabasePublishableKey: '',
    );

    expect(config.isDemo, isFalse);
    expect(config.isProduction, isFalse);
    expect(config.isConfigured, isFalse);
  });

  test('production runtime requires a valid publishable Supabase key', () {
    const invalid = AssalRuntimeConfig(
      mode: 'production',
      supabaseUrl: 'https://gvalqfgxrkibuydoiuiz.supabase.co',
      supabasePublishableKey: 'anon-key',
    );
    const valid = AssalRuntimeConfig(
      mode: 'production',
      supabaseUrl: 'https://gvalqfgxrkibuydoiuiz.supabase.co',
      supabasePublishableKey: 'sb_publishable_test-key',
    );

    expect(invalid.isConfigured, isFalse);
    expect(valid.isConfigured, isTrue);
  });
}

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/assal_app.dart';
import 'app/assal_runtime_config.dart';
import 'core/supabase_auth_gateway.dart';
import 'core/supabase_query_gateway.dart';
import 'package:assalkom_data/production_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AssalRuntimeConfig.fromEnvironment();

  if (!config.isProduction) {
    runApp(const AssalApp());
    return;
  }

  if (!config.isConfigured) {
    runApp(const AssalApp(
        startupError:
            'شغّل نسخة Production مع ASSALKOM_SUPABASE_URL وASSALKOM_SUPABASE_PUBLISHABLE_KEY وASSALKOM_MODE=production.'));
    return;
  }

  try {
    await Supabase.initialize(
        url: config.supabaseUrl, publishableKey: config.supabasePublishableKey);
    final client = Supabase.instance.client;
    final repository = ProductionRepository(
      gateway: SupabaseQueryGateway(client),
      authGateway: SupabaseAuthGateway(
          client: client, emailRedirectTo: config.supabaseUrl),
    );
    runApp(AssalApp(repository: repository));
  } on Object catch (error) {
    runApp(AssalApp(
        startupError:
            'تعذر تهيئة Supabase. راجع عنوان المشروع والمفتاح العام وإعدادات Auth.\n$error'));
  }
}

import 'package:flutter/material.dart';
import 'package:assalkom_data/assal_repository.dart';
import '../../core/assal_widgets.dart';
import 'customer_account.dart';

Future<bool> openAuth(BuildContext context, AssalRepository repository) async {
  final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AuthScreen(repository: repository)));
  return result == true;
}

Future<bool> requireAuth(
    BuildContext context, AssalRepository repository) async {
  final session = await repository.getSession();
  if (session.isAuthenticated) return true;
  if (!context.mounted) return false;
  final wantsLogin = await showAuthPrompt(context);
  if (wantsLogin && context.mounted) await openAuth(context, repository);
  return (await repository.getSession()).isAuthenticated;
}

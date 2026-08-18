import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import '../../core/assal_widgets.dart';
import 'customer_account.dart';

Future<bool> openAuth(BuildContext context, AssalRepository repository) async {
  final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AuthScreen(repository: repository)));
  return result == true;
}

Future<AssalSession?> requireUserSession(
    BuildContext context, AssalRepository repository) async {
  var session = await repository.getSession();
  if (session.isAuthenticated && session.user != null) return session;
  if (!context.mounted) return null;
  final wantsLogin = await showAuthPrompt(context);
  if (wantsLogin && context.mounted) await openAuth(context, repository);
  session = await repository.getSession();
  return session.isAuthenticated && session.user != null ? session : null;
}

Future<bool> requireAuth(
    BuildContext context, AssalRepository repository) async =>
    await requireUserSession(context, repository) != null;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';

const _profile = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'محمد اليمني',
  email: 'mohammed@example.com',
  phone: '+967700000000',
  location: 'إب، اليمن',
  bio: 'نبذة قديمة',
);

Future<void> _pumpEditor(
  WidgetTester tester,
  _EditorRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ProfileEditorScreen(repository: repository, profile: _profile),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 032 renders the profile editor contract', (tester) async {
    await _pumpEditor(tester, _EditorRepository());

    expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
    expect(find.bySemanticsLabel('صورة الغلاف'), findsOneWidget);
    expect(find.bySemanticsLabel('الصورة الشخصية'), findsOneWidget);
    expect(find.text('الاسم العربي'), findsOneWidget);
    expect(find.text('النبذة التعريفية'), findsOneWidget);
    expect(find.text('الهاتف'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    expect(find.text('حفظ التغييرات'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('محمد اليمني'), findsOneWidget);
  });

  testWidgets('TASK 032 sends trimmed editable fields through the repository',
      (tester) async {
    final repository = _EditorRepository();
    await _pumpEditor(tester, repository);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  أحمد عسلكم  ');
    await tester.enterText(fields.at(1), '  نبذة جديدة  ');
    await tester.enterText(fields.at(2), '  +967711111111  ');
    await tester.enterText(fields.at(3), '  صنعاء، حدة  ');
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.updatedUserId, 'customer-1');
    expect(repository.patch?.nameAr, 'أحمد عسلكم');
    expect(repository.patch?.bio, 'نبذة جديدة');
    expect(repository.patch?.phone, '+967711111111');
    expect(repository.patch?.locationLabel, 'صنعاء، حدة');
  });

  testWidgets('TASK 032 blocks save when the required name is empty',
      (tester) async {
    final repository = _EditorRepository();
    await _pumpEditor(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pump();

    expect(repository.updateCalls, 0);
    expect(find.text('أدخل الاسم العربي'), findsOneWidget);
  });

  testWidgets('TASK 032 exposes an explicit cancel action', (tester) async {
    await _pumpEditor(tester, _EditorRepository());
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditorScreen), findsNothing);
  });

  testWidgets('TASK 032 records the visual contract', (tester) async {
    await _pumpEditor(tester, _EditorRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProfileEditorScreen),
      matchesGoldenFile(
        'visual_reference/task032_profile_editor_reference_360x780.png',
      ),
    );
  });
}

class _EditorRepository implements AssalRepository {
  int updateCalls = 0;
  String? updatedUserId;
  AssalUserProfilePatch? patch;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async =>
      const AssalSession(isAuthenticated: true, role: AssalRole.customer);

  @override
  Future<AssalLoadState<void>> updateUserProfile(
    String userId,
    AssalUserProfilePatch value,
  ) async {
    updateCalls++;
    updatedUserId = userId;
    patch = value;
    return const AssalData<void>(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

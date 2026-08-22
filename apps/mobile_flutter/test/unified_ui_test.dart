import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/core/assal_widgets.dart';

void main() {
  testWidgets('shared app bar reserves space for tab navigation', (tester) async {
    const bar = AssalAppBar(
      title: 'المحفوظات والمتابعات',
      bottom: TabBar(
        tabs: [
          Tab(text: 'منتجات محفوظة'),
          Tab(text: 'متاجر متابَعة'),
        ],
      ),
    );

    expect(bar.preferredSize.height, greaterThan(kToolbarHeight));
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: bar,
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('منتجات محفوظة'), findsOneWidget);
    expect(find.text('متاجر متابَعة'), findsOneWidget);
  });

  testWidgets('image picker tile invokes the action from its in-place icon',
      (tester) async {
    var picked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssalImagePickerTile(
            onPick: () => picked = true,
            label: 'إضافة صورة المتجر',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('إضافة صورة المتجر'), findsOneWidget);
    await tester.tap(find.byTooltip('إضافة الصورة'));
    expect(picked, isTrue);
  });

  testWidgets('large upload slot uses the same in-place image action',
      (tester) async {
    var picked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssalImageUploadSlot(
            label: 'غلاف المتجر',
            icon: Icons.storefront_outlined,
            imageUrl: null,
            bytes: null,
            onPick: () => picked = true,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('غلاف المتجر'), findsOneWidget);
    await tester.tap(find.byTooltip('إضافة الصورة'));
    expect(picked, isTrue);
  });

  testWidgets('image picker tile previews, replaces, and clears an image',
      (tester) async {
    var picked = 0;
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssalImagePickerTile(
            bytes: _onePixelPng,
            onPick: () => picked++,
            onClear: () => cleared = true,
            label: 'صورة المنتج',
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byTooltip('تغيير الصورة'), findsOneWidget);
    expect(find.byTooltip('إزالة الصورة'), findsOneWidget);
    await tester.tap(find.byTooltip('تغيير الصورة'));
    await tester.tap(find.byTooltip('إزالة الصورة'));
    expect(picked, 1);
    expect(cleared, isTrue);
  });

  testWidgets('image picker treats a non-storage URL as an empty preview',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssalImagePickerTile(
            imageUrl: 'not-a-storage-url',
            onPick: null,
            icon: Icons.storefront_outlined,
            label: 'صورة المتجر',
          ),
        ),
      ),
    );

    expect(find.byTooltip('إضافة الصورة'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsNWidgets(2));
    expect(find.byTooltip('تغيير الصورة'), findsNothing);
  });

  testWidgets('premium badge is explicit and readable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssalPremiumBadge(label: 'خطة ذهبية'),
        ),
      ),
    );

    expect(find.text('خطة ذهبية'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
  });
}

final Uint8List _onePixelPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);

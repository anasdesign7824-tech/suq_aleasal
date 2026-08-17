# Task 26 — Header ثابت أثناء Scroll

## Task Scope

إبقاء Header الصفحة الرئيسية ظاهرًا أثناء تمرير محتوى Home، مع سلوك pinned واضح وظل عند تداخل المحتوى.

## Changes

تم استبدال Header العادي داخل `CustomScrollView` بـ`SliverPersistentHeader(pinned: true)` في حالتي Home الجاهزة والتحميل.

تم إنشاء `_PinnedHeaderDelegate` ليقوم بـ:

- تثبيت `_Header` عند أعلى viewport.
- إضافة Material elevation عند `overlapsContent`.
- الحفاظ على padding وهوية الألوان.
- استخدام ارتفاع ثابت 64px يطابق الارتفاع المرئي الفعلي للمكوّن.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | SliverPersistentHeader وdelegate ثابت |
| `docs/evidence/task_26_sticky_header_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Failure and Fix Record

المحاولة الأولى استخدمت `minExtent = 72` و`maxExtent = 80`، وأنتج Flutter assertion من نوع `SliverGeometry` لأن `layoutExtent` تجاوز `paintExtent` الفعلي البالغ 64px. تم إصلاح ذلك بتوحيد `minExtent` و`maxExtent` إلى 64px، ثم نجحت جميع الاختبارات.

## Runtime Verification

Home يستخدم Controller نفسه للتمرير، والـHeader يبقى pinned بينما تتحرك الرفوف والأقسام تحته. Loading body يستخدم السلوك نفسه.

## Visual Verification

عند تداخل المحتوى يظهر ظل خفيف تحت Header، بينما يبقى شريط العلامة والأزرار ثابتًا في أعلى الشاشة.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل بعد الإصلاح، ولم يتغير Auth أو الفلاتر أو مسارات المتاجر.

## Final Gate

**PASS** — Header ثابت أثناء Scroll، مع geometry صحيحة وبدون assertions في الاختبارات.

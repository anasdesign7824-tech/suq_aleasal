# Phase 6 — Final Evidence Report

## المرحلة

**Phase 6 — تنفيذ تطبيق Flutter/Dart وتجارب Customer وMerchant**.

## النتيجة

تم إنشاء تطبيق Flutter/Dart باسم الحزمة `assalkom` ضمن المسار `apps/mobile_flutter`. التطبيق عربي أولًا وRTL، ويستخدم Design System المشترك وأصول الهوية وخط IBM Plex Sans Arabic. يبدأ التطبيق في Demo Mode، ويعرض وسم «نسخة تجريبية» بدل الإيحاء باتصال إنتاجي.

## تجربة Customer

تتضمن Home لاكتشاف العسل اليمني، البحث، المنتجات المختارة، تفاصيل المنتج، التقييمات، وطلب تواصل تجريبي. تعتمد هذه الشاشات على `AssalRepository` ولا تنفذ استدعاءات Supabase مباشرة.

## تجربة Merchant

تتضمن لوحة تاجر تجريبية تعرض اسم المتجر، مؤشرات المنتجات والتقييم، طلبات التواصل، والمنتجات. يمكن التبديل بين Customer وMerchant داخل التطبيق للتأكد من أن كلا المسارين يعملان فوق Demo Repository نفسه.

## State وDomain

استخدمت الشاشات `FutureBuilder` و`AssalStateView` لتغطية loading/data/empty/error، مع رسائل عربية وإعادة محاولة. تستخدم الواجهات DTOs وعقود Dart المشتركة بدل نماذج محلية متعارضة.

## الأصول

تمت إضافة aliases ثابتة غير معدلة للأصلين المرجعيين إلى `assets/brand/logo-internal.svg` و`assets/brand/logo-external.svg`، ونسخهما إلى أصول التطبيق. تم تضمين Demo Catalog والخطوط في `pubspec.yaml`، وأُصلحت مسارات الأصول داخل Catalog وأُعيد التحقق من 36 مرجعًا.

## Evidence

نجح `tools/check_flutter_app.py` و`tools/check_demo_catalog.py` و`git diff --check`. تم التحقق من وجود الملفات والشاشات والأصول والهوية وحدود Demo. لا تحتوي ملفات التطبيق على Supabase أو service role أو اتصال مباشر بمصدر الإنتاج.

## القيود

لم يتوفر Flutter/Dart CLI في Sandbox، ومحاولة تشغيل التحقق على جهاز المستخدم انتهت بمهلة دون نتيجة. لذلك لم تُنفذ `flutter pub get` أو `flutter analyze` أو `flutter test` أو فحص بصري تنفيذي. هذا قيد بيئي موثق وليس تغييرًا للتقنية. يبقى تشغيل الأوامر Gate إلزاميًا عند توفر toolchain.

## Acceptance status

**ACCEPTED — Phase 6 على مستوى المصدر والبنية وDemo Evidence**، مع **فحص تنفيذي مؤجل وغير مانع للانتقال البرمجي** إلى حين توفر Flutter/Dart CLI، ودون اعتبار المرحلة إطلاقًا إنتاجيًا أو اكتمالًا لكل Features.

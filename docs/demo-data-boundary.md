# Demo Data Boundary — عسلكم

## المبدأ

> Demo Mode يعمل من مستودع بيانات محلي/مضمّن، ولا يتطلب Supabase أو RLS أو Backend APIs. Production Mode هو المسار الوحيد الذي يُهيأ له Gateway صريح إلى مصدر الإنتاج.

## المخرجات

| المسار | الدور |
|---|---|
| `packages/demo_data/data/demo_catalog.json` | بيانات Demo حتمية مستخرجة من Honey Master وموسومة `demo_only` |
| `packages/data_dart/lib/assal_repository.dart` | عقد Repository وحالات التحميل في Dart |
| `packages/data_dart/lib/demo_repository.dart` | Demo Repository لتطبيق Flutter |
| `packages/data_dart/lib/production_repository.dart` | Adapter إنتاجي قابل للحقن لاحقًا |
| `packages/data_dart/lib/repository_factory.dart` | اختيار صريح للمصدر |
| `packages/data_ts/src/repository.ts` | عقد Repository لمشاريع Web |
| `packages/data_ts/src/demo_repository.ts` | Demo Repository لمشاريع Web |
| `packages/data_ts/src/production_repository.ts` | Adapter إنتاجي لمشاريع Web |
| `packages/data_ts/src/repository_factory.ts` | اختيار صريح للمصدر |

## حالات البيانات

كل Repository يعيد حالات `loading`, `data`, `empty`, و`error` دلاليًا. لا تُخفى حالة الفراغ أو الخطأ خلف قائمة فارغة، ولا تُستخدم بيانات Demo داخل جداول Supabase.

## Production switch

لا يُسمح بإنشاء Production Repository دون Gateway صريح. عند طلب `production` من Factory دون gateway يفشل الإنشاء برسالة واضحة بدل fallback صامت إلى Demo أو اتصال غير مقصود.

## مصدر Demo

المصدر الأصلي هو `references/data/yemeni_honey_master_database_final.json`. تم توليد 30 منتجًا و3 متاجر و3 مراجعات وطلبات وإشعارات تجريبية حتمية. الأصول المرئية المشار إليها ضمن Demo موجودة في `assets/brand/` ولا تُستخدم كبديل عن البيانات.

# Task 30 — التخصيص

## Task Scope

إضافة تخصيص deterministic لقسم Discovery بعد تسجيل الدخول، باستخدام بيانات الحساب والتفاعلات المتاحة فعليًا دون إنشاء AI وهمي أو توصيات غير قابلة للتفسير.

## Changes

تمت إضافة Future مخصصة في Home تُبنى عند بدء التحميل المؤجل بعد التمرير، وتطبق قواعد قابلة للاختبار على:

| الإشارة | الأثر |
|---|---:|
| المنتجات المحفوظة في المفضلة | أولوية 100 |
| المتاجر التي يتابعها المستخدم | أولوية 70 |
| معرّفات المنتجات المشاهدة في `user.preferences['viewed_product_ids']` | أولوية 35 |
| تطابق الموقع مع منطقة/محافظة/بلد المنتج | أولوية 35 |
| نوع المنتج المفضل في `user.preferences['preferred_product_types']` | أولوية 30 |
| المنتج المميز | أولوية 10 |
| التقييم | إضافة مشتقة من `ratingAverage` |

يتم ترتيب الكتالوج بحسب مجموع النقاط، ثم إزالة التكرار واختيار ثمانية عناصر كحد أقصى. يظهر الرف بعنوان «مقترحات مخصصة لك». إذا لم يكن المستخدم مسجلًا، يظهر Empty State عربي يطلب تسجيل الدخول بدل عرض تخصيص وهمي.

## Data Boundary

التخصيص يستخدم `getSession`, `listFavoriteProducts`, `listFollowedStores`, و`listProducts` الموجودة في Repository. لا توجد خدمة AI أو مصفوفة توصيات ثابتة أو بيانات مستخدم مخترعة.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | قواعد التخصيص ورف المقترحات |
| `docs/evidence/task_30_personalization_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

التخصيص لا يبدأ عند startup؛ يبدأ مع `_startDeferredData` بعد التمرير، لذلك لا يضيف اتصالات مبكرة لمسار Home. المستخدم الضيف يحصل على رسالة واضحة، والمستخدم المسجل يحصل على ترتيب حتمي يمكن تتبعه واختباره.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يتغير مسار Email OTP أو عرض المنتجات العامة أو المتاجر الموثقة.

## Final Gate

**PASS** — تم تنفيذ تخصيص deterministic قابل للتفسير والاختبار، مع الحفاظ على حدود البيانات وعدم إضافة AI وهمي.

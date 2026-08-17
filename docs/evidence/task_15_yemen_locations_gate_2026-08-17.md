# Task 15 — المحافظات والمديريات

## Task Scope

استخدام مرجع اليمن الرسمي داخل التطبيق لاختيارات المحافظة والمديرية، مع أكواد مستقرة، تحميل مؤجل عند فتح الفلاتر، وتصفية المديريات بناءً على المحافظة المختارة.

## Existing State

كان `YemenLocationReference` موجودًا ويقرأ `assets/yemen_governorates_districts.json` ويتحقق من schema والبصمة والأعداد، لكن SearchScreen لم يكن يربطه بفلاتر region/province.

## Changes

تم ربط SearchScreen بمرجع `YemenLocationReference`:

- تحميل المرجع عند فتح Bottom Sheet فقط، وليس عند startup.
- Dropdown للمحافظة باستخدام الأكواد المصدرية.
- Dropdown للمديرية يُعاد بناؤه عند تغيير المحافظة ويعرض أبناءها فقط.
- تصفير المديرية تلقائيًا عند تغيير المحافظة لمنع اختيارًا غير صالح.
- تمرير `regionId` و`provinceId` إلى `AssalProductQuery`.
- عرض رسالة عربية واضحة إذا فشل تحميل المرجع.
- إبقاء كل بيانات الأسماء والأكواد في JSON، دون قوائم يدوية داخل Widget.

## Files Changed

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_discovery.dart` | selectors متسلسلة وربط query |
| `docs/evidence/task_15_yemen_locations_gate_2026-08-17.md` | دليل البوابة |

## Tests

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |
| `YemenLocationReference` schema/count/hash validation | PASS ضمن loader الحالي |

## Runtime Verification

المرجع لا يُحمّل إلا عند الضغط على «الفلاتر»، وبعد اختيار المحافظة تُستخدم `districtsFor(governorateCode)` لإظهار المديريات التابعة فقط. عند فشل القراءة لا يُعرض Selector ناقص، بل تظهر رسالة خطأ عربية.

## Visual Verification

Bottom Sheet يعرض «المحافظة» ثم «المديرية». يكون Selector المديرية معطلاً قبل اختيار المحافظة، ويُعاد ضبطه بعد تغييرها. هذا يمنع قوائم مديريات غير مرتبطة بالمحافظة الحالية.

## Architecture Verification

المسار هو:

```text
assets/yemen_governorates_districts.json → YemenLocationReference → SearchScreen selectors → AssalProductQuery.regionId/provinceId → Repository
```

لا توجد أسماء محافظات أو مديريات مكتوبة يدويًا في الواجهة.

## Data / Contract Verification

القيم الممررة إلى query هي الأكواد المستقرة نفسها، وليس أسماء عربية قابلة للتغيير. Production يستطيع استخدام نفس الأكواد عند تطبيق filtering في gateway.

## Regression Verification

نجحت اختبارات التنقل وطبقة البيانات ورحلة العميل، ولم يتغير Auth/OTP أو Product Model أو فلاتر Task 14.

## Remaining Issues

تفعيل filtering الفعلي في Supabase يتطلب أن تحتوي الجداول على `region_id` و`province_id` المتوافقين مع هذه الأكواد؛ إذا لم تكن الأعمدة موجودة، يجب إغلاق فجوة schema في طبقة backend، لا إدخال mapping بديل داخل الواجهة.

## Final Gate

**PASS** — المحافظة والمديرية أصبحتا اختيارات متسلسلة من مرجع JSON موثوق، مع query codes ثابتة وتحميل مؤجل واختبارات ناجحة.

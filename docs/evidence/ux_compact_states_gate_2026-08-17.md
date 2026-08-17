# UX Compact States Gate — 2026-08-17

## التغيير

تمت إعادة بناء `AssalMessageCard` في المكون المشترك من بطاقة كبيرة ذات فراغ رأسي واسع إلى حالة مدمجة متجاوبة:

- عرض محدود بعرض أقصى 420px.
- خلفية سطحية وحدّ وزوايا متوسطة بدل حاوية ضخمة.
- أيقونة ورسالة في صف واحد.
- زر إعادة المحاولة يظهر كأيقونة ذات tooltip عند توفر callback.
- رموز الأخطاء الداخلية لا تظهر للمستخدم؛ يبقى الكود في طبقة الحالة والسجلات، بينما تعرض الواجهة الرسالة العربية المفيدة فقط.

## التحقق

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 11 tests passed |
| `git diff --check` | PASS |
| مسارات الاستخدام | `AssalStateView`, `AssalFutureStateView`, Home, Search, Stores, Product Detail |

## البوابة

**PASS — compact shared Empty/Error state.**

Loading يبقى `AssalGlassLoading` كما طلب المرجع، وسيُراجع بصريًا في مرحلة QA النهائية بعد بناء النسخ.

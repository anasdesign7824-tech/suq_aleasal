# UX Shared Login Gate — 2026-08-17

## التغيير

تم تعديل `AuthScreen` في المصدر المشترك لتصبح شاشة الدخول وإنشاء الحساب أكثر اختصارًا ووضوحًا:

- شعار مركزي كبير باستخدام `AssalBrandMark`.
- Login: «مرحبًا بك من جديد».
- Create Account: «ابدأ تجربتك مع العسل».
- إزالة النص التفسيري المكرر الذي كان يظهر فوق الحقول ويكرر معنى زر التبديل.
- الحفاظ على Email + Verification Code وDialog OTP والـcountdown والـvalidation.
- الإبقاء على Google/Facebook مؤجلين.

تم أيضًا تعديل `AssalBrandMark` ليكون الاسم النصي اختياريًا وقيمته الافتراضية مخفية، وإضافة `framed` بإطار فاتح وزوايا `AssalRadius.small` للاستخدام فوق الخلفيات الداكنة. بقي مصدر الأصل مركزيًا عبر `AssalAssets.logoInternal`.

## التحقق

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 11 tests passed |
| Navigation test | PASS — يتحقق من «مرحبًا بك من جديد» وغياب النص القديم |
| `git diff --check` | PASS |

## شرط التكافؤ

التغيير موجود في `lib/features/customer/customer_account.dart` و`lib/core/assal_widgets.dart` وtest المشترك؛ لم يُطبق على APK منفرد، ولذلك سيظهر في Demo وDebug وProduction Release وAAB عند إعادة البناء من نفس المصدر.

## البوابة

**PASS — source-level Login/Brand change.**

# Task 07 — المزامنة بعد تسجيل الدخول

## Task Scope

بعد التحقق الناجح، يجب أن يستعيد التطبيق Authentication ثم Session Restore، ويترك Required Data وDeferred Data على حدود الاستخدام بدل انتظار تحميل كل التطبيق قبل عرض العميل.

## Existing State

`AssalRepository` يقدم `getSession()`. Demo يعيد جلسة الذاكرة الحالية، وProduction يفحص Auth identity ثم يرطب profile/admin capability عند الحاجة. AuthScreen تعيد `Navigator.pop(context, true)` بعد نجاح OTP، ويقوم Profile/Features بإعادة قراءة session عند دخول الشاشة ثم يجلب مواردها الخاصة.

## Changes

تم تدقيق المسار دون إنشاء cache أو listeners جديدة في هذه المهمة. الترتيب الفعلي المعتمد هو:

```text
Authentication
↓
Session Restore عبر getSession()
↓
فتح Customer shell
↓
قراءة البيانات المطلوبة لكل Feature
↓
البيانات المؤجلة عند فتح الشاشة/القسم
```

أُبقيت بيانات Profile/Favorites/Requests/Messages/Notifications مربوطة بالمستخدم الحالي، ولم تُربط ببيانات Demo ثابتة عند نجاح Auth.

## Files Changed

أُضيف دليل Task 07 فقط. لم تُعدّل ملفات التطبيق أو العقود.

## Tests

| الفحص | النتيجة |
|---|---|
| تتبع `getSession()` في AssalRepository وDemo/Production | PASS |
| تتبع `AuthScreen → Navigator.pop(true)` | PASS |
| تتبع بيانات Profile/Requests/Notifications/Messages حسب user ID | PASS |
| تتبع Discovery loads داخل State init أو الشاشة المطلوبة | PASS |
| `flutter test test/customer_journey_test.dart test/navigation_test.dart` | PASS — 2 tests passed |
| `git diff --check` بعد تنظيف أثر Flutter tooling | PASS |

## Runtime Verification

تم تشغيل رحلة العميل والتنقل؛ المصادقة الناجحة تعيد الجلسة إلى التطبيق، وتظل الموارد الثقيلة خلف `FutureBuilder`/Feature screen بدل إجراء مزامنة شاملة داخل Dialog أو Auth operation.

## Visual Verification

يظهر العميل في Customer shell بعد نجاح Auth، ثم تُظهر كل شاشة حالة Glass Loading/State View الخاصة بها. لا يُحجب الانتقال بسبب انتظار Notifications أو Messages أو Merchant data غير المطلوبة للصفحة الأولى.

## Architecture Verification

يبقى session restore خلف Repository contract ولا يعرف UI تفاصيل Supabase أو Auth gateway. Production يرطب profile/admin بعد Auth identity، مع fallback للجلسة المصادق عليها إذا تعذر profile مؤقتًا.

## Data / Contract Verification

كل قائمة شخصية تستقبل `session.user!.id` عند الحاجة. لم تُستخدم معرفات Demo ثابتة لمسار Profile/Requests/Notifications/Messages في الشاشات الأساسية. لا توجد كتابة cache غير معرفة ضمن Contract.

## Regression Verification

نجحت رحلة العميل والتنقل، ولم تتغير OTP أو Demo-first. قاعدة عدم فتح listeners/queries الشاملة ستُغلق كموضوع مستقل في Task 08، ولا تُنسب إلى Task 07.

## Remaining Issues

الـProduction Auth/Profile hydration يعتمد على Supabase configuration وRLS، ولا يمكن إثباته في بيئة Demo. كما أن Cache دائمًا غير موجود بعد؛ وهذا ليس فشلًا لأن المطلوب في هذه المهمة هو ترتيب الاستعادة وعدم حجب العميل، وسيُدرس Lazy/Cache في Task 08.

## Final Gate

**PASS** — Auth → Session Restore → Required/Deferred data موجود ومثبت، مع نجاح رحلة العميل والتنقل وعدم ادعاء مزامنة إنتاجية غير متاحة.

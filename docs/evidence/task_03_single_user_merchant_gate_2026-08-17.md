# Task 03 — قاعدة المستخدم والتاجر

## Task Scope

الحفاظ على النموذج الملزم:

```text
User → Open My Store → Merchant Capability
```

مع منع حساب تاجر منفصل، Login منفصل، تطبيق تاجر منفصل، أو Profile منفصل.

## Existing State

المسار الحالي يبدأ من `ProfileScreen` داخل تطبيق العميل، ويعرض `كن تاجرًا` ثم يفتح `BecomeMerchantScreen`. عند الإرسال، يقرأ المسار الجلسة الحالية من `repository.getSession()` ويستخدم `session.user!.id` لنداء `submitMerchantApplication`. لا يوجد مسار Auth أو App منفصل للتاجر. `merchant_dashboard.dart` موجود كـplaceholder، لكن ذلك يدخل في مهام Store Wizard/Dashboard اللاحقة وليس شرطًا لإثبات قاعدة الهوية في هذه المهمة.

## Changes

لم يُنشأ Contract أو Auth Gateway أو Repository جديد للتاجر. تم اعتماد البنية الموجودة وتوثيقها؛ أي توسعة لاحقة يجب أن تستخدم نفس `AssalSession` و`AssalUserProfile` و`AssalRepository` ونفس Auth UID.

## Files Changed

أُضيف دليل البوابة فقط. لم تُعدّل ملفات Flutter أو contracts أو migrations في Task 03.

## Tests

| الفحص | النتيجة |
|---|---|
| بحث عن `MerchantAuth` أو `merchant_login` أو Password/Auth مستقل | PASS — لا مؤشرات صريحة على هوية تاجر منفصلة |
| تتبع `Profile → BecomeMerchantScreen → session.user!.id` | PASS |
| تتبع `submitMerchantApplication` وDemo notification على user ID | PASS |
| `flutter test test/customer_journey_test.dart test/navigation_test.dart` | PASS — 2 tests passed |
| `git diff --check` بعد تنظيف أثر Flutter tooling | PASS |

اختبار `customer_journey_test.dart` يثبت أن رحلة العميل نفسها تسجل الدخول في Demo ثم تنفذ متابعة/مفضلة/طلب تحول إلى تاجر وتتحقق من إشعار `merchant_application` على نفس المستخدم، ثم تكمل الطلب والمراجعة والتعليق والمراسلة.

## Runtime Verification

تم تشغيل اختبارات رحلة العميل والتنقل. المسار يفتح التطبيق من Customer shell، ويستدعي Auth الحالي عند الحاجة، ثم يمرر Auth UID الحالي إلى عملية Merchant application. لا توجد نقطة دخول تاجر مستقلة.

## Visual Verification

تمت مراجعة `ProfileScreen`: زر التحول إلى تاجر يظهر داخل الملف الشخصي نفسه، وليس في شاشة Login أو تطبيق مستقل. كما أن `BecomeMerchantScreen` يحمل نفس هوية عسلكم وثيم التطبيق.

## Architecture Verification

بقيت الطبقات على المسار:

```text
Profile UI → repository.getSession() → AssalRepository.submitMerchantApplication → Demo/Production Repository
```

لم يُوضع Supabase داخل Widget، ولم تُضف طبقة مصادقة ثانية. Production يظل يرجع `production_merchant_application_not_configured` إلى أن تنفذ مهام الـWizard والـProduction provider لاحقًا؛ هذا Blocking صريح خارج نطاق Task 03 وليس نجاحًا وهميًا.

## Data / Contract Verification

تم استخدام `AssalMerchantApplicationDraft` و`AssalMerchantApplicationSummary` الموجودين، كما أن `DemoRepository` يخزن `userId` نفسه في الملخص والإشعار. لا توجد جداول أو IDs موازية لهوية التاجر.

## Regression Verification

نجحت رحلة العميل والتنقل، ولم تتغير الشاشات أو العقود. الفجوات المعروفة في Dashboard وWizard وProduction persistence محفوظة للمهام اللاحقة ولا تُخفى تحت هذه البوابة.

## Remaining Issues

`BecomeMerchantScreen` ما زال نموذجًا أوليًا أحادي الخطوة، و`merchant_dashboard.dart` Stub، وProduction merchant write غير مهيأ. هذه ليست إخفاقًا في قاعدة الهوية؛ ستُعالج بالتتابع في مهام فتح المتجر والتوثيق وDemo/Production.

## Final Gate

**PASS** — المستخدم والتاجر capability واحدة على نفس الحساب والجلسة، مع إبقاء الفجوات الوظيفية اللاحقة مسجلة صراحةً.

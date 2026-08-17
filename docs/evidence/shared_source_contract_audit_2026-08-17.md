# Shared Source Contract Audit — 2026-08-17

## النتيجة

التطبيق الحالي يملك مصدرًا مشتركًا بين نسخ البناء: `main.dart` يقرأ `AssalRuntimeConfig.fromEnvironment()`، ثم يختار Demo أو Production، بينما `AssalApp` و`AssalHomeShell` وWidgets والشاشات والعقود تبقى مشتركة.

## الأدلة من المصدر

`AssalRuntimeConfig` يستخدم:

- `ASSALKOM_MODE` بقيمة افتراضية `demo`.
- `ASSALKOM_SUPABASE_URL`.
- `ASSALKOM_SUPABASE_PUBLISHABLE_KEY`.

إذا لم يكن الوضع `production`، يشغّل `AssalApp` مباشرة، وتقوم `AssalHomeShell` بإنشاء `DemoRepository` عند عدم تمرير Repository. وإذا كان الوضع `production`، تتحقق `main.dart` من التهيئة ثم تنشئ `ProductionRepository` عبر Supabase gateways.

هذا يعني أن اختلاف النسخة ليس اختلاف UI مقصودًا؛ الاختلاف الحالي في Data Source/runtime configuration. يجب أن تبقى كل تحسينات الشعار والـHeader والتنقل والحالات الفارغة والفلاتر في `lib/` وcontracts/repository المشتركة، لا داخل APK منفصل أو مسار build خاص.

## ملاحظة UX مكتشفة

`AssalHomeShell` الحالي يعرض أربعة عناصر فقط في NavigationBar وNavigationRail: «اكتشف»، «التصنيفات»، «المراسلات»، «حسابي». لا يوجد عنصر «المتاجر» في الجذر المشترك، لذلك يجب إضافته هناك حتى يظهر في Demo وDebug وRelease وAAB بالطريقة نفسها.

## ملاحظة بيانات

وجود بيانات `demo_catalog.json` في APK لا يثبت أن Production غير مربوط؛ لكنه يثبت أن Demo fallback متاح عند غياب Repository. لذلك يجب تدقيق APK المستخدم نفسه عبر package/version/hash ثم اختبار runtime mode وOTP، ولا يجوز استنتاج الجاهزية من الحجم أو الصورة.

## شرط القبول الجديد

أي تعديل UX/UI لا يُقبل إلا إذا كان:

1. في الجذر المشترك للمصدر.
2. ظاهرًا في Demo وDebug وRelease وAAB وجميع ABIات بعد إعادة البناء.
3. لا يغير عقد المصادقة أو مصدر البيانات دون توثيق.
4. يملك اختبارًا أو دليلًا بصريًا يثبت التكافؤ بين نسخ البناء.

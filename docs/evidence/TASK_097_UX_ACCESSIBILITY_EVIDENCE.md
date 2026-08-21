# TASK 097 — UX / Accessibility Evidence

## النتيجة

**PASS — تم تدقيق النطاق المحدد وإصلاح فجوات مثبتة في Flutter، مع إعادة تحقق من baseline لوحة الإدارة.** ركزت المهمة على حقول الإدخال، حالات disabled/busy، keyboard submit، focus/semantic affordances، وRTL، دون إعادة بناء الواجهات أو تغيير عقود البيانات.

## نطاق التدقيق والجرد

تم إنشاء جرد source قابل لإعادة الفحص من `git grep` للـinteractive controls وحقول الإدخال وعناصر focus/keyboard/RTL في Flutter وAdmin. نتج عن الجرد `251` سطرًا مطابقًا للأنماط المحددة، منها `181` في Flutter و`70` في Admin، مع `26` تطابقًا صريحًا لأنماط focus/keyboard/RTL. الجرد الخام محفوظ في `artifacts/task097_interactive_inventory_raw.txt`.

هذا الجرد ليس ادعاءً بأن كل عنصر مرئي اختُبر يدويًا؛ هو inventory deterministic لاختيار مسارات عالية الأثر قابلة للاختبار. أما المسارات التي أثبتتها مهام سابقة فقد بقيت **ALREADY FIXED / REVERIFIED**، ومنها profile UX في TASK 042، ومسارات Admin الأساسية في TASK 073، وlocalization في TASK 074.

## الفجوات المثبتة قبل الإصلاح

| السطح | الفجوة المثبتة | الأثر |
|---|---|---|
| `CommentsSection` | حقل التعليق وزر الإرسال بقيا فعالين أثناء انتظار RPC، ولا يوجد keyboard submit، ما يسمح بإرسال متكرر أو تجربة بطيئة غير واضحة. | احتمال double-submit وتجربة غير واضحة عند الشبكة البطيئة. |
| `CommentsSection` | callback مثل `setState(() => future = repository.listComments(...))` يعيد `Future` بدل callback متزامن. | عند الإرسال أو retry يظهر runtime assertion: `setState() callback argument returned a Future`. |
| `ReviewsSection` | زر النشر لا يمنع النشر قبل وجود نص، ولا توجد حالة busy مرئية حول إنشاء المراجعة. | زر غير منضبط في حالة الإدخال الفارغ أو retry أثناء الطلب. |
| `ReviewsSection` | نفس نمط `setState` الذي يعيد Future موجود بعد الإنشاء وretry. | crash/assertion في مسار retry أو refresh بعد الإرسال. |

تم اكتشاف assertion فعليًا أثناء focused widget test، ثم أُصلح وأعيد تشغيل الاختبار حتى PASS؛ لم يُسجل النجاح اعتمادًا على static inspection فقط.

## الإصلاح المحافظ

تم تعديل `apps/mobile_flutter/lib/features/customer/customer_social.dart` فقط ضمن سطح social composition:

1. أضيفت حالة `adding` للتعليقات وحالة `reviewSubmitting` للمراجعات.
2. أثناء إرسال التعليق يُعطل الحقل والزر، ويظهر progress indicator وtooltip/semantic label عربي، ويُرفض أي استدعاء إضافي قبل انتهاء الطلب.
3. أضيف `textInputAction: TextInputAction.send` و`onSubmitted` للتعليق، لذلك يمكن الإرسال من keyboard، مع إبقاء زر الإرسال متاحًا عندما يحتوي الحقل نصًا.
4. أصبح زر نشر المراجعة disabled حتى يكتب المستخدم نصًا، ويظهر busy state خلال RPC، مع labels أوضح للـrating وbody.
5. استُبدلت callbacks التي كانت تعيد `Future` داخل `setState` بكتل متزامنة تعيّن الـFuture دون إرجاعه، في retry وsuccess لمساري المراجعة والتعليق.
6. وُضع `Semantics(button: true, label: ...)` حول زر إرسال التعليق مع tooltip، دون تغيير repository API أو database contract.

لم تتغير دوال Supabase أو migrations ضمن TASK 097، ولم تُضمّن أي تغييرات غير مرتبطة من ملفات أخرى.

## RTL وkeyboard وfocus

اختبار social composer شُغّل داخل `Directionality(textDirection: TextDirection.rtl)`، ويتحقق من `TextInputAction.send`، وkeyboard submit، وتعطيل الحقل والزر أثناء الطلب. التطبيق نفسه يفرض العربية وRTL على مستوى `AssalApp`، وtheme المركزي يوفّر focused borders وinteraction overlays للأزرار والحقول.

في Admin لم يظهر gap يستدعي patch. `AdminAuthGate` يستخدم `dir="rtl"` على wrappers، labels حقيقية للحقول، `role="alert"` للأخطاء، `autoComplete` مناسبًا، `disabled={submitting}` للنموذج، و`dir="ltr"` لقيم البريد وكلمات المرور. كما أن shared `Input` و`Button` يطبقان `focus-visible` rings وحالات disabled وIME composition protection. لذلك سُجل Admin ضمن **ALREADY FIXED / REVERIFIED** بدل تعديل غير لازم.

## الاختبارات والبوابات

| البوابة | النتيجة |
|---|---|
| focused Flutter widget test `test/task097_social_accessibility_test.dart` | PASS — `2/2`، ويثبت busy/disabled، منع duplicate submit، keyboard submit، RTL، وشرط النص قبل نشر المراجعة |
| Flutter analyze | PASS — `No issues found!` |
| Flutter full tests | PASS — `62` اختبارًا |
| Admin `pnpm check` | PASS |
| Admin tests | PASS — `43` اختبارًا عبر `7` ملفات |
| Admin `pnpm build` | PASS |

ظهر تحذير Vite المعتاد حول chunk أكبر من 500 kB بعد التصغير، لكنه non-blocking ولم يفشل البناء. لم تُجرَ browser session تفاعلية مسجلة ضمن TASK 097؛ إثبات هذه المهمة source-based وwidget-test-based، مع gate كامل للتطبيق والإدارة.

## حدود النطاق

هذه المهمة لا تدعي حل كل مسائل UX البصرية أو توحيد المصطلحات والألوان؛ ذلك نطاق TASK 098. كما لا تدعي اختبار كل `754` مرجعًا تفاعليًا يدويًا؛ inventory يحدد 251 تطابقًا source-based، بينما الإصلاح الفعلي استهدف فجوات social composition التي ثبتت باختبار runtime. Admin لم يحتج تعديلًا بعد مراجعة primitives ومسار المصادقة.

## الملفات

| المسار | الدور |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_social.dart` | الإصلاح المحافظ لمساري review/comment |
| `apps/mobile_flutter/test/task097_social_accessibility_test.dart` | focused widget regression test |
| `artifacts/task097_interactive_inventory_raw.txt` | الجرد الخام القابل لإعادة الفحص |
| `docs/evidence/TASK_042_PROFILE_UX_EVIDENCE.md` | دليل سابق أُعيد احترامه كـALREADY FIXED |
| `docs/evidence/TASK_073_ADMIN_CLICK_PATHS_EVIDENCE.md` | دليل سابق لمسارات Admin |
| `docs/evidence/TASK_074_ADMIN_LOCALIZATION_EVIDENCE.md` | دليل سابق لـAdmin localization |

## الحكم النهائي

**TASK 097 = PASS.** تم إصلاح فجوات UX/Accessibility المثبتة في social composer دون تغيير عقود البيانات، وأثبتت focused tests وFlutter full gate وAdmin gates عدم وجود regression. تظل مسائل consistency اللغوية والبصرية العامة في TASK 098 كما هو محدد في المصفوفة.

## References

[1]: `apps/mobile_flutter/lib/features/customer/customer_social.dart`
[2]: `apps/mobile_flutter/test/task097_social_accessibility_test.dart`
[3]: `artifacts/task097_interactive_inventory_raw.txt`
[4]: `apps/mobile_flutter/lib/app/assal_app.dart`
[5]: `apps/mobile_flutter/lib/app/assal_theme.dart`
[6]: `apps/admin_web/client/src/components/AdminAuthGate.tsx`
[7]: `apps/admin_web/client/src/components/ui/input.tsx`
[8]: `apps/admin_web/client/src/components/ui/button.tsx`

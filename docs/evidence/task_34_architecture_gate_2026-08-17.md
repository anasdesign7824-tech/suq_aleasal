# Task 34 — Architecture

## النطاق

تدقيق الحد الفاصل `UI → Repository → Demo/Production Data Source` ومنع استدعاء Supabase أو Gateway مباشرة من الشاشات والWidgets.

## النتائج

| الفحص | النتيجة |
|---|---|
| استيراد `supabase_flutter` داخل `features` | NONE |
| استخدام `SupabaseClient` أو `Supabase.instance` داخل `features` | NONE |
| استخدام `client.from`, `SupabaseQueryGateway`, `SupabaseAuthGateway` داخل `features` | NONE |
| الشاشات الفعلية تحمل `AssalRepository` | PASS — customer account/catalog/core/discovery/favorites/social وmerchant dashboard |
| Composition root | محصور في `main.dart` |
| Factory boundary | يختار DemoRepository أو ProductionRepository، ويرفض Production بلا Gateway |
| `flutter analyze` | PASS — No issues found |
| الاختبارات الأساسية | PASS — 7 tests passed |
| `git diff --check` | PASS |

## الإصلاح

كان `MerchantDashboard` يعرض بطاقة ثابتة تقول «قيد المراجعة في Demo Mode» دون قراءة Repository. أُعيد بناؤه كـ Stateful screen يتلقى `AssalRepository`، ويقرأ `loadMerchantApplication`، ويعرض الحالة الفعلية أو رسالة عدم التهيئة/الحاجة إلى تسجيل الدخول. بذلك لا توجد حالة توثيق أو كتالوج مزيّفة داخل لوحة التاجر.

واجهات `customer_experience.dart` و`home_screen.dart` و`product_detail_screen.dart` التي ظهرت في المسح الأول هي facades/export files، وليست تنفيذات تتصل بالبيانات؛ لذلك لم تُعتبر خرقًا.

## الحدود

تظل ملفات Supabase Gateway وتهيئة Supabase في composition root/core، بينما يمر منطق الأعمال والقراءة والكتابة عبر Repository. لم تتم إضافة تجاوزات أو استدعاءات مباشرة من Widgets.

## Visual QA

تمت مراجعة Dashboard المحدثة مصدرًا من ناحية RTL والحالات الفارغة وحالات الخطأ، لكن لا توجد لقطة محاكي صالحة في هذه الدورة بسبب فشل ADB `screencap` السابق. لا يُدّعى اكتمال Visual QA التفاعلي من دون دليل صالح.

## بوابة القبول

**BLOCKED** — Architecture boundary audit ناجح، وMerchantDashboard لم يعد يملك نجاحًا ثابتًا، والتحليل والاختبارات ناجحة. سبب الحجب الوحيد هو الدليل البصري التفاعلي غير المتاح، وليس خرقًا معماريًا.

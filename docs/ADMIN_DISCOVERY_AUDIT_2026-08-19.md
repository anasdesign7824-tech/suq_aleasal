# تقرير Discovery — تدقيق لوحة إدارة عسلكم

## النتيجة الأولية

الخادم المحلي يبدأ على `127.0.0.1:3210`، لكن موافقة طلب التاجر تستدعي `public.admin_review_merchant_application(...)` من خلال عميل `service_role`. مسار Production ينفذ تريغرات على `profiles` و`merchant_profiles` و`stores`، وهذه التريغرات تستدعي دوالًا في مخطط `private`.

## السبب المثبت لخطأ 42501

نتيجة فحص Production أظهرت أن `service_role` لا يملك `USAGE` على schema `private`، بينما يملكها `postgres` و`supabase_admin`، كما أن `private.is_admin()` لا يملك `EXECUTE` لـ`service_role`. في المقابل، `public.is_admin()` دالة `SECURITY INVOKER` تستدعي `private.is_admin()`. هذا يفسر سجل الخادم: `permission denied for schema private` عند تنفيذ تحديثات الموافقة أو moderation.

Migration `0002_security_hardening.sql` منحت `USAGE` على `private` لـ`authenticated` فقط، وMigration `0004_admin_helper_security.sql` أبقت التنفيذ لـ`anon, authenticated` فقط. Migration `0017` قيدت RPC الإدارية إلى `service_role`، لكنها لم تضف grants الخاصة بمسار `private`، ولذلك بقيت الفجوة.

## أعطال الواجهة المثبتة

في `Home.tsx` زر «استعراض المنتج» وزر «استعراض المتجر» ينفذان `toast.info` بمعرف السجل فقط، ولا يفتحان تفاصيل أو إجراءً فعليًا. هذا زر واجهة غير مكتمل. القائمة الجانبية داخل `aside` ثابتة، و`nav` لا يملك حاوية `overflow-y-auto`، بينما يوجد footer باستخدام `mt-auto`؛ لذلك يمكن قص عناصر القائمة في الارتفاعات الصغيرة.

العناوين `Customer Directory`, `Communication`, و`Operational Analytics` ما زالت إنجليزية، كما تظهر عبارات تقنية مثل `Production`, `Admin Identity`, و`Honey Taxonomy` في واجهة عربية دون طبقة ترجمة موحدة.

`ProductCreationPanel.tsx` يدعم فقط `storeId`, `nameAr`, `productType`, `price`, و`currencyCode`، ولا يتيح التصنيف، الوصف، المصدر، الوزن، الجودة، المعالجة، التغليف، الشحن، الصور، أو بيانات المراجعة. هذا لا يطابق عقد المنتج المستخدم في تطبيق العميل.

`AdminMerchantApplications.tsx` موصول فعليًا بالـAPI وليس زرًا شكليًا، لكن ملاحظة القرار تُقرأ بواسطة `document.getElementById` بدل state متحكم فيه، مما يضعف الاعتمادية عند وجود عدة بطاقات أو إعادة تصيير.

`admin-data.ts` يعيد 500 برسالة عامة من `sendError` ولا يترجم أخطاء Supabase المرمزة مثل `42501` إلى سبب قابل للإصلاح في الواجهة. كما أن `listUsers` يصرح بأن IP غير مسجل في مخطط Production الحالي، لذلك لا يجوز عرض IP وهمي.

## خطة الإصلاح التالية

يبدأ الإصلاح بإضافة migration دفاعية تمنح `service_role` استخدام schema `private` وتنفيذ `private.is_admin()`، وتحول `public.is_admin()` إلى مسار `SECURITY DEFINER` مضبوط أو تمنع الحاجة إلى المسار الملتبس، مع اختبار RPC بعد التطبيق. بعدها تُصلح رسائل Backend، وتُستبدل أزرار المعرفات الوهمية بتفاصيل حقيقية أو تُزال إذا لم يوجد عقد تفصيلي، وتُضاف حاوية تمرير للقائمة الجانبية، ويُوسّع نموذج المنتج الإداري باستخدام نفس حقول التطبيق والصور، ثم تُضاف اختبارات مسارات الإدارة.

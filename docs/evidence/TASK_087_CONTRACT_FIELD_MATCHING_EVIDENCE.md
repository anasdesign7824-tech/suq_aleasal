# TASK 087 — Contract Field Matching Evidence

**التاريخ:** 2026-08-21

**الحالة:** PASS WITH DOCUMENTED DOMAIN-SCOPE LIMITATION

## الهدف والنطاق

قورنت عقود `packages/contracts_dart/lib/assal_domain.dart` و`packages/contracts_ts/src/domain.ts` و`packages/contracts_ts/src/database.ts` مع مراجع الجداول في `apps/admin_web/server/admin-data.ts`. كما قورنت أسماء العلاقات في Database contract مع `information_schema.tables` في Production داخل `BEGIN`/`ROLLBACK`، مع فحص حقول Views التي يعتمد عليها العميل.

## جرد قابل لإعادة الإنتاج

أداة `artifacts/task087_contract_inventory.py` تقرأ enum/class/interface/Row declarations وتفشل صراحةً إذا تغيّر العدد المتوقع أو ظهر drift غير موثق. النتيجة الناجحة الحالية هي:

| المصدر | النتيجة |
|---|---:|
| Dart enums | 12 |
| Dart domain classes | 35 |
| TypeScript domain unions | 7 |
| TypeScript domain interfaces | 7 |
| Database.ts Tables + Views | 62 |
| Admin `.from()` relation references | 31 |
| Production relations من information_schema | 62 |

والـJSON الكامل محفوظ في `artifacts/task087_contract_inventory.json`، بينما snapshot مخطط Production محفوظ في `artifacts/task087_production_schema_snapshot.json`.

## ما تم اكتشافه

كانت `Database.ts` تغطي الجداول الأساسية ومعظم Views، لكنها كانت تفتقد أربع Views موجودة فعليًا في Production: `customer_comments`, `customer_conversations`, `customer_favorite_products`, و`customer_followed_stores`. لذلك كان العقد TypeScript غير مكتمل، حتى مع نجاح TypeScript العام، لأن بعض استدعاءات Supabase النصية لا تستنتج اسم العلاقة من literal داخل `admin-data.ts`.

كما أن `AssalRole` في Dart يحتوي `guest` بينما TypeScript كان يقصره على الأدوار authenticated. هذا اختلاف boundary مقصود وليس فقدان حقل في قاعدة البيانات؛ أضيف إلى التفسير كحالة guest runtime. و`RequestStatus` يستخدم `inProgress` في Dart لكن `in_progress` في TypeScript/SQL، وهو اختلاف تسمية تمت معالجته صراحةً في Dart بواسطة `RequestStatusWire.wireValue`، لذلك لا يُعد قيمة حالة مفقودة.

واجهات TypeScript domain الحالية أضيق من نماذج Dart الغنية في حقول store/product/review/request. فحص المصدر لم يجد استيرادًا لها من Admin client/server؛ هي boundary type مختصر غير مستهلك في المسار التشغيلي الحالي، ولذلك لم تُضف حقولًا تخمينية أو تغييرات واسعة غير لازمة. كامل الحقول الغنية ومصادرها الفعلية مغطاة في Dart وDatabase Views، وتنتقل مراجعتها التشغيلية إلى TASK 088 الخاصة بالـread models.

## الإصلاح المنفذ

أضيفت Views الأربعة إلى قسم `Views` في `packages/contracts_ts/src/database.ts`، مع Row fields مطابقة لأعمدة Production وأنواعها، و`Insert`/`Update` read-only عبر `never` لأن هذه العلاقات Views وليست مسارات كتابة. شملت الإضافة جميع أعمدة `customer_comments` (11)، و`customer_conversations` (9)، و`customer_favorite_products` (51)، و`customer_followed_stores` (28)، دون اختراع أعمدة أو تعديل Production schema.

بعد الإصلاح أعاد inventory المقارنة `contract_only=[]`, `production_only=[]`, و`shared_count=62`. كما نجحت assertions في تطابق ProductType وProductStatus وStoreStatus وVerificationStatus وReviewStatus بالكامل، وتحققت من أن الاختلاف الوحيد في RequestStatus هو `inProgress` مقابل wire value `in_progress`.

## الاختبارات والبوابات

نجحت أداة inventory مع جميع assertions، ونجحت بوابة Admin بعد تعديل Database contract: `pnpm check`، و`pnpm test -- --run` بعدد 26 اختبارًا (4 auth، 18 data، 4 error)، و`pnpm build`. بقي تحذير Vite الخاص بحجم chunk الأكبر من 500 kB كما هو تحذير غير مانع في المهام السابقة. لم تُجرَ أي كتابة في Production؛ فحص schema وcolumns كان داخل `BEGIN`/`ROLLBACK`.

## الخلاصة والحدود

**لا يوجد relation-name drift** بين Database.ts وProduction بعد الإصلاح، وجميع Admin relation references أصبحت مدعومة في Database contract؛ الاسمان الوحيدان غير الموجودين ضمن database relations هما `assalkom_public` و`assalkom_private`، وهما bucket names في Storage وليسا جداول أو Views. تبقى الواجهات المختصرة في `domain.ts` قيد توثيق scope لأنها غير مستهلكة تشغيليًا؛ لا يجوز اعتبارها generated mirror كاملًا لـDart قبل قرار معماري مستقل. أما مقارنة كل read-model field بمصدره المباشر وnullability والتحويلات فتُستكمل في TASK 088.

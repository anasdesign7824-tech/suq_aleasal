# تقرير قبول مزامنة التاجر والمستخدمين — 2026-08-18

## النتيجة التنفيذية

تم إصلاح فجوة كانت تجعل طلب التاجر ينتقل إلى حالة `approved` فقط، بينما يبقى حسابه في `profiles.role=customer` ولا يُنشأ له `merchant_profile` أو `store` أو إشعار تفعيل. أُضيفت Migration 0016 إلى Supabase Production، وتمت معالجة الطلب المعتمد الموجود مسبقًا.

أصبحت دورة الاعتماد الذرية:

`merchant_applications` → `profiles.role=merchant` → `merchant_profiles.verification_status=verified` → `stores.status=active / is_verified=true` → `notifications.merchant_activation` → `audit_logs`

يستخدم الخادم المحلي RPC واحدًا باسم `admin_review_merchant_application` حتى لا تظهر حالة نجاح جزئية إذا فشل أحد أجزاء المزامنة. كما أصبح القرار idempotent على مستوى الواجهة؛ المتجر المفعّل لا يعرض زر تفعيل مكررًا.

## تحقق Production

قبل Migration 0016 كان Production يحتوي على طلب تاجر واحد بحالة `approved`، ومستخدمين اثنين بحالة `customer`، ولم يكن للطلب متجر أو `merchant_profile` مرتبطان.

بعد Migration 0016 تم التحقق من الصف نفسه بالنتيجة التالية:

| العنصر | الحالة بعد الإصلاح |
|---|---|
| `merchant_applications.status` | `approved` |
| `profiles.role` | `merchant` |
| `merchant_profiles.verification_status` | `verified` |
| `stores.status` | `active` |
| `stores.is_verified` | `true` |
| إشعار التفعيل | `merchant_activation` موجود |
| `customer_stores` | يعرض المتجر النشط للتطبيق |

## تطبيق العميل

تقرأ `ProductionRepository.loadMerchantApplication` حالة الطلب والمتجر من Production، ولا تعتبر وجود الطلب وحده دليلًا على صلاحية المنتجات. تظهر للمستخدم رسالة التفعيل فقط عندما يكون المتجر `active` و`is_verified=true`. بعد تحديث الجلسة وقراءة `profiles.role=merchant` يظهر زر **لوحة التاجر** بدل **كن تاجرًا**.

أضيفت حقول وصف المتجر والمنطقة وشعار المتجر والغلاف إلى مسودة وطلب التاجر. كما أضيف مسار رفع الصور إلى bucket `assalkom_public` الموجود فعليًا في Supabase، مع مسار ملفات يبدأ بمعرف المستخدم حتى تطبق سياسات Storage الحالية. وضع Demo لا يعطي نجاحًا وهميًا لرفع الصور؛ يعرض أن الرفع متاح في Production فقط.

يحدّث التطبيق `users.last_seen_at` عند تحميل جلسة Production. فشل تحديث النشاط لا يبطل جلسة المستخدم، حتى لا تتحول Telemetry إلى نقطة فشل للمصادقة.

## لوحة الإدارة

تم تحديث قسم طلبات التجار ليعرض حالة `submitted`, `under_review`, `needs_more_info`, `rejected`, و`approved` باسم واضح **مفعّل — المتجر نشط**. قرار التفعيل يوضح أنه يزامن الحساب والمتجر والإشعار، ولا يسمح بتفعيل مكرر من الواجهة بعد نجاح القرار.

تم توسيع قسم المستخدمين ليعرض من مصادر فعلية:

| البيانات | المصدر |
|---|---|
| البريد وتأكيد البريد وآخر دخول | Supabase Auth Admin API |
| وقت إنشاء السجل وآخر نشاط | `users` و`last_seen_at` |
| الاسم والهاتف والدور والحالة | `profiles` |
| حالة طلب التاجر والموقع وملاحظة المراجعة | `merchant_applications` |
| اسم المتجر وحالته والتحقق | `stores` |
| عنوان IP | غير مسجل حاليًا؛ لا يتم اختلاقه |

عنوان IP لا يظهر على أنه قيمة حقيقية لأن مخطط Production الحالي لا يجمعه. الواجهة تعرض بوضوح أنه غير مسجل بدل اختراع بيانات تدقيق.

## الاختبارات

نجح `pnpm check` و`pnpm test` و`pnpm build` للوحة الإدارة. اختبارات الإدارة الحالية: **4/4**. نجح `flutter analyze --no-pub`، ونجحت اختبارات Flutter: **13 اختبارًا**. بعد إضافة `image_picker` نجح `flutter pub get` ونجح التحليل والاختبارات مرة أخرى.

تم تشغيل نسخة Admin مبنية على التغييرات الجديدة على المنفذ 3212، وتحقق تسجيل الدخول الإداري الحقيقي، وقراءة طلبات التجار، وقراءة المستخدمين مع حقول `merchantApplication` و`store`. أعاد الخادم تسجيل الدخول HTTP 200، وقراءة المسارين HTTP 200، وكان أول طلب بحالة `approved` وأول متجر بحالة `active`.

## بناء APK Production النهائي

بعد عودة اتصال Windows، أُعيد تشغيل `flutter pub get` ثم `flutter analyze --no-pub` و`flutter test --no-pub` بنجاح. بُني APK Production arm64 باستخدام `assalkom.production.defines.json`، وبذلك لا يمكن اعتباره Demo أو build غير مهيأ.

| العنصر | النتيجة |
|---|---|
| الملف | `assalkom-production-merchant-sync-arm64-release.apk` |
| الحجم | `22,055,089` بايت تقريبًا، أي 21.0 MB كما عرضه Flutter |
| SHA-256 | `49211c472a022f469bdc7a570886dc4cd08dfd08cdba9aaf88d3c81805579cbc` |
| APK archive integrity | `unzip -t`: لا توجد أخطاء |
| Supabase build defines | تم تمريرها عبر `--dart-define-from-file` |
| Flutter analysis | PASS |
| Flutter tests | 13/13 PASS |

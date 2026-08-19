# تشخيص إصلاح الملف الشخصي ومساحة التاجر — 2026-08-19

## نتيجة فحص Production

تم فحص سياسات RLS في مشروع Supabase `gvalqfgxrkibuydoiuiz` عبر Supabase MCP. كانت `profiles` تحتوي على سياسات `SELECT` و`UPDATE` تسمحان للمستخدم عندما يطابق `user_id = auth.uid()`، لكن لم تكن هناك سياسة `INSERT`. وفي المقابل كان `profiles_pkey` فهرسًا فريدًا على `user_id`، وكانت سجلات profiles موجودة للمستخدمين الذين تمت قراءتهم.

## السبب المرجح للرسالة

كان التطبيق ينفذ `profiles.upsert` دون تحديد `onConflict: user_id`. PostgREST قد يقيّم مسار INSERT في upsert حتى عند حل التعارض على المفتاح، وغياب سياسة INSERT كان يحوّل الفشل إلى الرسالة العامة `لا تملك صلاحية تنفيذ هذا الإجراء.` من `_write`.

## الإصلاح المطبق

أُنشئت Migration 0021 لإضافة `profiles_insert` بشرط `user_id = auth.uid()` أو admin، وتم تعديل عقد Gateway و`SupabaseQueryGateway` لقبول `onConflict`، وتمرير `onConflict: 'user_id'` في `updateUserProfile`. كما أضيف تحقق دفاعي داخل ProductionRepository يمنع تعديل أي ملف لا يطابق هوية جلسة Supabase نفسها.

## مسار التصميم القديم

كانت `ProfileScreen._openMerchantArea` تفتح `BecomeMerchantScreen` عند عدم وجود مساحة، وكانت الشاشة القديمة تعرض نموذج طلب تاجر طويلًا، وبطاقة تحقق، وأزرار رفع منفصلة. تم حذف `BecomeMerchantScreen` و`_VerificationStatusCard` واستبدالهما بـ`MerchantWorkspaceSetupScreen` التي تفتح مساحة المتجر مباشرة بعد الحد الأدنى من البيانات، وتعرض الحالة المعلقة، وتحوّل المستخدم إلى `MerchantDashboard`، وتستخدم مكوّن `AssalImageUploadSlot` المشترك.

## توحيد رفع الصور

نُقل `AssalImageUploadSlot` إلى `apps/mobile_flutter/lib/core/assal_widgets.dart` ويُستخدم الآن في محرر الملف الشخصي ومساحة إعداد المتجر. كل خانة تعرض المعاينة وزر `إضافة الصورة` أو `تغيير الصورة` داخل المربع نفسه، وتستدعي رفع الصورة مباشرة عند الضغط.

## مصادر خارجية

المصدر الخارجي المستخدم هو مخطط وسياسات Production عبر مشروع Supabase `gvalqfgxrkibuydoiuiz`، وليس صفحة ويب عامة. نتائج SQL محفوظة أيضًا في `/home/ubuntu/.mcp/tool-results/2026-08-19_08-31-14.489003785_supabase_execute_sql_2f9b040e.json` و`/home/ubuntu/.mcp/tool-results/2026-08-19_08-32-55.210985757_supabase_execute_sql_38024de5.json`.

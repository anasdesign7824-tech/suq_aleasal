# TASK 094 — IDOR Scope Decision

## النطاق المفحوص

تمت مراجعة routes وfunctions التي تستقبل IDs وتنفذ delete/update/review في `apps/admin_web/server/index.ts` و`apps/admin_web/server/admin-data.ts`. شمل ذلك المتاجر والمنتجات والبanners والمستخدمين وطلبات التاجر وطلبات التوثيق والمدفوعات والاشتراكات وطلبات التصميم والرسائل واللوجستيات وعضويات المديرين.

## نتيجة source review وProduction inventory

المسارات التشغيلية تستخدم `requireAdmin(permission)`، والـmutators تعيد فحص permission داخل `admin-data.ts` قبل إنشاء Supabase service query. RPCs الحساسة في Production (`admin_moderate_store`, `admin_review_merchant_application`, `admin_review_store_verification`, `admin_set_store_verification_payment`, `admin_reconcile_payment_request`, `admin_set_subscription_status`, `admin_activate_subscription_for_user`) هي `SECURITY DEFINER` ومقفلة عن `anon` و`authenticated` ومسموح تنفيذها لـ`service_role` فقط. تحقق كل RPC من administrator/permission عندما لا يكون الدور `service_role`، ثم يثبت record بالـID المرسل داخل transaction.

الأدوار الفعلية في Production: `super_admin` فقط لديه عضوية نشطة حاليًا؛ role `admin` و`moderator` موجودان كتعريفات، لكن لا توجد لهما عضوية نشطة في نتيجة inventory. role `moderator` لا يملك delete أو product.write أو store.approve أو payments.manage أو plans.manage أو admin.manage.

## قرار الإصلاح

لم يثبت تجاوز IDOR في المسارات المفحوصة، لذلك لم يُدخل patch runtime أو تغيير صلاحيات قد يكسر نموذج الإدارة المقصود. أضيفت اختبارات `admin-idor.test.ts` تثبت أن moderator لا يصل إلى mutators حتى مع تغيير target ID، وأضيفت HTTP matrix تثبت أن 18 mutation route ذات IDs تعيد `401` بلا session عند إرسال same-origin requests، بدل الوصول إلى handler أو Supabase.

التحذير المتبقي ليس IDOR مثبتًا: بعض operations الإدارية global بطبيعتها، مثل إدارة المتاجر والمنتجات والخطط، ويمكن للمشرف ذي permission الصحيح تشغيلها على أي record؛ هذا هو نطاق الإدارة المقصود وليس تجاوزًا عبر ID.

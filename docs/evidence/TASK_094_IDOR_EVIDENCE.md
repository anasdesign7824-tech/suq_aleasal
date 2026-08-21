# TASK 094 — IDOR Authorization Evidence

## النتيجة

**PASS — NO IDOR BYPASS FOUND.** تم تدقيق مسارات Admin التي تستقبل IDs في delete/update/review، مع negative tests لحساب moderator وHTTP matrix على Production-connected Admin Web. لم يثبت تجاوز للصلاحيات عبر استبدال IDs، ولذلك لم يُدخل تغيير runtime في authorization؛ أضيفت فقط regression tests وartifacts تثبت الحدود الحالية.

## نطاق التدقيق

شمل التدقيق مسارات المتاجر والمنتجات والـbanners والمستخدمين وطلبات التاجر وطلبات التوثيق والمدفوعات والاشتراكات وطلبات التصميم والرسائل واللوجستيات وعضويات المديرين. كما شمل RPCs `admin_moderate_store`, `admin_review_merchant_application`, `admin_review_store_verification`, `admin_set_store_verification_payment`, `admin_reconcile_payment_request`, `admin_set_subscription_status`, و`admin_activate_subscription_for_user`.

## نتائج Production

| الفحص | النتيجة المثبتة |
|---|---|
| Admin RPC ACL | الدوال الحساسة `SECURITY DEFINER`، والتنفيذ مغلق عن `anon` و`authenticated` ومفتوح لـ`service_role` فقط. |
| RPC permission | كل RPC يتحقق من active admin/permission عندما لا يكون الدور `service_role` قبل mutation. |
| ID binding | كل RPC يثبت السجل المطلوب بـ`where id = p_*_id` ثم ينفذ transition داخل نفس transaction؛ لا يوجد fallback إلى أول سجل أو إلى session user بدل المعرف المطلوب. |
| Roles | `super_admin` هو العضوية النشطة الفعلية في inventory. role `admin` و`moderator` معرفان، لكن بلا عضوية نشطة في النتيجة المقروءة. moderator لا يملك delete أو product.write أو store.approve أو payments.manage أو plans.manage أو admin.manage. |
| Global admin scope | إدارة المتاجر والمنتجات والخطط مقصودة كصلاحيات إدارية global للمدير المخول؛ اختيار أي ID بهذه الصلاحية ليس IDOR بذاته. |

## HTTP IDOR matrix

شُغّل Admin Web المتصل بـSupabase Production على `127.0.0.1:3213`. أُرسلت الطلبات بـ`Origin: http://127.0.0.1:3213`، بلا cookies أو session، وبمعرف UUID غير موجود. جميع الحالات الثماني عشرة أعادت `401`، فلم تصل إلى handler أو Supabase write.

| الفئة | المسارات المفحوصة | النتيجة |
|---|---|---:|
| Store | delete store، moderate store | 2/2 = `401` |
| Product/banner | delete/update product، delete/update banner | 4/4 = `401` |
| Verification/payment | review verification، reconcile verification payment، review merchant application، reconcile payment request | 4/4 = `401` |
| Subscription/design | set subscription status، activate subscription، update design request | 3/3 = `401` |
| Requests/logistics | answer request، delete delivery option، delete pickup location | 3/3 = `401` |
| Admin identity/user | update admin membership، delete user | 2/2 = `401` |

النتيجة الخام محفوظة في `artifacts/task094_idor_http_matrix.json`، والسكربت القابل لإعادة التشغيل في `artifacts/task094_idor_http_matrix.ps1`.

## Unit authorization matrix

`server/admin-idor.test.ts` يستخدم session بدور `moderator` وtarget ID واحدًا ثابتًا، ويثبت أن permission check يرفض قبل إنشاء أي Supabase mutation في delete/update/review/activation/membership operations. شمل الاختبار deleteStore وdeleteProduct وdeleteBanner وdeleteUser وupdateProduct وupdateDesignRequest وmoderateStore وreviewStoreVerification وreconcileStoreVerificationPayment وreconcilePaymentRequest وsetMerchantSubscriptionStatus وactivateSubscriptionForUser وupdateAdminMembership.

## الاختبارات

| الاختبار | النتيجة |
|---|---|
| `pnpm check` | PASS |
| `pnpm test -- --run` | PASS؛ 6 ملفات و40 اختبارًا ناجحًا، منها 3 اختبارات IDOR |
| `pnpm build` | PASS |
| HTTP matrix | 18/18 بلا جلسة = `401` |
| Permanent data writes | لا توجد probes mutation في Production؛ كل HTTP requests بلا session توقفت عند auth guard |

## قرار الإصلاح

لم يُغيّر runtime authorization أو database/RPC contracts لأن الدليل لم يثبت IDOR. التغيير الوحيد في التطبيق هو إضافة `admin-idor.test.ts` كحاجز regression. هذا يحافظ على نموذج الإدارة المقصود: المدير المخول عالميًا يستطيع إدارة السجل الذي يختاره، بينما role بلا permission لا يصل إلى mutation مهما تغير ID.

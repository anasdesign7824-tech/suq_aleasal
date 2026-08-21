# TASK 096 — Production Write Constraints Summary

المصدر الخام: `/home/ubuntu/.mcp/tool-results/2026-08-21_20-25-25.625773814_supabase_execute_sql_a06278e6.json`.

## قيود التكرار المثبتة

| الجدول | القيد/المفتاح | الدلالة في duplicate-write audit |
|---|---|---|
| `favorites` | unique partial indexes على `(user_id, product_id)` و`(user_id, store_id)` | toggle favorite/store follow لا ينبغي أن ينشئ صفين لنفس هوية المستخدم والهدف. |
| `product_likes` | primary key مركب على `(product_id, user_id)` | إعجاب المنتج محمي من duplicate rows على مستوى المفتاح. |
| `reviews` | unique على `product_id` وunique على `author_id` بحسب Production schema | المراجعة ليست append-only بلا قيد؛ retry يجب ألا ينشئ مراجعتين. |
| `merchant_applications` | unique على `user_id` | إعادة إرسال application يجب أن تستخدم update/upsert semantics أو تفشل بلا duplicate. |
| `merchant_subscriptions` | unique على `payment_request_id` | إعادة reconcile لنفس payment request يجب ألا تنشئ اشتراكين مرتبطين بالطلب نفسه. |
| `merchant_delivery_options` | unique على `(store_id, delivery_method_id, region_id)` | duplicate click على upsert delivery option يجب أن يبقى صفًا واحدًا. |
| `request_messages` | primary key فقط على `id` | لا يوجد business idempotency key ظاهر في schema؛ retry للإجابة/الرسالة قد ينشئ صفًا ثانيًا إن لم تحمِ RPC أو الواجهة. |
| `comments` | primary key فقط على `id` | لا يوجد unique business key؛ duplicate comment retry يحتاج RPC/UX guard أو يبقى قابلًا للتكرار. |
| `requests` | primary key فقط على `id` | create request يحتاج فحص RPC/UX للتكرار؛ لا يوجد unique business key في الأعمدة المستخرجة. |
| `design_requests` | primary key فقط على `id` | create design request لا يظهر له unique business idempotency key في schema. |
| `store_verification_documents` | primary key فقط على `id` | duplicate document insert قد يكون ممكنًا إذا أعيد الطلب نفسه؛ يلزم فحص RPC/UX policy قبل patch. |
| `payment_events` / `store_verification_events` | primary key فقط على `id` | events append-only؛ يجب أن تكون transitions/RPCs idempotent عند إعادة نفس الحالة أو ترفض الانتقال غير الصالح. |

## حدود التدقيق

هذه الخلاصة تثبت قيود schema فقط. لا تُثبت بعد سلوك RPC عند تكرار الطلب؛ لذلك يلزم قراءة تعريفات RPC الفعلية واختبارات fake gateway أو probes داخل `BEGIN ... ROLLBACK` قبل تقرير إصلاح. لا يوجد أي write دائم مقصود في هذا artifact.

# TASK 096 — Production Write RPC Definitions Summary

المصدر الخام: `/home/ubuntu/.mcp/tool-results/2026-08-21_20-26-28.976462325_supabase_execute_sql_0d66c427.json`.

## RPCs ذات idempotency أو existing-row guards

| RPC | السلوك المثبت من definition |
|---|---|
| `customer_create_conversation` | يبحث عن أحدث conversation بنفس `store_id + created_by` داخل `FOR UPDATE`؛ يعيد existing row بدل إنشاء conversation ثانية. participants يستخدم `ON CONFLICT DO NOTHING`. |
| `customer_create_review` | `INSERT ... ON CONFLICT (product_id, author_id) DO UPDATE`؛ retry يعيد نفس review ID ويحدث payload بدل duplicate review. |
| `merchant_create_subscription_payment_request` | يستخدم `pg_advisory_xact_lock` لكل merchant، ثم يبحث عن payment request نشط (`not_started/proof_uploaded/under_review`) ويعيده بدل إنشاء ثاني؛ يغلق race بين check وinsert. |
| `merchant_open_workspace` | `merchant_profiles` و`stores` يستخدمان `ON CONFLICT (user_id/merchant_id) DO UPDATE`؛ retry لا ينشئ متجرًا ثانيًا. |
| `merchant_submit_payment_proof` | يقفل payment request بـ`FOR UPDATE` ويقبل فقط `not_started/failed`؛ retry بعد `proof_uploaded` يرفض ولا يضيف payment event ثانيًا. |
| `merchant_submit_verification_payment_reference` | يقفل request بـ`FOR UPDATE` ويقبل فقط `draft/payment_pending/needs_more_info`; بعد ذلك الحالة `payment_pending`، والإعادة تعيد رفضًا transition-invalid بدل duplicate request. |

## RPCs قابلة للتكرار بحسب definition الحالية

| RPC | ملاحظة |
|---|---|
| `customer_create_request` | كل استدعاء ينفذ `INSERT INTO requests`، ولا يوجد idempotency key أو existing-request guard في definition؛ schema لا يملك business unique key. double-click/retry قد ينشئ طلبين. |
| `customer_create_comment` | كل استدعاء ينفذ `INSERT INTO comments`، ولا يوجد idempotency key؛ schema primary key فقط. duplicate comments ممكنة عند retry. |
| `customer_send_message` | كل استدعاء ينفذ `INSERT INTO messages`، ولا يوجد client idempotency key أو duplicate guard؛ messages primary key random فقط. duplicate messages ممكنة عند retry. |
| `customer_toggle_favorite` | toggle semantics: الاستدعاء الثاني المقصود يزيل favorite، لذلك double-click ليس retry-idempotent؛ unique index يحمي الصفوف لكنه لا يمنع تغيير الحالة مرتين. |
| `customer_toggle_product_like` | toggle semantics مشابهة؛ `FOR UPDATE` على product يمنع race جزئيًا، لكن retry بعد success يعكس like إلى unlike. |
| `customer_toggle_store_follow` | toggle semantics مشابهة؛ `FOR UPDATE` على store يمنع race جزئيًا، لكن retry بعد success يعكس following إلى unfollowing. |
| `merchant_create_design_request` | كل استدعاء ينشئ `design_requests` جديدة بعد entitlement count؛ لا يوجد idempotency key أو unique business key؛ duplicate design requests ممكنة. |

## قرار التدقيق المؤقت

العمليات `conversation/review/subscription payment/workspace/payment proof/verification reference` تبدو محمية من duplicate writes خادميًا. العمليات `request/comment/message/design_request` تحتاج duplicate-write probes أو patch محافظ، بينما toggles تحتاج فصل double-click UX من retry semantics أو إضافة operation idempotency؛ لا يجوز اعتبار unique index وحده كافيًا لأن الاستدعاء الثاني يغيّر الحالة.

لا توجد بيانات Production جديدة أو permanent writes في هذه القراءة؛ كانت قراءة تعريفات فقط.

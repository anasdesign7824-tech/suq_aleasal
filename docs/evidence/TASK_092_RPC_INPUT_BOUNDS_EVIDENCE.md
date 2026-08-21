# TASK 092 — RPC Input Bounds / Abuse Evidence

## النتيجة

**PASS.** تم تدقيق public RPC inventory في Production، ثم تنفيذ boundary probes قبل الإصلاح وبعده، وإيداع migration `0060_harden_public_rpc_input_bounds.sql` وتطبيقها بنجاح على مشروع Supabase Production `gvalqfgxrkibuydoiuiz`.

لم تُستخدم أي بيانات ثابتة من الواجهة لإثبات النجاح. جميع probes التي يمكن أن تُنشئ سجلات نُفذت داخل `BEGIN ... ROLLBACK`، ولم تُدّعَ اختبارات لم تتوفر لها محادثة أو اشتراك نشط.

## نطاق التدقيق

شمل inventory الدوال العامة المتاحة لـ`authenticated`، ومنها `customer_create_comment`, `customer_create_request`, `customer_create_review`, `customer_send_message`, `customer_toggle_favorite`, `customer_toggle_product_like`, `customer_toggle_store_follow`, `merchant_create_design_request`, `merchant_create_subscription_payment_request`, `merchant_open_workspace`, `merchant_submit_payment_proof`, و`merchant_submit_verification_payment_reference`.

أثبت فحص schema أن `reviews.rating` محمي أصلًا بقيـد `1..5`، وأن `request_items.quantity` محمي فقط بشرط `> 0`، بينما كانت أعمدة النصوص وحقول JSONB في الطلبات والتعليقات والمراجعات والرسائل والتصميمات من نوع `text/jsonb` دون حدود طول أو حجم كافية على مستوى RPC.

## ما كُشف قبل الإصلاح

| الحالة | نتيجة Production قبل migration | الدلالة |
|---|---|---|
| `customer_create_review(..., rating=0)` | `22023:invalid_review` | **ALREADY FIXED**؛ لم يُعاد إصلاحها خارج نطاق الحاجة. |
| `customer_create_review(..., rating=6)` | `22023:invalid_review` | **ALREADY FIXED**؛ حدود التقييم 1–5 موجودة. |
| مراجعة بطول 5001 حرفًا | `ACCEPTED` | ثغرة طول نص؛ كانت تُقبل قبل الكتابة. |
| تعليق بطول 5001 حرفًا | `ACCEPTED` | ثغرة طول نص؛ كانت تُقبل قبل الكتابة. |
| طلب بكمية `0` | `ACCEPTED` | السلوك السابق كان يحولها صامتًا إلى `1` عبر `greatest(...)` بدل رفض الإدخال غير الصحيح. |
| `handoff_details` كمصفوفة JSON | `ACCEPTED` | لم يكن هناك تحقق من أن JSON يمثل object أو من حجمه. |
| رسالة بطول 5001 حرفًا | تعذر الوصول إلى body guard بسبب `conversation_not_owned` للمحادثة الاصطناعية | لا تُحسب كنجاح أو فشل لطول الرسالة؛ بعد patch أصبح طول الرسالة يفحص قبل الوصول إلى المحادثة. |

## الإصلاح المنفذ

أُضيفت migration `0060_harden_public_rpc_input_bounds.sql` دون تغيير signatures أو عقد ACL، وأعيد تعريف الدوال المستهدفة فقط مع الحفاظ على منطق الأعمال القائم للقيم الصحيحة.

| RPC / المجال | الحدود المضافة |
|---|---|
| المراجعات والتعليقات والرسائل | رفض body الفارغ عند الاقتضاء، ورفض النصوص الأطول من 5000 حرف. |
| `customer_create_request` | subject حتى 180 حرفًا، body حتى 5000، phone حتى 40، handoff option حتى 32، channel حتى 64، notes حتى 1000 لكل حقل، `handoff_details` يجب أن يكون JSON object وحجمه حتى 16 KiB، والكمية من 1 إلى 1000. |
| `merchant_open_workspace` | business name من 2 إلى 180، description حتى 5000، phone حتى 40، وlogo/cover URL حتى 2048. |
| `merchant_submit_payment_proof` | payment reference من 3 إلى 120، file name وsender name حتى 180، sender phone حتى 40، proof path حتى 512 مع رفض `..` و`//`، مع الإبقاء على MIME/size/owner-prefix checks السابقة. |
| `merchant_create_design_request` | title حتى 180 وغير فارغ، description حتى 5000 وغير فارغ، brand name حتى 180، brand colors array حتى 32 KiB، product scope object حتى 32 KiB. |

الحد الأعلى للكمية `1000` متسق مع أكبر product limit المعلن في خطط المشروع، ولم يُستخدم truncation صامت للحقول الجديدة؛ الإدخال غير الصحيح يُرفض برسالة ثابتة لا تعكس قيم المستخدم الخام.

## إثبات التطبيق والاختبار

سجل Supabase يثبت migration:

| الاسم | version |
|---|---:|
| `harden_public_rpc_input_bounds` | `20260821192247` |

نتائج post-migration داخل `BEGIN ... ROLLBACK`:

| الحالة | النتيجة بعد الإصلاح |
|---|---|
| rating `0` و`6` | كلاهما مرفوض بـ`22023:invalid_review`. |
| review body `5000` | **ACCEPTED**، لإثبات عدم رفض الحد الصحيح. |
| review body `5001` | مرفوض بـ`review_body_too_long`. |
| comment body `5001` | مرفوض بـ`comment_body_too_long`. |
| message body `5001` | مرفوض بـ`message_body_too_long`. |
| request quantity `0` و`1001` | كلاهما مرفوض بـ`request_quantity_invalid`. |
| request handoff JSON array | مرفوض بـ`request_handoff_details_invalid`. |
| request subject بطول `181` | مرفوض بـ`request_subject_too_long`. |
| workspace name بطول `181` | مرفوض بـ`Business name is too long`. |
| payment reference بطول `121` | مرفوض بـ`payment_reference_invalid`. |
| design title بطول `181` | مرفوض بـ`design_title_invalid`. |

ونتائج smoke probe للقيم الصالحة داخل rollback:

| الحالة | النتيجة |
|---|---|
| comment body بطول `5000` | **ACCEPTED**. |
| request صحيح بكمية `1` وhandoff object صغير | **ACCEPTED**. |

تحقق ACL/body flags بعد التطبيق أن جميع الدوال المستهدفة لها `anon_execute=false` و`authenticated_execute=true`. كما ظهرت length guards في كل الدوال المستهدفة، وJSON type/size guards في `customer_create_request` و`merchant_create_design_request`، وquantity guard في `customer_create_request`.

## الملفات والأدلة

| الملف | الغرض |
|---|---|
| `database/migrations/0060_harden_public_rpc_input_bounds.sql` | migration الإصلاح المحافظ. |
| `docs/evidence/TASK_092_RPC_INPUT_BOUNDS_EVIDENCE.md` | هذا التقرير. |
| `artifacts/task092_pre_boundary_probe.json` | raw pre-migration boundary result. |
| `artifacts/task092_post_boundary_probe.json` | raw post-migration rejection matrix. |
| `artifacts/task092_valid_probe.json` | raw valid-payload smoke result. |
| `artifacts/task092_acl_flags_probe.json` | raw ACL/body guard verification. |
| `artifacts/task092_security_advisors_after_migration.json` | raw Supabase security-advisor result after migration. |

## Advisor limitation

أعاد فحص Supabase الأمني بعد DDL تحذيرات معروفة عن قابلية تنفيذ دوال `SECURITY DEFINER` من أدوار `anon` أو `authenticated`، إضافة إلى تحذير حماية كلمات المرور المسربة. هذه ليست نتيجة أنشأتها migration 0060: الـRPCs atomic الحالية مصممة عمدًا كـ`SECURITY DEFINER` ومحصورة في `authenticated`، و`is_admin()` وAuth password policy خارج نطاق input bounds لهذه المهمة. سُجلت النتيجة في `artifacts/task092_security_advisors_after_migration.json` ولم يُجرَ تغيير معماري غير مطلوب قد يكسر atomic writes؛ تُتابع هذه التحذيرات ضمن مسار hardening/RLS المخصص.

## الخلاصة والحدود

أُغلقت TASK 092 بحالة **PASS**. التقييم `0..5` كان محميًا مسبقًا وسُجل **ALREADY FIXED** بدل تكرار الإصلاح. أما الثغرات المثبتة بالـprobe فتمت معالجتها على مستوى RPC قبل أي insert/update. لم تُنفذ اختبارات إرسال رسالة ناجحة إلى محادثة حقيقية أو اختبار design request ناجح لأن ذلك يتطلب حالة محادثة/اشتراك أعمال فعلية؛ لذلك لا يُدّعى نجاح تلك السيناريوهات خارج حدود boundary guards التي اختُبرت مباشرة قبل الوصول إلى preconditions.

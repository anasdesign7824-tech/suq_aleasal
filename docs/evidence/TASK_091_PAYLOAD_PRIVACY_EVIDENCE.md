# TASK 091 — Notification and Request Payload Privacy Evidence

**التاريخ:** 2026-08-21

**الحالة:** PASS

## النطاق

تم تدقيق payloads الإشعارات والطلبات والرسائل والتعليقات ومسارات payment proof للتأكد من عدم نسخ phone أو بيانات الدفع إلى recipient غير مقصود. شمل ذلك source review لـ`ProductionRepository` وAdmin notification route، وProduction payload-key probe، و`pg_policies` الخاصة بالـrecipient scope.

## Production payload probe

تم فحص مفاتيح `notifications.payload` فقط، مع تجميع عدد الصفوف دون إرجاع أي قيم. المفاتيح المرصودة كانت:

| المفتاح | عدد الصفوف |
|---|---:|
| `action` | 1 |
| `image_url` | 2 |
| `payment_status` | 2 |
| `request_id` | 5 |
| `status` | 4 |
| `store_id` | 4 |

لم تظهر مفاتيح `phone`, `email`, `sender_phone`, `payment_reference`, `proof_path`, `proof_file_name`, `account_number`, أو `iban` في payloads الحالية. تفاصيل الـprobe محفوظة في `artifacts/task091_payload_privacy_probe.json`.

## Recipient isolation

أثبت Production `pg_policies` ما يلي:

| المورد | نطاق القراءة |
|---|---|
| `notifications` | `user_id = auth.uid()` فقط |
| `requests` | requester نفسه، أو مالك المتجر المستهدف، أو Admin |
| `request_messages` | المرسل، أو requester/store owner للطلب، أو Admin |
| `comments` | approved، أو author، أو مالك متجر المنتج، أو Admin |

لذلك فإن phone الموجود في request يظل داخل request المصرح بها للطالب/التاجر المستهدف، ولا يتحول إلى notification payload عام. ويمرر `customer_create_request` phone إلى RPC كحقل الطلب نفسه، بينما يرسل `customer_send_message` conversation id وbody فقط. أما `merchant_submit_payment_proof` فيرسل حقول الإثبات إلى payment RPC ولا يضعها في notifications payload.

## الخلل المكتشف والإصلاح

كان Admin `buildAdminNotificationPayload` يمرر `payload` المخصص كما هو، مما يسمح نظريًا لمستخدم Admin بإدخال phone أو email أو payment/proof/account/IBAN key داخل إشعار. لم تظهر هذه المفاتيح في Production الحالي، لكن المسار المستقبلي لم يكن محميًا مركزيًا.

أضيف recursive redaction مركزي قبل insert إلى `notifications`. يحذف الحقول الحساسة داخل objects وarrays، ويدعم snake_case وcamelCase الشائعين مثل `sender_phone`, `senderPhone`, `payment_reference`, `paymentReference`, `proof_path`, `proofPath`, `account_number`, `accountNumber`, و`iban`. وتبقى الحقول الوظيفية الآمنة مثل `screen`, `action`, `request_id`, `status`, `store_id`, و`image_url`.

## الاختبارات والبوابة

أضيف اختبار Admin يمرر sensitive keys متداخلة داخل object وarray ويتحقق من حذفها مع بقاء القيم الآمنة. نجحت البوابات النهائية:

| البوابة | النتيجة |
|---|---|
| `pnpm check` | PASS |
| `pnpm test -- --run` | PASS — 29 tests إجمالًا: 4 auth، 21 data، 4 error |
| `pnpm build` | PASS؛ تحذير chunk-size غير المانع المعروف فقط |

## الحدود الصريحة

لم تُخفَ phone داخل body النصي الذي يكتبه المستخدم أو Admin؛ فهذا محتوى مقصود داخل request/message ويُحكم بنطاق recipient policies، وليس payload metadata آليًا. كما أن payment/verification documents تبقى في private bucket وتخضع لنتائج TASK 090. لم تُجرَ أي كتابة Production ضمن probes.

## الحكم

**TASK 091 مغلقة PASS.** payloads الحالية لا تحمل sensitive keys، recipient policies تقصر القراءة على الأطراف الصحيحة، ومسار Admin المستقبلي محمي الآن بـrecursive redaction مركزي قابل للاختبار.

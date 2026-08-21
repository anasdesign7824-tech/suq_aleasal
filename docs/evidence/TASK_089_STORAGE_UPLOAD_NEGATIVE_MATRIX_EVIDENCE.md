# TASK 089 — Storage Upload Negative Matrix Evidence

**التاريخ:** 2026-08-21

**الحالة:** PASS

## النطاق

تم تدقيق مسارات رفع الصور والملفات في العميل وفي Admin، مع فصل public image uploads عن private verification/payment-proof uploads. شمل التدقيق الامتداد المعلن، MIME/signature consistency، الحجم، path traversal، separators، overwrite، وامتداد SVG/PDF. لا توجد كتابة في قاعدة البيانات أو Storage ضمن الاختبارات؛ التغيير التشغيلي الوحيد هو تشديد الحواجز البرمجية قبل الرفع.

## الخلل المكتشف

كان `SupabaseQueryGateway` يختار `image/jpeg` لأي امتداد غير معروف، ويسمح بـ`upsert: true` في public وprivate buckets، ولم يكن يتحقق من signature أو size أو path. وكان `uploadPaymentProof` يضع extension القادم من caller مباشرةً داخل private path. أما Admin فكان يفرض MIME وحجمًا للصور العامة ويستخدم `upsert: false`، لكنه لم يتحقق من magic bytes ولم يكن لديه اختبار صريح لـpurpose traversal.

هذه الفجوات كانت تسمح بأن يعلن caller نوعًا لا يطابق محتوى الملف، أو يرسل مسارًا غير آمن إلى gateway، أو يستبدل object قائمًا عند إعادة استخدام path، كما أن private payment proof كان يقبل extension خامًا بدل whitelist موحدة.

## الإصلاح المنفذ

أضيف `packages/data_dart/lib/storage_upload_policy.dart` كسياسة مركزية قابلة للاختبار. تفرض السياسة حدود `10 MiB` للـpublic و`20 MiB` للـprivate، وتسمح فقط بـ`jpg/jpeg/png/webp/svg` للـpublic وبـ`jpg/jpeg/png/webp/pdf` للـprivate. وتتحقق من magic bytes للـJPEG/PNG/WEBP/PDF ومن بنية SVG النصية، وترفض empty payload وsignature mismatch. كما ترفض المسارات الفارغة أو المطلقة أو التي تحتوي `..` أو backslash أو `//` أو whitespace غير مطبع أو محارف خارج whitelist.

تم تعديل `SupabaseQueryGateway` لاستخدام extension normalization، policy validation، و`upsert: false` في `assalkom_public` و`assalkom_private`. وتم تعديل `ProductionRepository` ليطبع extension في verification/payment paths ويمنع إدخال extension خام داخل path، مع إبقاء ownership/IDOR ضمن نطاق TASK 094 بدل خلط المهام.

في Admin، أضيف `validatePublicImageSignature` إلى `decodePublicImageInput`، وأضيف `sanitizeStoragePurpose` قبل بناء public path. ظل Admin يستخدم `upsert: false` ويظل الحد الأقصى العام `MAX_PUBLIC_IMAGE_BYTES = 10 MiB`.

## مصفوفة الاختبار

| الحالة | النتيجة المثبتة |
|---|---|
| امتداد public/private غير مدعوم | مرفوض عبر normalization whitelist |
| MIME أو signature لا يطابق المحتوى | مرفوض في Admin وFlutter policy |
| payload فارغ | مرفوض |
| public أكبر من 10 MiB | مرفوض |
| private أكبر من 20 MiB | مرفوض |
| absolute path أو `../` أو backslash أو `//` | مرفوض عبر `validateStorageUploadPath` |
| Admin purpose يحوي traversal أو separators | يتحول إلى prefix آمن لا يحتوي `/` أو `\\` أو `..` |
| إعادة استخدام نفس object path | لا overwrite؛ `upsert=false` في Gateway وAdmin |
| SVG في public | مقبول فقط عند signature نصية SVG صحيحة |
| SVG في private | مرفوض لأن private whitelist لا تسمحه |
| PDF في private | مقبول عند `%PDF-` signature |

المصفوفة القابلة لإعادة القراءة محفوظة في `artifacts/task089_storage_upload_matrix.json`.

## البوابات

نجح `flutter analyze --no-pub`، ونجحت اختبارات Flutter بعد إضافة اختبار policy المستقل بعدد **59 اختبارًا**. نجح `pnpm check`، ونجحت اختبارات Admin بعدد **28 اختبارًا**، ونجح `pnpm build`. أثناء التحقق الأول فشل اختبار واحد لأنه ظل يتوقع payload النصي `hello` بعد تحويل fixture إلى PNG حقيقي؛ صُحح الاختبار ليطابق PNG signature، ثم أعيدت البوابة كاملة ونجحت. بقي تحذير Vite الخاص بحجم chunk كما هو تحذير غير مانع معروف.

## الحدود الصريحة

لم يُنفذ رفع فعلي إلى Storage ضمن الاختبارات لتجنب إنشاء objects في Production. لذلك إثبات overwrite هو إثبات contract-level من `upsert=false` في جميع مسارات الرفع، وليس probe destructive. كما أن فحص IDOR الخاص بملكية payment proof أو verification object ينتقل إلى TASK 094، وفحص عدم كشف objects الخاصة عبر public URL ينتقل إلى TASK 090.

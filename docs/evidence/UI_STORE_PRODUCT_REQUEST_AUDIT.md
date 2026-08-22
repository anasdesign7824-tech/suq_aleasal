# تدقيق واجهة العميل والتاجر ومسار الطلب — سوق عسلكم

**الإصدار المرحلي:** 22 أغسطس 2026.  
**النطاق:** دورة المنتج والمتجر والطلب والرد، بيانات المتجر الظاهرة للعميل، قنوات التواصل والتسليم، المتابعة، الحقول المرجعية، وإخفاء Pro/التوثيق مؤقتًا من أسطح العميل دون حذف الخلفية.

## 1. الحكم المرحلي

أُغلقت في هذه الجولة فجوات حقيقية في الخادم وعقود البيانات والواجهات، ولم يقتصر العمل على إضافة أزرار شكلية. أصبح المسار المدعوم كالتالي: يفتح العميل منتجًا، يقرأ معلومات المنتج والمتجر وخيارات التسليم المتاحة، يرسل طلب توفر، يظهر الطلب للتاجر من خلال read model موحد، يفتح التاجر التفاصيل ويرسل ردًا مصنفًا، ثم يقرأ العميل الرد في شاشة التفاصيل. كما أصبحت قنوات التواصل وخيارات التسليم ونقاط الاستلام قابلة للتأليف من محرر المتجر، وتظهر في `customer_stores` عند حفظها.

> هذا الحكم **ليس إعلان جاهزية إطلاق عام**؛ فاختبار جهازين authenticated، وإثبات تسليم Realtime الفعلي، وOTP الحي ما زالت بوابات منفصلة لم تُغلق في هذه الجولة.

## 2. ما تم إثباته فعليًا

| المجال | النتيجة الحالية | الدليل |
|---|---|---|
| رد التاجر | RPC ذري يتحقق من هوية وملكية التاجر، يضيف الرسالة، يحدّث الحالة، ينشئ إشعار العميل، ويمنع التكرار بمفتاح mutation | `artifacts/REQ01_MERCHANT_REPLY_EVIDENCE.md` |
| تفاصيل الطلب | عقد Flutter وشاشة مشتركة تعرض تفاصيل الطلب وسجل الرسائل وتمنح التاجر controls للرد | `artifacts/REQ01_MERCHANT_REPLY_EVIDENCE.md` و`customer_request_detail_widget_test.dart` |
| read model الطلب | view واحدة تعرض المنتج والكمية والمتجر والعميل والحالة وبيانات التسليم، وتُستخدم للعميل والتاجر | `artifacts/REQ04_REQUEST_READ_MODEL_EVIDENCE.md` |
| بطاقة المنتج | الصورة الرئيسية مربعة 1:1 مع ضبط ارتفاع الشبكات ومعالجة overflow عربي حقيقي | `artifacts/REQ05_PRODUCT_CARD_EVIDENCE.md` |
| متابعة المتجر | زر متابعة/إلغاء متابعة في رأس المتجر فوق الهوية مع تحميل حالة المستخدم وbusy/error handling | `artifacts/REQ06_STORE_FOLLOW_EVIDENCE.md` |
| Pro والتوثيق | الإخفاء مؤقت في الأسطح المشتركة، مع بقاء الجداول والعقود ومسارات الخلفية دون حذف | `artifacts/REQ07_PRO_BADGE_DEFERRED_EVIDENCE.md` |
| الحقول المرجعية | خيارات منسدلة للحقول المقيدة في محرر المنتج، مع إبقاء legacy value خيارًا قابلًا للحفظ وعدم تحويل النصوص الحرة إلى قوائم مصطنعة | `artifacts/REQ08_PRODUCT_EDITOR_DROPDOWNS_EVIDENCE.md` |
| read model المتجر | `customer_stores` يسقط القنوات الاجتماعية والتوصيل والاستلام بدل arrays فارغة ثابتة | `artifacts/REQ09_STORE_RICH_READ_MODEL_EVIDENCE.md` |
| تأليف القنوات | RPC Production ومحرر التاجر يتيحان WhatsApp وTelegram والموقع، طرق التسليم canonical، ونقاط استلام منفصلة | `artifacts/REQ10_11_STORE_CHANNELS_EVIDENCE.md` |

## 3. دورة الطلب والرد الحالية

يبدأ العميل من صفحة المنتج، ويستفيد من البيانات التي يعيدها `customer_products` ومن بيانات المتجر التي يعيدها `customer_stores`. لا توجد في هذا النطاق سلة أو checkout أو دفع بالبطاقة. الطلب الحالي هو **طلب توفر/استفسار**؛ لذلك لا ينبغي وصفه كعملية شراء مكتملة.

عند إنشاء الطلب، يمرر العميل الكمية وخيار التسليم وبيانات التسليم الاختيارية وفق العقد الحالي. يصل الطلب إلى التاجر عبر قائمة طلباته، وتستخدم الشاشة المشتركة `customer_request_detail.dart` بدل بطاقة قراءة غير قابلة للفتح. يختار التاجر إحدى الحالات الثلاث: `available` أو `unavailable` أو `contact_required`، ثم يرسل نص الرد. الخادم هو الذي يفرض الملكية وانتقال الحالة؛ الواجهة لا تنفذ تحديثًا مباشرًا غير مقيد للحالة.

يظهر الرد للعميل من سجل الرسائل، بينما يحتوي إشعار `request_answered` على معرفات محدودة ولا يضع نص الرسالة أو رقم الهاتف داخل payload. التواصل الخارجي يعرض فقط القنوات التي أعلنها التاجر، ولا يُستنتج وجود قناة من مجرد كون المتجر مفعّلًا.

## 4. بيانات المتجر والتواصل والتسليم

كان الخلل السابق مزدوجًا: read model العميل كان يعيد القنوات فارغة، ومحرر التاجر لم يكن يملك سطحًا لتأليف هذه القنوات. عولج السببان معًا. migration `merchant_store_channels` طُبقت في Production، وأصبح RPC `public.merchant_save_store_channels(uuid, jsonb, jsonb, jsonb)` يحفظ القيم تحت ملكية التاجر ثم يعيد صف `customer_stores`.

| نوع البيانات | طريقة التحرير | ضابط القيمة |
|---|---|---|
| WhatsApp وTelegram والموقع | حقول URL منفصلة | `http://` أو `https://`، وWhatsApp يكتب كرابط `https://wa.me/...` لا رقمًا خامًا |
| طرق التسليم | checklist متعدد الاختيار | الأكواد الفعالة من `delivery_methods` فقط؛ في fixture الحالي `courier` و`merchant_delivery` و`pickup` |
| نقاط الاستلام | إدخال نقطة واحدة ثم `InputChip` لكل نقطة | لا توجد قائمة نصية مفصولة بفواصل، والحد الأقصى للنص يفرضه RPC |
| الهاتف | حقل اتصال المتجر الحالي | يبقى منفصلًا عن الروابط الاجتماعية |

في probe rollback استخدم مالك المتجر `4e658ebb-4b2f-4c01-8ee8-e56fc201c673` والمتجر `32fb6bdd-ceb4-4a8b-b6a1-1ac92c466c47`. نجح الحفظ، وأظهر `customer_stores` رابطَي WhatsApp وTelegram، وخياري `شركة توصيل` و`توصيل التاجر`، ونقطة الاستلام. عند إعادة الاستدعاء بالقيم نفسها كانت الأعداد `social=2` و`delivery=2` و`pickup=1`، ورُفض non-owner وanon بـ`P0001`. انتهى الاختبار بـ`ROLLBACK` ولم يترك بيانات probe في Production.

## 5. قرارات تجربة المستخدم

تم اعتماد الصورة المربعة 1:1 في بطاقات المنتج لأن صورة المنتج هي مدخل القرار البصري الأول، مع إبقاء الاسم والتصنيف والتوفر والسعر والتقييم داخل بطاقة قابلة للقراءة RTL. في صفحة المتجر، وُضعت المتابعة في رأس الهوية مع عدد المتابعين بدل دفنها في تبويب التواصل. كما بقيت القنوات العامة والتسليم في قسم واضح داخل بيانات المتجر، ولا تُعرض القنوات غير المؤلفة على أنها متاحة.

أُخفيت عبارة `موثق Pro` من الأسطح المقصودة مؤقتًا. هذا لا يعني أن `is_verified` أصبح معنىً تجاريًا جديدًا، ولا يعني أن فتح المتجر أو تفعيله يمنح توثيقًا. خلفية Pro والتوثيق قابلة لإعادة التفعيل بعد بناء مسار طلب مستقل، دفع محلي يدوي، مراجعة بيانات، وحالة تحقق مستقلة.

الحقل المرجعي لا يعني أن كل محتوى المنتج يجب أن يصبح قائمة. لذلك تحولت القيم ذات wire contract مثل بلد المصدر والجودة والمعالجة والتغليف إلى خيارات منضبطة، بينما بقي الوصف والوسوم والمكونات وملاحظات التسليم نصوصًا حرة لأنها محتوى خاص بالمنتج.

## 6. قائمة المهام وحالتها

| المهمة | الحالة | قرار الإغلاق |
|---|---|---|
| REQ-01 — رد التاجر الآمن | مغلقة | migration وrollback probe وidempotency وRLS وإشعار العميل |
| REQ-02/03 — عقد البيانات وشاشة التفاصيل | مغلقة | contracts وProduction/Demo implementations وwidget tests |
| REQ-04 — read model الطلب | مغلقة | view موحدة وprobe يعيد المنتج والمتجر والعميل والكمية والحالة |
| REQ-05 — بطاقة المنتج المربعة | مغلقة | 1:1، إصلاح overflow، واختبار البطاقة |
| REQ-06 — متابعة المتجر | مغلقة | زر الرأس، الحالة الحقيقية، busy/error، واختبار widget |
| REQ-07 — تأجيل Pro/التوثيق | مغلقة | default-off في العميل دون حذف الخلفية |
| REQ-08 — dropdowns المنتج | مغلقة | القيم المرجعية منظمة مع legacy compatibility |
| REQ-09 — read model المتجر الغني | مغلقة | القنوات والتوصيل والاستلام تُقرأ من الجداول القانونية |
| REQ-10 — RPC قنوات المتجر | مغلقة | Production version `20260822072206` وprobe owner/non-owner/anon/rollback |
| REQ-11 — ربط Flutter وواجهة التاجر | مغلقة | DTO، repository methods، editor section، tests، evidence، commit `305f620` |
| PROD-02 — ترتيب أعلى أولوية لتفاصيل المنتج | مفتوحة | يلزم مراجعة لاحقة مستقلة للسعر/التوفر/التسليم وCTA دون توسيع النطاق الحالي |
| SYNC-01 — إثبات مزامنة جهازين | مفتوحة ومحجوزة | لا تُغلق إلا بحسابين منفصلين وجهازين authenticated وتغيير مقروء من الطرف الآخر |
| QA-01 — قبول الهاتفين وOTP الحي | مفتوحة ومحجوزة | يحتاج inbox حقيقيًا وحسابات اختبار مخصصة وtimestamps وAPK محدثًا |

## 7. الاختبارات والـgates

| البوابة | النتيجة |
|---|---|
| `flutter analyze --no-pub` من `apps/mobile_flutter` | PASS — No issues found |
| اختبار REQ-11 المستهدف | PASS — 3 tests |
| full mobile test suite | PASS — 70 tests |
| `git diff --check` للملفات المستهدفة | PASS |
| APK release split-per-ABI بنمط Demo | PASS — arm64 21.7 MB، armeabi-v7a 19.7 MB، x86_64 23.2 MB |
| أجهزة Android متاحة في جلسة القبول | BLOCKED — `adb devices` لم يعرض جهاز Android؛ المتاح Windows فقط وEdge غير مدعوم للتطبيق |

الـAPK المبني بنمط Demo يثبت بوابة البناء والتقسيم حسب المعمارية، لكنه ليس دليلًا على اتصال Production. بناء Production يحتاج تمرير `ASSALKOM_MODE=production` مع URL ومفتاح publishable صالحين، ولا تُطبع الأسرار في السجلات أو تُلتزم في Git.

## 8. commits هذه الجولة

| commit | المحتوى |
|---|---|
| `7307b0a` | تمكين رد التاجر على طلبات العميل |
| `ca012f3` | توحيد read model للطلبات |
| `56057c8` | بطاقات منتجات مربعة ومتجاوبة |
| `6f559d5` | ربط متابعة المتجر في صفحة العميل |
| `b7b7600` | تأجيل شارة Pro في أسطح العميل |
| `afef138` | قوائم محرر المنتج المرجعية |
| `869271a` | read model المتجر الغني |
| `305f620` | ربط قنوات المتجر والتوصيل في Production وFlutter |

## 9. ما لم يُعتبر نجاحًا

لن نعتبر وجود زر أو نص داخل الواجهة دليلًا على وظيفة مكتملة. النجاح هنا يتطلب أن يملك الخادم عقدًا مقيدًا، وأن يمرر repository القيم الصحيحة، وأن تعرض الواجهة نتيجة المصدر الحقيقي مع states للتحميل والخطأ والفراغ. كذلك لا تُعتبر حالة `SUBSCRIBED` وحدها إثباتًا لتسليم Realtime event، ولا يُعتبر بناء APK أو وصول التطبيق إلى شاشة الدخول إثباتًا لـOTP حي.

لا تشمل هذه الجولة cart أو checkout أو الدفع بالبطاقة أو FCM/APNs أو اعتماد توثيق Pro. كما لا يُحذف أي جدول أو migration خاص بالتوثيق أو الاشتراكات بسبب قرار الإخفاء المؤقت.

## 10. المراجع المعيارية

المقارنة التالية استخدمت لاستخراج أنماط عامة، لا لنسخ التصميم أو ادعاء وظائف غير موجودة.

| المرجع | النمط المستفاد |
|---|---|
| Amazon | تجميع هوية المنتج والصور والمواصفات والعرض والتسليم في مسار قرار واحد. [1] |
| OpenSooq | فصل التواصل المباشر بين البائع والمشتري عن مجرد عرض الإعلان. [2] |
| يمن مزاد | تصنيف المحتوى وربط الإعلان بالتواصل مع صاحبه. [3] |
| Meta/Facebook | فصل إثبات أصالة الحساب عن الخدمة المدفوعة وعن اعتماد كل منشور. [4] |
| YouTube | شارة القناة نتيجة تحقق مستقل وليست نتيجة فتح الحساب فقط. [5] |

[1]: https://sell.amazon.com/blog/amazon-product-listings "Amazon — How to create Amazon product listings"
[2]: https://play.google.com/store/apps/details?id=com.opensooq.OpenSooq&hl=ar "OpenSooq — Google Play listing"
[3]: https://play.google.com/store/apps/details?id=com.yemenmazad.www&hl=ar "Yemen Mazad — Google Play listing"
[4]: https://www.facebook.com/help/196050490547892 "Meta — About verified Pages and profiles on Facebook"
[5]: https://support.google.com/youtube/answer/3046484?hl=ar "YouTube Help — شارات التحقق على القنوات"

## 11. مراجع المشروع

- `apps/mobile_flutter/lib/features/customer/customer_catalog.dart`
- `apps/mobile_flutter/lib/features/customer/customer_account.dart`
- `apps/mobile_flutter/lib/features/customer/customer_request_detail.dart`
- `apps/mobile_flutter/lib/features/merchant/merchant_dashboard.dart`
- `apps/mobile_flutter/lib/features/merchant/merchant_product_editor.dart`
- `apps/mobile_flutter/lib/core/assal_widgets.dart`
- `packages/contracts_dart/lib/assal_domain.dart`
- `packages/data_dart/lib/assal_repository.dart`
- `packages/data_dart/lib/production_repository.dart`
- `packages/data_dart/lib/demo_repository.dart`
- `database/migrations/0062_merchant_request_reply.sql`
- `database/migrations/0063_customer_requests_read_model.sql`
- `database/migrations/0064_customer_stores_rich_read_model.sql`
- `database/migrations/0065_merchant_store_channels.sql`
- `artifacts/REQ10_11_STORE_CHANNELS_EVIDENCE.md`
- `artifacts/REQ06_DEMO_APK_SHA256SUMS.md`

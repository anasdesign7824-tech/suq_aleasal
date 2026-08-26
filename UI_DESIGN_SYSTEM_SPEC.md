# UI Design System Specification — عسلكم

## الهوية البصرية

الهوية المعتمدة هي **Premium Arabic Social Marketplace**: دافئة وفخمة وهادئة، مع أولوية للقراءة والبيانات وعدم تضخيم البطاقات. اسم المستخدم هو **عسلكم**، ويظل `Souq Al Assal / سوق العسل` اسمًا هندسيًا داخليًا.

## Tokens

تُستخدم tokens الموجودة في `packages/design_system/dart` و`docs/design-system-contract.md` بدل القيم المباشرة داخل الشاشات. الألوان الأساسية هي `primary #F39C12` و`primaryDark #9C5A00` و`honeyLight #FFF0D6` و`deepBrown #4F2E1F` و`cream #F8F4EC` و`surface #FFFFFF`، مع `textPrimary #342118` و`textSecondary #6F5B4C` و`border #E8DCCB` وحالات النجاح والتحذير والخطأ المعتمدة.

الخط الموحد هو `IBM Plex Sans Arabic`. سلم المسافات من مضاعفات 4، ونصف أقطار العناصر بين 8 و28، بينما تستخدم Chips وBadges نصف القطر الحبيبي. لا تُستخدم ألوان أو قياسات أو ظلال جديدة داخل Screen من دون قرار موثق.

## المكونات الإلزامية

| Component | السلوك القانوني | الحالات المطلوبة |
|---|---|---|
| `AssalAppBar` | رأس موحد مع RTL وشعار/رجوع وأفعال | normal, scrolled, compact |
| `PrimaryButton` | فعل رئيسي واحد واضح | enabled, loading, disabled, forbidden |
| `SecondaryButton` | فعل ثانوي غير منافس | enabled, disabled |
| `HoneyCard` | حاوية بيانات ناعمة كثيفة | normal, pressed, disabled |
| `ProductCard` | عرض ProductPresentation موحد | compact, rail, grid, disabled |
| `StoreCard` | عرض StorePresentation موحد | compact, list, verified |
| `SearchField` | بحث RTL مع نص إدخال واضح | empty, typing, loading, error |
| `FilterChip` | فلتر قابل للتمييز | selected, unselected, disabled |
| `Badge` | حالة/توثيق من مصدر بيانات | verified, pending, rejected, unavailable |
| `InputField` | حقل مع label/help/error | empty, valid, invalid, disabled |
| `EntityStateView` | Renderer موحد للحالات | الثماني حالات |
| `Dialog/Sheet` | قرار/تفصيل دون فقدان السياق | confirm, error, loading |
| `MediaTile` | نسبة صورة ومعالجة fallback ثابتة | loading, loaded, failed, empty |
| `ContextPreview` | ربط المنتج/المتجر/الطلب | present, absent |

## قواعد البطاقات

`ProductCard` يثبت نسبة الصورة، الاسم، التصنيف، السعر/عند الطلب، التقييم، التوفر، والوسم القانوني. الأفعال توضع في موضع واحد ولا تُكرر داخل البطاقة. `StoreCard` يعرض صورة الهوية والاسم وشارة التوثيق والموقع ومؤشر التفاعل، ولا يعرض وصفًا طويلًا أو قائمة منتجات داخل البطاقة.

أي اختلاف بين العميل والتاجر والإدارة ينفذ كـ`variant` أو `capability slot` موثق. لا تنشأ `CustomerProductCard` أو `MerchantProductCard` أو `AdminProductCard` إلا عند وجود اختلاف دلالي مثبت في Discovery.

## الحالات العامة

توحّد الواجهة عرض الحالات التالية: التحميل مع رسالة قصيرة لا تحجز مساحة مبالغًا فيها؛ الفراغ مع سبب وخطوة تالية؛ النجاح بالبيانات؛ النجاح الجزئي مع بيان ما لم يحمل؛ الخطأ مع إعادة محاولة؛ التعطيل مع سبب؛ عدم تسجيل الدخول مع دعوة واضحة؛ المنع مع تفسير دون كشف معلومات أمنية؛ والفشل غير المتصل مع إجراء استرداد.

`AssalStateView` الحالي يغطي loading/data/empty/error، وسيُوسّع أو يُغلّف دون كسر العقد لتغطية partial/disabled/unauthorized/forbidden/offline بصورة صريحة.

## الأفعال والتغذية الراجعة

كل زر ينفذ mutation حقيقية خلف repository أو يكون معطلًا بسبب واضح. بعد النجاح تعرض الواجهة نتيجة قابلة للفهم وتحدّث المصدر/الحالة. عند الفشل لا يُعرض نجاح وهمي، ولا تُمسح مدخلات المستخدم قبل نجاح العقد. الأفعال الحساسة مثل الحذف والاعتماد والرفض والإرسال النهائي تتطلب تأكيدًا مناسبًا.

## RTL وإمكانية الوصول

العربية وRTL هما الافتراض. تستخدم المحاذاة والهوامش الاتجاهية، ولا تُستخدم أرقام المعرفات أو البريد إلا مع `TextDirection.ltr` عند الحاجة. كل زر وأيقونة تملك label أو tooltip عربيًا، وكل صورة تملك وصفًا دلاليًا أو `ExcludeSemantics` إذا كانت زخرفية. الحد الأدنى لحجم اللمس 44x44، ويجب أن يعمل تكبير النص دون قص أو overflow.

## Responsive

| العرض | القاعدة |
|---|---|
| أقل من 600px | عمود واحد، أفعال أساسية بعرض واضح، Sheets بدل لوحات جانبية |
| 600–899px | تخطيط متوسط، شبكات مرنة، الحفاظ على ترتيب القراءة |
| 900px فأعلى | NavigationRail/Sidebar، أعمدة محدودة العرض، بطاقات أكثر كثافة |
| Admin mobile | Drawer وقوائم قابلة للتمرير، الجداول تتحول إلى بطاقات أو scroll موثق |

## الحركة والأداء

الحركة قصيرة وهادئة، ولا تغيّر تخطيط القراءة دون سبب. لا تُحمّل صورة أو بيانات قسم مخفي، ولا تُنشئ Future جديدًا مع كل rebuild دون cache أو lifecycle واضح. يجب أن تبقى القوائم قابلة للتمرير وأن تستخدم placeholders خفيفة بدل البطاقات العملاقة.

## التحقق من النظام

قبل اعتماد أي مكوّن جديد يجب اجتياز فحص tokens، RTL، states، semantics، responsive، data source، permission، وregression. أي امتداد بصري أو دلالي يضاف إلى `UI_GAP_REGISTER.md` و`UI_RECONSTRUCTION_TASK_LEDGER.md` قبل تنفيذه.

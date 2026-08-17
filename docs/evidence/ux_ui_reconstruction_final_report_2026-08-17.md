# تقرير إعادة بناء UX/UI المبنية على الأدلة — عسلكم

**التاريخ:** 2026-08-17

## الخلاصة التنفيذية

تم جمع الملاحظات النصية والصور المرفقة وتحويلها إلى تغييرات في الجذر المشترك لتطبيق عسلكم، لا إلى تعديل خاص بملف APK معين. لذلك ستظهر التحسينات نفسها عند بناء Demo وDebug وRelease وAAB وجميع ABIات التطبيق؛ الاختلاف الوحيد المقصود بين Demo وProduction هو مصدر البيانات والمصادقة.

أهم تشخيص مستقل كان أن نسخة ARM64 بحجم يقارب 19.7 MiB التي كانت مثبتة على Mimo هي Release APK صحيح من حيث ABI، لكنها بُنيت في الوضع الافتراضي `Demo`؛ ولذلك لا ترسل OTP حقيقيًا. `DemoRepository` يحفظ البريد في الذاكرة ويقبل الرمز التجريبي `123456` فقط. تم بناء مرشح Production منفصل من نفس المصدر مع dart-defines الخاصة بـSupabase، ونجح اختبار REST المباشر للمشروع، لكن جداول `customer_stores` و`customer_products` و`customer_banners` تعيد قوائم فارغة حاليًا، كما لم يُرسل OTP إلى بريد حقيقي أثناء التحقيق لعدم وجود صندوق اختبار مصرح به.

## ما تم تطبيقه في المصدر المشترك

| المحور | التنفيذ |
|---|---|
| الشعار | `AssalBrandMark` يستخدم الأصل المركزي `AssalAssets.logoInternal`، والاسم النصي اختياري ومخفي افتراضيًا، مع إطار فاتح بزوايا 8 عند الحاجة فوق الخلفيات الداكنة |
| Login/Create Account | شعار مركزي كبير، «مرحبًا بك من جديد» للدخول، «ابدأ تجربتك مع العسل» للتسجيل، وإزالة ازدواجية العناوين دون تغيير عقد Email + OTP |
| AppBar | سهم رجوع فعلي عبر `maybePop` في الشاشات الفرعية، وشعار مصغر مؤطر عند الحاجة |
| التنقل | خمسة أقسام: اكتشف، المتاجر، التصنيفات، المراسلات، حسابي؛ والمتاجر يفتح `StoresScreen` الحقيقي عبر Repository |
| Home | ticker زجاجي صغير متحرك أسفل تعريف Home والبحث، يعتمد على `Repository.listBanners()` ويختفي عند عدم وجود بانرات بدل اختلاق أخبار |
| Empty/Error | استبدال البطاقات الكبيرة بحالة مدمجة بعرض أقصى 420px، مع زر إعادة المحاولة كأيقونة وإخفاء رموز الخطأ التقنية عن المستخدم |
| Filters | إضافة القسم والتصنيف الفرعي من `listCategories()` و`listTaxonomy()` مع المحافظة/المديرية وباقي الفلاتر والسلايدر، دون Taxonomy موازية داخل Widgets |
| الحوكمة | الحفاظ على UI → Repository → Demo/Production Data Source وعدم إدخال Supabase داخل Features |

## قياسات البناء بعد التعديل

| المخرج | الوضع | الحجم |
|---|---|---:|
| Debug APK | Demo | 184,317,600 bytes / 175.78 MiB |
| Release ARM64 | Demo | 20,673,094 bytes / 19.72 MiB |
| Release x86_64 | Demo | 22,173,205 bytes / 21.14 MiB |
| AAB | Demo | 56,227,627 bytes / 53.60 MiB |
| Release ARM64 | Production | 21,262,918 bytes / 20.28 MiB |
| AAB | Production | 57,860,297 bytes / 55.18 MiB |

Debug ليس نسخة نشر؛ كبره ناتج عن أدوات التصحيح وFlutter debug runtime. ARM64 وx86_64 Release يحتوي كل منهما مكتبات native لمعمارية واحدة. أما AAB فيحمل حزم توزيع متعددة ويُفترض أن يختار Google Play ما يلزم للجهاز.

## نتائج الاختبار

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 11 tests passed |
| `git diff --check` | PASS |
| Architecture QA | PASS — لا استدعاءات Supabase/Gateway مباشرة داخل Features |
| Honey Master QA | PASS — v5.0.0، 5 فئات، 30 منتجًا، duplicate IDs = 0 |
| Demo JSON QA | PASS — النطاقان الصغير والغني معلنان، ولا حذف تلقائي للمحتوى |
| Supabase REST | PASS — `regions`, `honey_taxonomy`, `categories` أعادت HTTP 200 وبيانات |
| Production catalog | OPEN — `customer_stores`, `customer_products`, `customer_banners` أعادت HTTP 200 وقوائم فارغة |
| OTP الحقيقي | BLOCKED — يحتاج بريد اختبار يملكه المستخدم أو اختبارًا مباشرًا مصرحًا به |
| Visual screenshot review | BLOCKED جزئيًا — Mimo شغّل APK، لكن Flutter canvas لا يظهر في UIAutomator وملف اللقطة محفوظ على جهاز المستخدم |

## الملفات الدالة

- `ux_evidence_inventory_2026-08-17.md`: مصفوفة الصور والمشكلات ومواضع الإصلاح.
- `mimo_arm64_artifact_identity_2026-08-17.md`: هوية APK الذي كان مثبتًا على Mimo وهاشه.
- `mimo_runtime_supabase_otp_diagnosis_2026-08-17.md`: إثبات Demo Mode وسبب عدم وصول OTP وتشخيص Supabase.
- `ux_shared_login_gate_2026-08-17.md`: بوابة Login وBrand.
- `ux_navigation_appbar_gate_2026-08-17.md`: بوابة التنقل وAppBar.
- `ux_home_ticker_gate_2026-08-17.md`: بوابة Home/Ticker.
- `ux_compact_states_gate_2026-08-17.md`: بوابة Empty/Error.
- `ux_filter_hierarchy_gate_2026-08-17.md`: بوابة الفلاتر الهرمية.
- `shared_build_matrix_gate_2026-08-17.md`: مصفوفة Debug/Demo/Production/AAB.
- `ux_qa_matrix_2026-08-17.md`: نتائج Architecture/Data/Visual QA.

## القرار النهائي لهذه الحزمة

**PASS — التغييرات المصدرية المشتركة والاختبارات والبناء والتحقق المعماري والبياني.**

**BLOCKED — الإغلاق البصري النهائي على Mimo وإثبات وصول OTP إلى بريد حقيقي، وهما خارج ما يمكن إثباته دون قراءة لقطة Mimo بصريًا وتوفير بريد اختبار مصرح به.**

لا ينبغي اعتبار مرشح Production جاهزًا لاستقبال مستخدمين قبل إدخال بيانات المتاجر والمنتجات في الجداول المنشورة، ثم اختبار OTP الحقيقي بصندوق اختبار، ثم إعادة Visual QA على الجهاز.

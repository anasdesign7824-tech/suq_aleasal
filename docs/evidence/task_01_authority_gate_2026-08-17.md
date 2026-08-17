# Task 01 — سلطة الملفات والمراجع

## Task Scope

تثبيت مصادر السلطة قبل أي تعديل، وقراءة Prompt التنفيذ، Amendment، ملف حوكمة المهام، العقود، Repositories، migrations، ملفات UI، Design System، Honey Master الكامل، ومرجع المحافظات والمديريات الكامل.

## Existing State

كان المستودع يحتوي على خطة تنفيذ أقدم ذات 50/60 مهمة ووثائق Discovery سابقة، مع وجود تطبيق Flutter قائم ونسخة Demo وProduction boundary. كما كانت هناك أصول بناء محلية غير متتبعة من جلسة تحسين APK السابقة.

## Changes

لم تُعدّل ملفات التطبيق أو العقود أو migrations في هذه المهمة. أُضيف فقط سجل التدقيق السابق `ui_amendment_phase2_audit_2026-08-17.md` وهذا الدليل الخاص بالبوابة.

تم تثبيت أن سلسلة هذه الحزمة هي 35 مهمة مستقلة، وفق أرقام المصدر §1–§6 و§8–§26 و§28–§37، لأن الملف المقدم يترك الرقمين 7 و27 بلا عنوان ويطلب صراحةً عدم إعادة تقسيم أو دمج المهام.

## Files Changed

| الملف | نوع التغيير |
|---|---|
| `docs/evidence/ui_amendment_phase2_audit_2026-08-17.md` | سجل تدقيق ما قبل التنفيذ |
| `docs/evidence/task_01_authority_gate_2026-08-17.md` | دليل بوابة Task 01 |

لم تُدرج APK/AAB أو الملفات المؤقتة أو الأسرار في Git. حالة Git تحتوي على ملفات محلية غير متتبعة من جلسة سابقة، وتحتاج إلى تنظيف artifact hygiene منفصل قبل أي commit كودي لاحق.

## Tests

تم تشغيل:

- `git diff --check` ونجح.
- `python3 tools/analyze_honey_master.py` ونجح دون duplicate IDs أو missing product IDs.
- `python3 -m json.tool` على Honey Master وLocations وDemo Catalog ونجح.
- `python3 tools/check_demo_catalog.py` ونجح.
- SHA-256 للمراجع سُجل كما يلي:

| المصدر | SHA-256 |
|---|---|
| `references/data/yemeni_honey_master_database_final.json` | `ba2461f4a746ea71a4b83b6976c1400c4cb1a93ee5a9253423ec8595cc6af1c5` |
| `references/data/yemen_governorates_districts.json` | `2c75e36367ca4e58ca21baf679534d4d5cf90c3c27b54b554855dc87b43a5834` |
| `apps/mobile_flutter/assets/demo_catalog.json` | `7ee9f7c96e0037a3005dfdcf8cb48de1644a3cc2d73cbe2b1fc875c8c4d86dfd` |
| `docs/design-system-contract.md` | `786441138d2c1f38872f198f22da39338933e4b929a65e35222e88340ef50c6e` |

نتيجة Honey Master: الإصدار 5.0.0، خمس فئات رئيسية، أربع فئات فرعية مباشرة، 30 منتجًا معرفًا، 39 معرفًا فريدًا إجمالًا، بلا IDs مكررة أو مفقودة، مع أربع درجات جودة وخمس شارات وست وحدات تغليف.

نتيجة Locations: المصدر المثبت يعلن 22 محافظة و335 مديرية، مع أكواد مستقرة ومصدر/commit موثقين.

## Runtime Verification

لا يوجد تغيير Runtime في Task 01. تم فحص مسارات التنفيذ الحالية قراءةً، وتأكد وجود Demo Repository وProduction Repository خلف `AssalRepository`، وعدم الحاجة إلى تشغيل التطبيق لإثبات مهمة سلطة الملفات.

## Visual Verification

تم فحص تعريفات الأصول ومواضع `AssalBrandMark` في Home/Login، وتبين أن الشعار الداخلي runtime موجود، بينما توجد مراجع قديمة مثل `assets/brand/logo-internal.svg` داخل Demo Catalog تحتاج إلى معالجة في مهام الهوية/الأصول اللاحقة. لم يتم حذف أو استبدال أي أصل في Task 01.

## Architecture Verification

تم تثبيت قاعدة:

```text
UI → Controller/ViewModel → Use Case → Repository → Demo/Production Data Source
```

كما تم تثبيت أن المستخدم نفسه يملك Customer capability وMerchant capability، وأن Supabase لا يُستدعى مباشرة من Widgets، وأن Demo لا يدعي Production persistence.

## Data / Contract Verification

تمت قراءة `assal_domain.dart` و`assal_repository.dart` و`demo_repository.dart` و`production_repository.dart` وmigrations الحالية. لم يُنشأ Contract بديل، ولم تُحذف حقول من Honey Master أو Location source.

## Regression Verification

فحوص JSON وDemo guard نجحت، ولم تُعدّل ملفات التشغيل؛ لذلك لا يوجد مسار Customer سابق كُسر بهذه المهمة.

## Remaining Issues

يوجد Artifact hygiene محلي: APK/AAB وصور وملفات مؤقتة غير متتبعة في Git من الجلسة السابقة. لا يؤثر ذلك على مصدر التطبيق، لكنه يجب تنظيفه أو إبقاؤه خارج commits اللاحقة. كما أن توحيد الأيقونات وإصلاح مراجع Demo Catalog القديمة يبدأ في مهام الهوية المرئية اللاحقة ولا يُنسب إلى Task 01.

## Final Gate

**PASS** — تم تثبيت السلطة وقراءة المصادر وفحص سلامتها، ولم يبدأ تعديل كودي قبل إغلاق هذه البوابة.

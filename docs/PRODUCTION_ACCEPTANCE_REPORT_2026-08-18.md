# تقرير قبول الإنتاج — عسلكم

**التاريخ:** 18 أغسطس 2026

**المستودع:** `anasdesign7824-tech/suq_aleasal`

**Commit المنشور:** `172f42c24a5646bcc8c62dfed8b3fbfbf31c43fb`

## النتيجة التنفيذية

تم إكمال تكامل مسارات الكتابة الإنتاجية في تطبيق العميل Flutter وربط لوحة الإدارة المحلية الخاصة بمصدر Supabase Production نفسه. لا تُستخدم بيانات Demo داخل مسارات الإنتاج، وتبقى الواجهة الحالية هي الواجهة المرجعية الوحيدة. أضيفت دورة طلب التاجر من التطبيق إلى الإدارة ثم قرار المراجعة مع تسجيل التدقيق، كما تم تحديث عقد TypeScript من قاعدة Supabase الحية بعد آخر migrations.

> **القاعدة المعمارية النهائية:** تطبيق العميل ولوحة الإدارة المحلية يقرآن ويكتبان في Supabase Production نفسه، بينما تبقى أسرار الخدمة خلف Local Admin Backend ولا تصل إلى React أو APK.

## بوابات التحقق

| المجال | الاختبار | النتيجة |
|---|---|---|
| Flutter | `flutter analyze --no-pub` من `apps/mobile_flutter` | **PASS — No issues found** |
| Flutter | `flutter test --no-pub` | **PASS — 13 tests passed** |
| Flutter | بوابة `tool/build-production.ps1` مع `--dart-define-from-file=assalkom.production.defines.json` | **PASS — APK Production متصل، 21.87 MB** |
| Admin Web | `pnpm check` | **PASS** |
| Admin Web | `pnpm test` | **PASS — 4/4** |
| Admin Web | `pnpm build` | **PASS** |
| Local Admin | `GET /api/health` على `127.0.0.1:3210` | **200** |
| Local Admin Auth Gate | `GET /api/admin/merchant-applications` بدون جلسة | **401 — محمي** |
| Supabase Production | أدوار `admin` و`moderator` | **merchant.review مفعلة** |
| Supabase Security Advisor | بعد Migrations 0013–0015 | **تحذير واحد مقصود لمسار حذف الحساب + تحذير إعداد Auth** |
| GitHub | `HEAD == origin/main` | **PASS** |
| APK integrity | `unzip -t` للنسختين | **PASS** |

## ما تم ربطه إنتاجيًا

أصبح `ProductionRepository` يدعم إنشاء طلبات التواصل وبنود الطلب، وتسجيل قراءة المنتج، والإعجاب بالمنتج، والمفضلة، والمتابعة، وإنشاء المراجعات والتعليقات، وتحديد قراءة الإشعار، وإنشاء المحادثات والرسائل، وإرسال طلبات التاجر ومسوداته. تستعمل مسارات العميل جلسة المستخدم الحقيقية عبر `requireUserSession()` بدل معرفات `demo-customer` أو `demo-conversation-*`.

أضيفت إلى لوحة الإدارة المحلية إدارة حقيقية لطلبات التجار: قراءة قائمة الطلبات من `merchant_applications`، وعرض حالات الفراغ والخطأ، واعتماد الطلب أو رفضه أو طلب معلومات إضافية، وحفظ `reviewed_at` و`reviewed_by` و`review_note`، ثم تسجيل العملية في `audit_logs`. جميع المسارات تمر عبر `requireAdmin` وصلاحية `merchant.review`.

## Migrations Production

تم تطبيق migrations التالية على مشروع Supabase `gvalqfgxrkibuydoiuiz`:

| Migration | الغرض |
|---|---|
| `0007` | دورة حياة Admin Identity وBootstrap وRBAC |
| `0008` | حقول التواصل والرد على الطلبات |
| `0009` | المحادثات والمشاركون والرسائل |
| `0010` | أحداث قراءة المنتجات |
| `0011` | إعجابات المنتجات |
| `0012` | طلبات التجار ومسوداتها |
| `0013` | صلاحية `merchant.review` لأدوار الإدارة المناسبة |
| `0014` | تقليل سطح RPC العام لدوال فحص الإدارة وتحسين search path |
| `0015` | تثبيت `search_path` لدالة تحديث Admin timestamps |

## نتائج Security Advisor

بعد التحصين اختفت تحذيرات دوال `is_admin` و`is_super_admin` و`has_admin_permission` من سطح RPC العام، واختفى تحذير `search_path` المتغير. بقيت ثلاثة ملاحظات:

أولًا، `admin_bootstrap_state` مفعّل عليه RLS دون سياسة، وهذا مقصود كمنع وصول افتراضي؛ الجدول داخلي لمسار Bootstrap الخادمي ولا ينبغي أن يقرأه مستخدم التطبيق.

ثانيًا، بقي تحذير `delete_my_account()` لأنه مسار حذف حساب المستخدم المقصود، وهو `SECURITY DEFINER` عمدًا حتى يستطيع حذف سجل Auth مع إبقائه مقيدًا بـ`authenticated` فقط ومحصنًا بـ`search_path = pg_catalog, public, auth`. إزالة صلاحية التنفيذ ستكسر امتثال حذف الحساب من التطبيق، لذلك لم تتم إزالتها.

ثالثًا، أبلغ Supabase عن تعطيل حماية كلمات المرور المسربة في Auth. هذا إعداد على مستوى خدمة Auth وليس migration SQL؛ ينبغي تفعيله من إعدادات Auth في Supabase قبل الإطلاق العام النهائي.

## الملفات المرفقة

`artifacts/assalkom-demo-arm64-release.apk` هي نسخة Demo للمراجعة البصرية وتحتوي على السلوك المحلي التجريبي السابق.

`artifacts/assalkom-production-connected-arm64-release.apk` هي نسخة Production arm64 المصححة، المبنية عبر بوابة البناء الإلزامية مع `ASSALKOM_MODE=production` وعنوان Supabase والمفتاح العام. حجمها **21,872,688 بايت**، وبصمتها SHA-256 هي `f94b69ef058443c0b33f143547cbf1c0620d01b1a8ff4aaa1414b0a43065001d`. أما ملف `assalkom-production-arm64-release.apk` ذي **20,282,864 بايت** فكان build غير مهيأ؛ فحص `libapp.so` أثبت عدم وجود عنوان Supabase داخله، ولذلك لا يُستخدم ولا يُسلّم كنسخة Production.

لا توجد ملفات APK أو AAB ضمن Git؛ تم استبعادها عبر `.gitignore` وتبقى في مجلد `artifacts` المحلي فقط.

## تشغيل لوحة الإدارة المحلية

من مجلد `apps/admin_web` شغّل:

```bash
pnpm start
```

أو:

```bash
NODE_ENV=production ADMIN_BIND_HOST=127.0.0.1 PORT=3210 pnpm start
```

ثم افتح `http://127.0.0.1:3210`. الوصول مقيد بـlocalhost، وتسجيل الدخول إداري مستقل بالبريد وكلمة المرور عبر Supabase Auth، ولا يمر عبر OTP الخاص بالعميل. بعد Bootstrap الأول يجب تغيير كلمة المرور وحذف ملف بيانات الاعتماد المؤقت من الجهاز المحلي وعدم إدخاله في Git.

## حالة GitHub

تم دفع إصلاح البناء في commit `2452e8f` إلى `origin/main` بنجاح، وأصبح الفرع المحلي مطابقًا للفرع البعيد. الملفات المصدرية والـmigrations والعقود والتقارير محفوظة في المستودع، بينما المخرجات الثنائية الكبيرة غير متتبعة عمدًا.

## حدود القبول المتبقية

تم التحقق من البناء والتحليل والاختبارات، ومن حماية المسار الجديد بدون جلسة. تم التحقق من اتصال REST إلى جدول `regions` بنتيجة HTTP 200، ومن نقطة Supabase Auth `settings` بنتيجة HTTP 200، كما ثبت وجود عنوان Supabase داخل AOT للـAPK المصحح وعدم وجوده داخل APK القديم. أما اختبار إرسال OTP الفعلي فيحتاج إدخال بريد اختبار حقيقي على الجهاز، ولم أرسل رمزًا بالنيابة عنك حتى لا يُستخدم بريد حقيقي دون موافقتك. الكود ومسارات Auth جاهزة لهذا الاختبار المنضبط باستخدام APK المصحح فقط.

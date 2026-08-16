# Master Authority Baseline — عسلكم / Souq Al Assal

**تاريخ baseline:** 2026-08-16 حسب وقت المشروع.

**الغرض:** تثبيت مصادر السلطة وحالة المستودع قبل تنفيذ الخطة الموحدة، حتى لا تُستبدل المتطلبات أو تُخلط النسخ أو يُعلن نجاح غير قابل للتحقق.

## مصادر السلطة

| الأولوية | المصدر | الدور | SHA-256 أو المرجع |
|---:|---|---|---|
| 1 | Prompt التنفيذ الأعلى: `وثيقةالبرمبتالتنفيذيلمشروععسلكمالمعروفبسوقالعسل.txt` | Product vision، architecture، customer/merchant/admin، security، testing، acceptance | `8eebb6db13cd07d2ff05597a3ac006ee815fd361da51b7a2869489f1788fa785` |
| 2 | Amendment: `pasted_content_3.txt` | Store Creation، Auth ordering، Session، Profile، Merchant، Analytics، Performance، RLS، Admin compatibility | `34a9ce5b318755544bbf4cf2244ee76c50027e74d41404271fc014942b35c9b0` |
| 3 | `docs/evidence/master_execution_plan.md` | خطة التنفيذ المعتمدة ذات 50 مهمة وبوابات الانتقال | `386b019cfb88951a9cc01a2321aa5469801f83a02e6ec7de694ad9dde0c638fd` |
| 4 | `docs/evidence/battle_test_validation_plan.md` | الاختبارات الميدانية، الأمن، RLS، Storage، الضغط، Web/APK/Mimo، أدلة الإطلاق | `a5332b13dc638355368bbd506caef1441b3a19374f74427dd0d069047487db05` |
| 5 | `references/data/yemeni_honey_master_database_final.json` | المرجع المركزي لتصنيف العسل والمنتجات والخصائص | `ba2461f4a746ea71a4b83b6976c1400c4cb1a93ee5a9253423ec8595cc6af1c5` |
| 6 | `docs/evidence/merchant_amendment_discovery.md` | baseline Discovery السابق للفجوات الحالية ومسارات الملفات | `1901306ff3631a5b85a863b84f0d6d4b1e97fb3305fd2b0d87120bb7ff8e3af5` |

## قرارات السلطة المثبتة

| الموضوع | القرار الملزم |
|---|---|
| Product semantics | منصة اجتماعية/تجارية متخصصة بالعسل اليمني؛ ليست Checkout تقليديًا |
| User identity | حساب واحد للعميل والتاجر؛ التاجر Capability على نفس Auth UID |
| UI/Data boundary | `UI → Controller/ViewModel → Use Case → Repository → Data Source` |
| Demo | يعمل بدون Supabase/Internet ولا يدعي حفظ Production |
| Production | Supabase Auth/Postgres/Storage خلف contracts وrepositories |
| Auth | Email ثم Google ثم Facebook؛ Google Web Client في Supabase، Android client في Google Cloud |
| Firebase | خارج النطاق وغير مطلوب |
| Admin | Admin Web محلي متصل ببيانات حقيقية، مع Supabase Auth وrole/RLS، وليس اتصالًا عامًا بلا حماية |
| Storage | public media بسياسات محددة، private verification files غير عامة |
| Notifications | In-App عبر DB في هذه الدفعة؛ Push خارجي غير شرط للإطلاق الحالي |
| Web/Landing | Flutter Web artifact يُحفظ ويُختبر؛ public marketing Landing/Cloudflare لاحقًا |
| Release gate | لا GO من build فقط؛ يلزم Battle-Test وevidence وRLS/Storage/Auth/timing |

## حالة المستودع عند baseline

| القياس | النتيجة |
|---|---:|
| Branch | `main` |
| HEAD | `53b189aa04aa79b124cedbe85aadaf7482fbe406` |
| Remote state | `main...origin/main`، نظيف ومتزامن عند القياس |
| Dart files تحت apps/packages | 27 |
| SQL migrations | 6 |
| Flutter/package test files | 5 حسب glob baseline |
| Admin Web files | 86 |
| Landing Web files | 1 |
| Customer Flutter | موجود ويحتوي على Demo catalog، tests، Web/APK build evidence سابقة |
| Database | migrations `0001`–`0006` موجودة؛ أي توسعة جديدة additive وبعد GAP review |

## ما هو موجود ويجب الحفاظ عليه

Customer discovery، Home carousel، categories، honey filters، Product Detail، Store Profile، favorites، Profile، Notifications، Settings، Requests، Messaging، Reviews/Comments، Demo repository، Production repository boundary، Design System، IBM Plex Sans Arabic، RTL، Responsive navigation، واختبارات customer الحالية. لا يُعاد بناء هذه الأجزاء بلا سبب مثبت.

## ما هو معروف أنه ناقص عند baseline

Store Creation Wizard الحقيقي، StoreDraft/resume، media upload pipeline، governorate/district cascading source، delivery/pickup configuration، private documents، multi-stage verification، generic product creation/edit/publish، real Auth providers/session restoration، user history، analytics events/buffering/aggregates، Admin production CRUD، Storage policies المتخصصة، In-App notification write path، وBattle-Test evidence الفعلية.

## قواعد المقارنة بعد كل دفعة

1. يُحفظ commit قبل التعديل وبعده.
2. يُعاد تشغيل `git diff --check` وanalyze/tests المناسبة.
3. لا يُعتبر التغيير نجاحًا إذا كسر Demo أو Customer journeys القائمة.
4. كل فجوة جديدة تُسجل بصيغة `GAP → ROOT CAUSE → IMPACT → REQUIRED CHANGE`.
5. كل إعداد خارجي غير قابل للوصول يُسجل `BLOCKED` ولا يُستبدل بنجاح وهمي.
6. الأسرار، مفاتيح Google/Facebook/Supabase service role، كلمات مرور Admin، وkeystore لا تُحفظ في Git أو client artifacts.

## بوابة Task 1

Task 1 يمر فقط بعد اكتمال هذا الملف، وتثبيت بصمات مصادر السلطة، وتسجيل baseline Git. بعد ذلك يمكن الانتقال إلى Task 2–5 للجرد والتتبع وحدود البيئات. لم تُعدّل ملفات التطبيق أو migrations أثناء إنشاء هذا baseline.

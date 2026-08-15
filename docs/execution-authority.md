# Execution Authority — عسلكم / Souq Al Assal

## مستوى السلطة

هذه الوثيقة تلخص القواعد التنفيذية المعتمدة من وثيقة `pasted_content_2.txt`، وتُقرأ مع الخطة التنفيذية وملفات المرجع. هي مرجع حاكم لقرارات المشروع، ولا يجوز لأي خطة فرعية أو تنفيذ لاحق أن يغيّر معناها.

## الثوابت

المشروع Greenfield من الصفر، ومنصة اجتماعية/تجارية متخصصة بالعسل اليمني وليست متجر Checkout تقليديًا. يلتزم بالعربية أولًا وRTL، وبهوية Design System موحدة، وبـ Flutter/Dart لتطبيق الجوال، وبـ Demo-First Architecture وRepository Abstraction، وبالفصل بين UI وDomain وData Sources، وبالفصل بين Demo Mode وProduction Mode، وبوجود تجربة Customer وMerchant وAdmin، وبنموذج أمان وRLS، وبالقبول المبني على الأدلة وبوابات القبول المرحلية.

## عقد الاسم

الاسم الهندسي الداخلي هو `Souq Al Assal / سوق العسل` ويُستخدم في المستودع والمجلدات والمعرفات التقنية والوثائق الداخلية وإعدادات البنية. الاسم التجاري الظاهر للمستخدم هو **عسلكم** ويُستخدم في التطبيق وSplash وOnboarding والـ Header والتنقل وتسجيل الدخول والإشعارات وصفحات العميل والتاجر وLanding وSEO وOpen Graph وfavicon والنصوص التسويقية. لا يُستخدم `سوق العسل اليمني` كاسم تجاري أساسي بديل عن `عسلكم`.

## Demo وProduction

Supabase هو مصدر الإنتاج الرسمي للبيانات والمصادقة والتخزين، لكنه ليس شرط التشغيل أو الاختبار أثناء Demo Mode. لا يجوز لـ Supabase أو Schema أو RLS أو Backend APIs أن تقود UX أو Domain Model أو User Journey قبل استقرار عقود Demo والواجهات. الاتصال الحقيقي بمصدر Supabase يبدأ فقط في مرحلة Production Data Sources بعد اكتمال Demo Gates.

## العقود النوعية

يستخدم تطبيق Flutter عقود Dart، وتستخدم مشاريع Web عقود TypeScript عند الحاجة، مع تطابق دلالي بين الحقول والحالات والتحويلات. لا يفرض ذكر TypeScript تغيير تقنية Flutter/Dart أو إدخاله إلى تطبيق الجوال.

## اكتمال الميزات

لا يُعتبر Schema أو migration أو RLS أو Backend API أو نجاح build أو ظهور شاشة دليلًا على اكتمال Feature. اكتمال Feature يتطلب:

```text
UI + State + Domain Behavior + Repository Contract + Demo Implementation
+ Demo Data + Loading/Empty/Error States + Tests + Evidence
+ Production Data Source عند الوصول إلى مرحلة التكامل
```

كل زر ظاهر يجب أن ينفذ فعلًا، أو يكون Disabled مع سبب واضح، أو لا يظهر أصلًا. يُمنع استخدام handlers فارغة أو Placeholder يخفي عدم التنفيذ.

## بوابات التنفيذ

تتبع كل Phase التسلسل الإلزامي:

```text
PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK
→ ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE
→ GIT COMMIT → ACCEPTANCE GATE → NEXT PHASE
```

لا يجوز الانتقال عند الفشل، ولا يجوز إعلان اكتمال مبكر أو إخفاء Known Issues.

## التصعيد

الوكيل مستقل في التفاصيل التي لا تمس الثوابت، مثل أسماء الملفات الداخلية واختيار المكتبات وتنظيم الملفات داخل الطبقة وأسلوب الاختبار وتحسين الأداء. أي قرار يغير Product Vision أو Brand Identity أو User Journey أو Demo-First أو Design System أو Security Model أو Architecture Boundaries أو Technology Requirement يُعامل كقرار كبير ويُوثق وفق:

```text
CONFLICT → ROOT CAUSE → IMPACT → OPTIONS → RECOMMENDATION → USER DECISION IF REQUIRED
```

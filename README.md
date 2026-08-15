# Souq Al Assal / سوق العسل

## عسلكم — منصة العسل اليمني

هذا المستودع هو مشروع **Greenfield** لبناء منصة اجتماعية/تجارية متخصصة بالعسل اليمني. الاسم الهندسي الداخلي الثابت هو `Souq Al Assal / سوق العسل`، بينما الاسم التجاري الظاهر للمستخدم في التطبيق والويب هو **عسلكم**.

## مخرجات المشروع

يحتوي المشروع على ثلاثة مخرجات مستقلة ومترابطة بعقود دلالية مشتركة:

| المخرج | المسار | نطاق التشغيل |
|---|---|---|
| تطبيق الجوال | `apps/mobile_flutter` | Flutter/Dart، عربي أولًا وRTL، Demo-First ثم مصدر إنتاج |
| لوحة Admin | `apps/admin_web` | Web محلية التشغيل، عربية RTL، صلاحيات إدارية وسجل تدقيق |
| صفحة الهبوط | `apps/landing_web` | Web عامة، عربية RTL، مهيأة للنشر على Cloudflare |

وتوجد عقود الويب وعقود Flutter في `packages/contracts_ts` و`packages/contracts_dart` عند الحاجة، مع الحفاظ على التطابق الدلالي وعدم فرض TypeScript على تطبيق Flutter.

## القواعد التنفيذية الملزمة

يعمل التطوير وفق **Demo-First Architecture** و**Repository Abstraction**. لا تتصل أي Widget أو Screen مباشرة بـ Supabase. المسار المعتمد هو:

```text
UI → ViewModel / Controller → Use Case → Repository Interface → Demo Repository أو Supabase Repository → Data Source
```

Supabase هو مصدر الإنتاج الرسمي للبيانات والمصادقة والتخزين، لكنه ليس شرطًا لتشغيل أو اختبار Demo Mode. لا يقود Schema أو RLS أو Backend APIs تجربة المستخدم أو Domain Model قبل استقرار عقود Demo.

كل Feature مكتملة يجب أن تجمع بين UI وState وDomain Behavior وRepository Contract وDemo Implementation وDemo Data وحالات Loading/Empty/Error والاختبارات والأدلة، ثم Production Data Source عند مرحلة التكامل. لا توجد واجهات ميتة أو handlers فارغة.

## المراجع والسلطة

المرجع الأعلى للتنفيذ هو `docs/execution-authority.md`، وتفاصيل Phase 1 في `docs/phase-01-plan.md`. سجل الأصول المرجعية في `docs/reference-manifest.md`. لا تُستخدم الصور المرجعية كمصدر معماري، ولا تُستخدم بيانات Honey Master كمصدر تلقائي للأسعار أو المخزون أو الإحصاءات.

## حالة التنفيذ

المرحلة الحالية: **Phase 1 — تأسيس المشروع والحوكمة**.

لا يُسمح بالانتقال إلى المرحلة التالية قبل اجتياز التسلسل:

```text
PLAN → IMPLEMENT → RUN → VERIFY → TEST → VISUAL CHECK → ARCHITECTURE CHECK → FIX → RETEST → EVIDENCE → GIT COMMIT → ACCEPTANCE GATE
```

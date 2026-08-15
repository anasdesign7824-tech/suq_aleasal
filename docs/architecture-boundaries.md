# Architecture Boundaries — Phase 1

## المبدأ

يُبنى المشروع كمنظومة Greenfield مستقلة، ولا يُستورد كود أو قالب سابق. المخرجات الثلاثة تشترك في الدلالة والهوية فقط، ولا تشترك في خلط طبقات التنفيذ.

## حدود المشاريع

| المشروع | التقنية الملزمة | مسؤوليات Phase 1 |
|---|---|---|
| `apps/mobile_flutter` | Flutter/Dart | تثبيت موضع التطبيق وحدود `core/`, `features/`, وطبقات Presentation/Domain/Data دون تنفيذ Features بعد |
| `apps/admin_web` | Web | تثبيت موضع لوحة الإدارة المحلية وحدود الواجهة والطبقات المرتبطة بها دون ربط إنتاجي في Phase 1 |
| `apps/landing_web` | Web | تثبيت موضع الصفحة التسويقية العامة وحدودها دون نشر أو تحميل أصول نهائية في Phase 1 |
| `packages/contracts_dart` | Dart | موضع عقود تطبيق Flutter عند بدء تعريفها، دون فرضها على الويب |
| `packages/contracts_ts` | TypeScript | موضع عقود مشاريع Web عند الحاجة، مع تطابق دلالي مع عقود Dart |

## مسار البيانات

في Demo Mode، يكون مصدر البيانات Demo Repository مستقلًا عن Supabase:

```text
UI → ViewModel / Controller → Use Case → Repository Interface
→ Demo Repository → Demo Data + Demo State
```

في Production Mode، يُستبدل المصدر خلف العقد نفسه:

```text
UI → ViewModel / Controller → Use Case → Repository Interface
→ Supabase Repository → Supabase
```

لا يجوز لـ Widget أو Screen الاتصال مباشرة بـ Supabase. لا يجوز لتصميم Schema أو RLS أو API أن يقود UX أو Domain Model أو User Journey قبل استقرار Demo Contracts.

## حدود Phase 1

لا تنفذ هذه المرحلة قاعدة بيانات أو migrations أو RLS أو تسجيل دخول أو منتجًا أو متجرًا أو محادثة أو لوحة بيانات فعلية. توثق مواضعها وقراراتها فقط، لأن وجود مخطط أو ملف أو مجلد لا يساوي اكتمال Feature.

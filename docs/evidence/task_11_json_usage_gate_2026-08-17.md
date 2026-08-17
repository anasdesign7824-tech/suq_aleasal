# Task 11 — استخدام JSON في جميع أجزاء التطبيق

## Task Scope

ضمان أن بيانات التطبيق التشغيلية في Demo تُقرأ من JSON versioned عبر `DemoCatalogLoader` و`DemoRepository`، وأن Production يمر عبر Repository/DB، مع منع hardcoded domain data داخل Widgets.

## Audit Findings

`DemoRepository` يقرأ الكتالوج مرة واحدة عبر `jsonDecode(await _loader.loadJson())` ثم يمرر المناطق، التصنيفات، الأقسام، المتاجر، المنتجات، البنرات، الإشعارات، الطلبات، التعليقات، الرسائل والمراجعات من مصدر الكتالوج أو من حالة Demo المحلية المعلنة. Production يستخدم `ProductionRepository` وقراءة الجداول الحقيقية عبر gateway.

تم العثور على fallback تجاري داخل Store Profile كان يعرض `['عسل يمني', 'مصدر موثق']` إذا غابت تخصصات المتجر. أُزيل هذا fallback واستُبدل بـEmpty State تعليمي: «لم يضف المتجر تخصصاته بعد»، حتى لا تُنسب بيانات غير موجودة إلى متجر حقيقي.

## Changes

| الملف | التغيير |
|---|---|
| `apps/mobile_flutter/lib/features/customer/customer_catalog.dart` | إزالة fallback تخصصات المتجر المكتوب يدويًا وإظهار Empty State عند غياب المصدر |
| `docs/evidence/task_11_json_usage_gate_2026-08-17.md` | دليل البوابة |

لم تُحذف أي بيانات من JSON، ولم تتغير طريقة تحميل `DemoCatalogLoader` أو نسخة المصدر.

## Tests

| الفحص | النتيجة |
|---|---|
| `python3 tools/check_demo_catalog.py` | PASS — deterministic, source-versioned, demo-only, production-independent |
| مسح مداخل `jsonDecode/_readCatalog/DemoCatalogLoader/Repository` | PASS |
| مسح fallback domain data | PASS بعد إزالة fallback التخصصات |
| `flutter analyze` | PASS — No issues found |
| `flutter test test/navigation_test.dart test/data_layer_test.dart test/customer_journey_test.dart` | PASS — 5 tests passed |
| `git diff --check` | PASS |

## Runtime Verification

تم تشغيل اختبارات الرحلة والتنقل وطبقة البيانات؛ الشاشات تستمر في استخدام Repository نفسه، ولا تصل إلى ملفات JSON مباشرة من Widgets.

## Visual Verification

عند غياب التخصصات يظهر Empty State محلي واضح بدل عرض معلومات تجارية مختلقة. بقية بطاقات المتجر والمنتج تستمر في عرض القيم القادمة من models/Repository.

## Architecture Verification

المسار المعتمد هو:

```text
RootBundleDemoCatalogLoader → DemoRepository → Contracts → Feature Widgets
Production Gateway → ProductionRepository → Contracts → Feature Widgets
```

لا يوجد اتصال Supabase داخل UI، ولا hardcoded product taxonomy داخل `customer_catalog.dart`.

## Data / Contract Verification

Task 10 `listCategories()` وTask 09 Honey Master checks يعملان ضمن نفس عقد البيانات. `demo_catalog.json` يبقى explicitly `demo_only` ومرتبطًا بإصدار المصدر المرجعي.

## Regression Verification

نجحت الفحوص الخمسة، ولم يتغير Auth/OTP أو مسار العميل أو التحميل المؤجل. لم تُحذف أي records من الكتالوج.

## Remaining Issues

بعض النصوص الثابتة داخل الواجهة هي UI copy وتعليمات وليست domain data، وتبقى ثابتة عمدًا. كما أن Demo local mutations مثل reviews/comments/messages تُدار في الذاكرة وفق Demo-first وليست ادعاءً لبيانات Production.

## Final Gate

**PASS** — بيانات التطبيق التشغيلية تمر عبر JSON/Repository، وتمت إزالة fallback تجاري كان يختلق تخصصات عند غيابها، مع نجاح الفحوص والتحليل والاختبارات.
